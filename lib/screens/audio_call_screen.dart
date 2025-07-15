import 'dart:async';
import 'dart:io';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/call_model.dart';
import '../services/agora_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelName;
  final String doctorName;
  final String doctorImageUrl;

  const AudioCallScreen({Key? key, required this.channelName, required this.doctorName, required this.doctorImageUrl}) : super(key: key);

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AgoraService _agoraService;
  bool _isCallEnded = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  String? agoraErrorMessage;
  bool _isAgoraInitialized = false;
  bool _isSpeakerEnabled = false; // Initial state: false (earpiece)
  bool _isMuted = false;
  bool _permissionsGranted = false;
  static const platform = MethodChannel('app.channel.audio');

  final AudioPlayer audioPlayer = AudioPlayer();
  bool _isRinging = true;
  bool _isConnected = false;

  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  Timer? _ringingTimer;
  Duration _ringingDuration = Duration.zero;
  bool _ringingTimeoutReached = false;

  late AnimationController _animationController;
  bool _isInternetAvailable = true;
  StreamSubscription? _connectivitySubscription;
  bool _isInBackground = false;

  // Add a StreamController to manage speakerphone state
  final _speakerphoneController = StreamController<bool>.broadcast();

  final List<File> _selectedImages = []; // Added to store selected images
  double _uploadProgress = 0.0; // Added for upload progress
  bool _isSelectingImages = false; // Added to track image selection state

  String get firebaseChannelName => widget.channelName.replaceAll('.', '');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _agoraService = AgoraService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _checkInternetConnectivity(); // Check the connection at the first render
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

    _setInitialAudioRoute();
    initAgora();

    // Configure EasyLoading in initState
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..backgroundColor = Colors.grey[800]!;
  }
 /* @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _agoraService = AgoraService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _checkInternetConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

    _setInitialAudioRoute();
    initAgora();

    // Configure EasyLoading in initState
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..backgroundColor = Colors.grey[800]!;
  }
*/
  Future<void> _setInitialAudioRoute() async {
    // Initialize speaker state to false (earpiece)
    _speakerphoneController.sink.add(false);
    _isSpeakerEnabled = false; //set initial speaker state to false

    // Set speaker OFF and play ringing through earpiece
    await _setSpeakerphone(false);

    _startRinging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isCallEnded) {
      _endCallAndCleanUp(reason: 'App destroyed');
    }

    _speakerphoneController.close();
    _animationController.dispose();

    super.dispose();
    _stopRinging();
    _stopCallTimer();
    _stopRingingTimer();
    audioPlayer.dispose();
    _connectivitySubscription?.cancel();
    _agoraService.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _isInBackground = true;
        break;
      case AppLifecycleState.hidden:
        throw UnimplementedError();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isInternetAvailable = (result != ConnectivityResult.none);
    });

    if (!_isInternetAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initAgora() async {
    if (!_isInternetAvailable) {
      return;
    }

    agoraErrorMessage = null;

    try {
      if (kIsWeb) {
        final permissionsGranted = await _requestPermissions();
        if (!permissionsGranted) {
          setState(() {
            agoraErrorMessage = "Microphone permissions not granted.";
          });
          return;
        }
      }

      final success = await _agoraService.initializeAgora(widget.channelName);
      if (!success) {
        setState(() {
          agoraErrorMessage = _agoraService.agoraErrorMessage;
        });
        return;
      }

      _setupEventHandlers();
      await _agoraService.joinChannel(widget.channelName);

      setState(() {
        _isAgoraInitialized = true;
      });

      await FirebaseService.updateCallStatus(
        firebaseChannelName,
        CallModel(
            appointmentID: "0",
            callType: "Incoming Audio Call",
            callingPlatform: "Webdoc App",
            isCalling: "true",
            senderEmail: '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk'
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      setState(() {
        agoraErrorMessage = "Error initializing Agora: $e";
      });
    }
  }

  void _setupEventHandlers() {
    _agoraService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            agoraErrorMessage = null;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            agoraErrorMessage = null;
            _isConnected = true;
          });
          _stopRinging();
          _stopRingingTimer();
          _startCallTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left");
          setState(() {
            _remoteUid = null;
            agoraErrorMessage = null;
            _isConnected = false;
          });
          _endCallAndNavigateBack(reason: 'Remote user left.');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Error occurred: $err, $msg");
          setState(() {
            agoraErrorMessage = "Agora error: $err, $msg";
          });
        },
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [Permission.microphone].request();
    bool allGranted = statuses[Permission.microphone] == PermissionStatus.granted;

    setState(() {
      _permissionsGranted = allGranted;
    });
    return allGranted;
  }

  Future<void> _startRinging() async {
    try {
      final source = AssetSource('ringing.mp3');
      await audioPlayer.setSource(source);
      audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(1.0);
      await audioPlayer.resume();

      setState(() {
        _isRinging = true;
      });
      _startRingingTimer();
    } catch (e) {
      print("Error playing ringing sound: $e");
    }
  }

  Future<void> _stopRinging() async {
    try {
      await audioPlayer.stop();
      setState(() {
        _isRinging = false;
      });
    } catch (e) {
      print("Error stopping ringing sound: $e");
    }
  }

  void _startCallTimer() {
    if (_remoteUid != null) {
      _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _callDuration = _callDuration + const Duration(seconds: 1);
        });
      });
    }
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startRingingTimer() {
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _ringingDuration = _ringingDuration + const Duration(seconds: 1);
      });

      if (_ringingDuration.inSeconds > 30) {
        _stopRingingTimer();
        _stopRinging();
        if (mounted) {
          setState(() {
            _ringingTimeoutReached = true;
          });
        }
        Global.call_missed = true;
        _endCallAndNavigateBack(reason: 'Call not answered in time.');
      }
    });
  }

  void _stopRingingTimer() {
    _ringingTimer?.cancel();
    _ringingTimer = null;
    _ringingDuration = Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final formatter = DateFormat('mm:ss');
    return formatter.format(DateTime(2024, 1, 1, 0, duration.inMinutes, duration.inSeconds % 60));
  }

  Future<void> _setSpeakerphone(bool enable) async {
    if (kIsWeb) {
      try {
        await _agoraService.setEnableSpeakerphone(enable);
        _speakerphoneController.sink.add(enable); // Update stream on success
        if (mounted) {
          setState(() {
            _isSpeakerEnabled = enable;
          });
        }
      } catch (e) {
        print("Error setting speakerphone (Agora): $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set speakerphone.')),
        );
      }
      return;
    }

    try {
      if (Platform.isIOS) {
        // Configure audio session *before* setting speakerphone
        try {
          await platform.invokeMethod('configureAudioSession');
        } on PlatformException catch (e) {
          print("Error configuring audio session: ${e.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to configure audio session: ${e.message}')),
          );
          return; // Important: Don't proceed if session config fails
        }
      }

      if (Platform.isAndroid || Platform.isIOS) {
        await platform.invokeMethod('setSpeakerphoneOn', {'enable': enable});
      }

      // Update the UI and the stream.
      if (mounted) {
        setState(() {
          _isSpeakerEnabled = enable;
        });
      }
      _speakerphoneController.sink.add(enable);

    } on PlatformException catch (e) {
      print("Failed to set speakerphone: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set speakerphone: ${e.message}')),
      );
    }
  }

  Future<void> endCall() async {
    await _endCallAndNavigateBack(reason: 'User pressed end call button.');
  }

  Future<void> _endCallAndNavigateBack({String reason = 'Call ended'}) async {
    if (_isCallEnded) return;

    setState(() {
      _isCallEnded = true;
    });

    _endCallAndCleanUp(reason: reason);
  }

  Future<void> _endCallAndCleanUp({String reason = 'Call ended'}) async {
    try {
      await _agoraService.leaveChannel();
      _stopRinging();
      _stopCallTimer();
      _stopRingingTimer();

      await FirebaseService.updateCallStatus(
        firebaseChannelName,
        CallModel(
          appointmentID: "0",
          callType: "",
          callingPlatform: "",
          isCalling: "",
          senderEmail: '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
        ),
      );
      if (_isConnected && !_ringingTimeoutReached) {
        Global.feedbackDialog = true;
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error ending call: $e");
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _agoraService.toggleMute(_isMuted);
  }
  // Image picking and uploading functions (Copied from VideoCallScreen)
  Future<void> pickImagesFromGallery() async {
    Navigator.of(context).pop();

    // Immediately show "Selecting..."
    setState(() {
      _isSelectingImages = true;
    });
    // Show EasyLoading immediately for image selection
    EasyLoading.show(
      status: 'Selecting images...',
      dismissOnTap: false,
      indicator: const CircularProgressIndicator(
        valueColor:
        AlwaysStoppedAnimation<Color>(Colors.white), // Set color to white
      ),
      maskType: EasyLoadingMaskType.black,
    );

    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 70,
      );

      setState(() {
        _isSelectingImages = false; // Selection done
      });

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (pickedFiles.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can only select up to 10 images."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        });
      }
    } catch (e) {
      setState(() {
        _isSelectingImages = false; // Ensure this is false even on error
      });
      print("Error picking images from gallery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking images: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      EasyLoading.dismiss();
      _showConfirmationDialog(context);
    }
  }

  Future<void> pickImageFromCamera() async {
    Navigator.of(context).pop();

    setState(() {
      _isSelectingImages = true;
    });

    // Show EasyLoading immediately for camera selection
    EasyLoading.show(
      status: 'Opening Camera...',
      dismissOnTap: false,
      indicator: const CircularProgressIndicator(
        valueColor:
        AlwaysStoppedAnimation<Color>(Colors.white), // Set color to white
      ),
      maskType: EasyLoadingMaskType.black,
    );

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      setState(() {
        _isSelectingImages = false;
      });

      if (pickedFile != null) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      setState(() {
        _isSelectingImages = false;
      });
      print("Error picking image from camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      EasyLoading.dismiss();
      _showConfirmationDialog(context);
    }
  }

  Future<File> compressImage(File imageFile) async {
    try {
      final filePath = imageFile.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp[e]?g'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath =
          "${splitted}out${filePath.substring(lastIndex)}"; // Modified for unique name

      final originalImage = img.decodeImage(imageFile.readAsBytesSync());
      if (originalImage == null) {
        return imageFile; // Return original if decoding fails
      }

      img.Image compressedImage = img.copyResize(
        originalImage,
        width: 800,
      );

      final compressedFile = File(outPath)
        ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 85));

      if (compressedFile.lengthSync() > 2 * 1024 * 1024) {
        compressedImage = img.copyResize(
          originalImage,
          width: 600,
        );
      }
      final finalCompressedFile = File(outPath)
        ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 70));
      return finalCompressedFile;
    } catch (e) {
      print("Compression error: $e");
      return imageFile; // Return original on error
    }
  }

  Future<void> _compressImagesAndUpload() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No images selected to upload."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show EasyLoading immediately
      EasyLoading.show(
        status: 'Preparing images...',
        dismissOnTap: false,
        indicator: const CircularProgressIndicator(
          valueColor:
          AlwaysStoppedAnimation<Color>(Colors.white), // Set color to white
        ),
        maskType: EasyLoadingMaskType.black,
      );

      List<File> compressedImages = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        EasyLoading.show(
          status: 'Compressing image ${i + 1}/${_selectedImages.length}',
          dismissOnTap: false,
          indicator: CircularProgressIndicator(
            value: (i + 1) / _selectedImages.length,
            valueColor:
            const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          maskType: EasyLoadingMaskType.black,
        );
        final compressedImage = await compressImage(_selectedImages[i]);
        compressedImages.add(compressedImage);

        await Future.delayed(
            const Duration(milliseconds: 100)); // Simulate compression time
      }

      EasyLoading.show(
        status: 'Uploading images...',
        dismissOnTap: false,
        indicator: const CircularProgressIndicator(
          valueColor:
          AlwaysStoppedAnimation<Color>(Colors.white), // Set color to white
        ),
        maskType: EasyLoadingMaskType.black,
      );

      await _uploadImages(compressedImages);
    } finally {
      EasyLoading.dismiss();
    }
  }
  Future<void> _uploadImages(List<File> compressedImages) async {
    if (compressedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No images selected to upload."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set initial state for progress
    setState(() {
      _uploadProgress = 0.0;
    });

    try {
      final String uploadUrl =
          'https://digital.webdoc.com.pk/ci4webdocsite/public/files/upload';
      final String doctorEmail = widget.channelName.replaceAll('.', '');

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      final jar =
      PersistCookieJar(storage: FileStorage(appDocPath + "/.cookies/"));

      List<Cookie> cookies = await jar.loadForRequest(Uri.parse(uploadUrl));
      String? ciSessionCookie;

      for (Cookie cookie in cookies) {
        if (cookie.name == 'ci_session') {
          ciSessionCookie = cookie.value;
          break;
        }
      }

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['doctor_email'] = doctorEmail;

      if (ciSessionCookie != null) {
        request.headers['Cookie'] = 'ci_session=$ciSessionCookie';
      }

      for (int i = 0; i < compressedImages.length; i++) {
        final imageName = compressedImages[i].path.split('/').last;

        request.files.add(await http.MultipartFile.fromPath(
          'files[$i]',
          compressedImages[i].path,
          filename: imageName, // Provide the filename
        ));

        final progress = (i + 1) / compressedImages.length;
        setState(() {
          _uploadProgress = progress;
        });

        // Update EasyLoading status and progress
        EasyLoading.show(
          status: 'Uploading image ${i + 1}/${compressedImages.length}',
          dismissOnTap: false,
          indicator: CircularProgressIndicator(
            value: progress,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          maskType: EasyLoadingMaskType.black,
        );

        await Future.delayed(const Duration(milliseconds: 100)); // Simulate upload time
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Images uploaded successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Images uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedImages.clear();
        });
      } else {
        print(
            'Failed to upload images. Status code: ${response.statusCode},  reason: ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload images."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading images: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      EasyLoading.dismiss();
      setState(() {
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[800],
              title: const Text("Confirm Upload",
                  style: TextStyle(color: Colors.white)),
              content: SizedBox( // use SizedBox to constrain the height
                width: MediaQuery.of(context).size.width * 0.8, // Limit width if needed
                height: MediaQuery.of(context).size.height * 0.3, // Adjust height as needed
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImages.isNotEmpty)
                      Expanded( // Use Expanded to allow the ListView to take available space within the Column
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      const Text("No images selected.",
                          style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child:
                  const Text("Send", style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _compressImagesAndUpload();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showImagePickerDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[800],
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading:
                  const Icon(Icons.photo_library, color: Colors.white),
                  title: _isSelectingImages
                      ? const Text('Selecting...',
                      style: TextStyle(color: Colors.white))
                      : const Text('Photo Library',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    if (!_isSelectingImages) {
                      pickImagesFromGallery();
                    }
                  }),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: _isSelectingImages
                    ? const Text('Selecting...',
                    style: TextStyle(color: Colors.white))
                    : const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  if (!_isSelectingImages) {
                    pickImageFromCamera();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryTextColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Call',
                style: AppStyles.titleMedium(context).copyWith(color: AppColors.primaryTextColor),
              ),
              if (_callDuration != Duration.zero)
                Text(
                  'Call duration: ${_formatDuration(_callDuration)}',
                  style: AppStyles.bodySmall(context).copyWith(color: AppColors.secondaryTextColor),
                ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: _isInternetAvailable
                ? null
                : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColorLight, AppColors.primaryColor], // Using primaryColor from AppColors
            ),
          ),
          child: _isInternetAvailable
              ? Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.doctorImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.primaryColor.withOpacity(0.2), AppColors.primaryColor],
                      stops: const [0.0, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 240),
                    Text(
                      widget.doctorName,
                      style: AppStyles.titleLarge(context).copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    if (!_isConnected)
                      _isRinging
                          ? FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                        child: Text(
                          'Ringing...',
                          style: AppStyles.titleMedium(context).copyWith(color: Colors.white),
                        ),
                      )
                          : Container()
                    else
                      Text(
                        'Connected',
                        style: AppStyles.bodyLarge(context).copyWith(color: Colors.white),
                      ),

                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMuted ? Colors.black.withOpacity(0.3) : Colors.transparent,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                      FloatingActionButton(
                        backgroundColor: const Color(0xFFE63946),
                        onPressed: _isCallEnded ? null : endCall,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.white, size: 30),
                        onPressed: () {
                          _showImagePickerDialog(context);
                        },
                      ),

                    ],
                  ),
                ),
              ),
              if (agoraErrorMessage != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red,
                    child: Text(
                      agoraErrorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          )
              : Center(
            child: Text(
              'No internet connection. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppStyles.bodyLarge(context).copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}


/*import 'dart:async';
import 'package:Webdoc/utils/shared_preferences.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/call_model.dart';
import '../services/agora_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelName;
  final String doctorName;
  final String doctorImageUrl;

  const AudioCallScreen({Key? key, required this.channelName, required this.doctorName, required this.doctorImageUrl}) : super(key: key);

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AgoraService _agoraService;
  bool _isCallEnded = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  String? agoraErrorMessage;
  bool _isAgoraInitialized = false;
  bool _isSpeakerEnabled = false;
  bool _isMuted = false;
  bool _permissionsGranted = false;
  static const platform = MethodChannel('app.channel.audio');

  final AudioPlayer audioPlayer = AudioPlayer();
  bool _isRinging = true;
  bool _isConnected = false;

  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  Timer? _ringingTimer;
  Duration _ringingDuration = Duration.zero;

  late AnimationController _animationController;
  bool _isInternetAvailable = true;
  StreamSubscription? _connectivitySubscription;
  bool _isInBackground = false;

  String get firebaseChannelName => widget.channelName.replaceAll('.', '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _agoraService = AgoraService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _checkInternetConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    initAgora();
    _startRinging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isCallEnded) {
      _endCallAndCleanUp(reason: 'App destroyed');
    }
    super.dispose();
    _stopRinging();
    _stopCallTimer();
    _stopRingingTimer();
    _animationController.dispose();
    audioPlayer.dispose();
    _connectivitySubscription?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isInBackground = true;
        break;
      case AppLifecycleState.hidden:
        throw UnimplementedError();
    }
  }

  Future<void> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isInternetAvailable = (result != ConnectivityResult.none);
    });

    if (!_isInternetAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initAgora() async {
    if (!_isInternetAvailable) {
      return;
    }

    agoraErrorMessage = null;

    try {
      if (kIsWeb) {
        final permissionsGranted = await _requestPermissions();
        if (!permissionsGranted) {
          setState(() {
            agoraErrorMessage = "Microphone permissions not granted.";
          });
          return;
        }
      }

      final success = await _agoraService.initializeAgora(widget.channelName);
      if (!success) {
        setState(() {
          agoraErrorMessage = _agoraService.agoraErrorMessage;
        });
        return;
      }

      _setupEventHandlers();
      await _agoraService.joinChannel(widget.channelName);
      _setSpeakerphone(false);

      setState(() {
        _isAgoraInitialized = true;
      });

      await FirebaseService.updateCallStatus(
        firebaseChannelName,
        CallModel(
            appointmentID: "0",
            callType: "Incoming Audio Call",
            callingPlatform: "Webdoc App",
            isCalling: "true",
            senderEmail: '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk'
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      setState(() {
        agoraErrorMessage = "Error initializing Agora: $e";
      });
    }
  }

  void _setupEventHandlers() {
    _agoraService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
            agoraErrorMessage = null;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            agoraErrorMessage = null;
            _isConnected = true;

          });
          _stopRinging();
          _stopRingingTimer();
          _startCallTimer();
          Global.feedbackDialog = true;
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left");
          setState(() {
            _remoteUid = null;
            agoraErrorMessage = null;
            _isConnected = false;
          });
          _endCallAndNavigateBack(reason: 'Remote user left.');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Error occurred: $err, $msg");
          setState(() {
            agoraErrorMessage = "Agora error: $err, $msg";
          });
        },
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [Permission.microphone].request();
    bool allGranted = statuses[Permission.microphone] == PermissionStatus.granted;

    setState(() {
      _permissionsGranted = allGranted;
    });
    return allGranted;
  }

  Future<void> _startRinging() async {
    try {
      final source = AssetSource('ringing.mp3');
      await audioPlayer.setSource(source);
      audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(1.0);
      await audioPlayer.resume();

      setState(() {
        _isRinging = true;
      });
      _startRingingTimer();
    } catch (e) {
      print("Error playing ringing sound: $e");
    }
  }

  Future<void> _stopRinging() async {
    try {
      await audioPlayer.stop();
      setState(() {
        _isRinging = false;
      });
    } catch (e) {
      print("Error stopping ringing sound: $e");
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = _callDuration + const Duration(seconds: 1);
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startRingingTimer() {
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _ringingDuration = _ringingDuration + const Duration(seconds: 1);
      });

      if (_ringingDuration.inSeconds > 30) {
        _stopRingingTimer();
        _stopRinging();
        Global.call_missed = true;
        _endCallAndNavigateBack(reason: 'Call not answered in time.');
      }
    });
  }

  void _stopRingingTimer() {
    _ringingTimer?.cancel();
    _ringingTimer = null;
    _ringingDuration = Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final formatter = DateFormat('mm:ss');
    return formatter.format(DateTime(2024, 1, 1, 0, duration.inMinutes, duration.inSeconds % 60));
  }

  Future<void> _setSpeakerphone(bool enable) async {
    try {
      await platform.invokeMethod('setSpeakerphoneOn', {'enable': enable});
      setState(() {
        _isSpeakerEnabled = enable;
      });
      print("Speakerphone set to: $enable");
    } on PlatformException catch (e) {
      print("Failed to set speakerphone: ${e.message}");
    }
  }

  Future<void> endCall() async {
    await _endCallAndNavigateBack(reason: 'User pressed end call button.');
  }

  Future<void> _endCallAndNavigateBack({String reason = 'Call ended'}) async {
    if (_isCallEnded) return;

    setState(() {
      _isCallEnded = true;
    });

    _endCallAndCleanUp(reason: reason);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _endCallAndCleanUp({String reason = 'Call ended'}) async {
    try {
      await _agoraService.leaveChannel();
      _stopRinging();
      _stopCallTimer();
      _stopRingingTimer();

      await FirebaseService.updateCallStatus(
        firebaseChannelName,
        CallModel(
          appointmentID: "0",
          callType: "",
          callingPlatform: "",
          isCalling: "",
          senderEmail: '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
        ),
      );



    } catch (e) {
      print("Error ending call: $e");
    }
  }

  Future<void> _toggleSpeaker() async {
    _setSpeakerphone(!_isSpeakerEnabled);
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _agoraService.toggleMute(_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryTextColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio Call',
                style: AppStyles.titleMedium.copyWith(color: AppColors.primaryTextColor),
              ),
              if (_callDuration != Duration.zero)
                Text(
                  'Call duration: ${_formatDuration(_callDuration)}',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryTextColor),
                ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: _isInternetAvailable
                ? null
                : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColorLight, AppColors.primaryColor], // Using primaryColor from AppColors
            ),
          ),
          child: _isInternetAvailable
              ? Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.doctorImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.primaryColor.withOpacity(0.2), AppColors.primaryColor],
                      stops: const [0.0, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 240),
                    Text(
                      widget.doctorName,
                      style: AppStyles.titleLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    if (!_isConnected)
                      _isRinging
                          ? FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                        child: Text(
                          'Ringing...',
                          style: AppStyles.titleMedium.copyWith(color: Colors.white),
                        ),
                      )
                          : Container()
                    else
                      Text(
                        'Connected',
                        style: AppStyles.bodyLarge.copyWith(color: Colors.white),
                      ),

                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMuted ? Colors.black.withOpacity(0.3) : Colors.transparent,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                      FloatingActionButton(
                        backgroundColor: const Color(0xFFE63946),
                        onPressed: _isCallEnded ? null : endCall,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSpeakerEnabled ? Colors.black.withOpacity(0.3) : Colors.transparent,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isSpeakerEnabled ? Icons.speaker_phone : Icons.volume_up,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _toggleSpeaker,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (agoraErrorMessage != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red,
                    child: Text(
                      agoraErrorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          )
              : Center(
            child: Text(
              'No internet connection. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppStyles.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}*/





