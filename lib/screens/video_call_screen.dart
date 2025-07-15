
import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/call_model.dart';
import '../services/agora_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../utils/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_easyloading/flutter_easyloading.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String doctorName;
  final String doctorImageUrl;

  const VideoCallScreen({
    Key? key,
    required this.channelName,
    required this.doctorName,
    required this.doctorImageUrl,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AgoraService _agoraService;
  bool _isCallEnded = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  String? agoraErrorMessage;
  bool _isAgoraInitialized = false;
  bool _isMuted = false;
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

  final List<File> _selectedImages = [];
  double _uploadProgress = 0.0;
  bool _isSelectingImages = false; // Track image selection state

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
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    initCall();

    // Configure EasyLoading in initState
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..backgroundColor = Colors.grey[800]!;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        if (!_isAgoraInitialized) {
          initCall();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _isInBackground = true;
        break;
      case AppLifecycleState.detached:
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      case AppLifecycleState.hidden:
        throw UnimplementedError();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isCallEnded) {
      _endCallAndCleanUp(reason: 'App destroyed');
    }

    // **CRITICAL: Dispose of the AnimationController *before* calling super.dispose()**
    _animationController.dispose();

    super.dispose();
    _stopRinging();
    _stopCallTimer();
    _stopRingingTimer();
    audioPlayer.dispose();
    _connectivitySubscription?.cancel();
    EasyLoading.dismiss();
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
          content:
          Text('No internet connection. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initCall() async {
    if (!_isInternetAvailable) {
      return;
    }
    await initAgora();
  }

  Future<void> initAgora() async {
    agoraErrorMessage = null;

    try {
      final success = await _agoraService.initializeAgora(widget.channelName);
      if (!success) {
        setState(() {
          agoraErrorMessage = _agoraService.agoraErrorMessage;
        });
        return;
      }

      _setupEventHandlers();
      await _agoraService.startLocalPreview();
      await _agoraService.joinChannel(widget.channelName);

      setState(() {
        _isAgoraInitialized = true;
      });
if(Global.appointmentNo=="0"){
  await FirebaseService.updateCallStatus(
    firebaseChannelName,
    CallModel(
      appointmentID: "0",
      callType: "Incoming Video Call",
      callingPlatform: "Webdoc App",
      isCalling: "true",
      senderEmail:
      '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
    ),
  );
      }
else{
  await FirebaseService.updateCallStatus(
    firebaseChannelName,
    CallModel(
      appointmentID: Global.appointmentNo,
      callType: "Incoming Video Call",
      callingPlatform: "Webdoc App",
      isCalling: "true",
      senderEmail:
      '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
    ),
  );
}

      _startRinging();
      _startRingingTimer();
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
          // Global.feedbackDialog = true; // Remove this line here
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
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

  Future<void> _startRinging() async {
    try {
      final source = AssetSource('ringing.mp3');
      await audioPlayer.setSource(source);
      audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(1.0);
      await audioPlayer.resume();

      setState(() {
        _isRinging = true;
      });
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
    return formatter.format(
        DateTime(2024, 1, 1, 0, duration.inMinutes, duration.inSeconds % 60));
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
          senderEmail:
          '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
        ),
      );
      Global.appointmentNo="0";
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

  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
  }

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
        // backgroundColor: Colors.black, // Remove the explicit black color
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColorLight, AppColors.primaryColor], // Using primaryColor from AppColors
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _remoteVideo(),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: SafeArea(
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: _localVideo(),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(  // Wrap the icons in a Column
                    mainAxisSize: MainAxisSize.min, // Ensure the column takes only the space it needs
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
                        children: [
                          IconButton(
                            icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
                            onPressed: _switchCamera,
                          ),
                          IconButton(
                            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic,
                                color: Colors.white, size: 30),
                            onPressed: _toggleMute,
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.white, size: 30),
                            onPressed: () {
                              _showImagePickerDialog(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Add spacing between the icon row and the end call button
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        onPressed: _isCallEnded ? null : endCall,
                        child: const Icon(Icons.call_end),
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
          ),
        ),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              endCall();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctorName,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              if (_callDuration != Duration.zero)
                Text(
                  'Call duration: ${_formatDuration(_callDuration)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
            ],
          ),
          backgroundColor: AppColors.primaryColorLight, // Make app bar transparent
          elevation: 0, // Remove shadow
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),
    );
  }

  Widget _localVideo() {
    if (_isAgoraInitialized && _localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraService.engine!,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeHidden,
          ),
        ),
      );
    } else {
      return const Text(
        'Joining, please wait...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      );
    }
  }

  Widget _remoteVideo() {
    if (_isAgoraInitialized && _remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeFit,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Center(
        child: _isRinging
            ? FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
          child: const Text(
            'Ringing...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        )
            : const Text(
          'Waiting for remote user to join...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
}

/*import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/call_model.dart';
import '../services/agora_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../utils/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_easyloading/flutter_easyloading.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String doctorName;
  final String doctorImageUrl;

  const VideoCallScreen({
    Key? key,
    required this.channelName,
    required this.doctorName,
    required this.doctorImageUrl,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AgoraService _agoraService;
  bool _isCallEnded = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  String? agoraErrorMessage;
  bool _isAgoraInitialized = false;
  bool _isMuted = false;
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

  final List<File> _selectedImages = [];
  double _uploadProgress = 0.0;
  bool _isSelectingImages = false; // Track image selection state

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
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    initCall();

    // Configure EasyLoading in initState
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..backgroundColor = Colors.grey[800]!;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isInBackground = false;
        if (!_isAgoraInitialized) {
          initCall();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _isInBackground = true;
        break;
      case AppLifecycleState.detached:
        if (mounted) {
          Navigator.pop(context);
        }
        break;
      case AppLifecycleState.hidden:
        throw UnimplementedError();
    }
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
    EasyLoading.dismiss();
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
          content:
          Text('No internet connection. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> initCall() async {
    if (!_isInternetAvailable) {
      return;
    }
    await initAgora();
  }

  Future<void> initAgora() async {
    agoraErrorMessage = null;

    try {
      final success = await _agoraService.initializeAgora(widget.channelName);
      if (!success) {
        setState(() {
          agoraErrorMessage = _agoraService.agoraErrorMessage;
        });
        return;
      }

      _setupEventHandlers();
      await _agoraService.startLocalPreview();
      await _agoraService.joinChannel(widget.channelName);

      setState(() {
        _isAgoraInitialized = true;
      });

      await FirebaseService.updateCallStatus(
        firebaseChannelName,
        CallModel(
          appointmentID: "0",
          callType: "Incoming Video Call",
          callingPlatform: "Webdoc App",
          isCalling: "true",
          senderEmail:
          '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
        ),
      );
      _startRinging();
      _startRingingTimer();
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
          // Global.feedbackDialog = true; // Remove this line here
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
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

  Future<void> _startRinging() async {
    try {
      final source = AssetSource('ringing.mp3');
      await audioPlayer.setSource(source);
      audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(1.0);
      await audioPlayer.resume();

      setState(() {
        _isRinging = true;
      });
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
    return formatter.format(
        DateTime(2024, 1, 1, 0, duration.inMinutes, duration.inSeconds % 60));
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
          senderEmail:
          '${SharedPreferencesManager.getString('mobileNumber')}@webdoc.com.pk',
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

  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
  }

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
      final String doctorEmail = 'drnereenawan@webdoccompk';

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
        // backgroundColor: Colors.black, // Remove the explicit black color
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColorLight, AppColors.primaryColor], // Using primaryColor from AppColors
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _remoteVideo(),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: SafeArea(
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: _localVideo(),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(  // Wrap the icons in a Column
                    mainAxisSize: MainAxisSize.min, // Ensure the column takes only the space it needs
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
                        children: [
                          IconButton(
                            icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
                            onPressed: _switchCamera,
                          ),
                          IconButton(
                            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic,
                                color: Colors.white, size: 30),
                            onPressed: _toggleMute,
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.white, size: 30),
                            onPressed: () {
                              _showImagePickerDialog(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Add spacing between the icon row and the end call button
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        onPressed: _isCallEnded ? null : endCall,
                        child: const Icon(Icons.call_end),
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
          ),
        ),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              endCall();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctorName,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              if (_callDuration != Duration.zero)
                Text(
                  'Call duration: ${_formatDuration(_callDuration)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
            ],
          ),
          backgroundColor: AppColors.primaryColorLight, // Make app bar transparent
          elevation: 0, // Remove shadow
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),
    );
  }

  Widget _localVideo() {
    if (_isAgoraInitialized && _localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraService.engine!,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeHidden,
          ),
        ),
      );
    } else {
      return const Text(
        'Joining, please wait...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      );
    }
  }

  Widget _remoteVideo() {
    if (_isAgoraInitialized && _remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeFit,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Center(
        child: _isRinging
            ? FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
          child: const Text(
            'Ringing...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        )
            : const Text(
          'Waiting for remote user to join...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
}*/





