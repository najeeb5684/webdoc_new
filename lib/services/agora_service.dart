
/*import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as StandardBitrate;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AgoraService {
  static const String appId =
      "f0924810ffd04733b7a726cb961157cd"; // Replace with your Agora App ID
  RtcEngine? engine;
  String? channelName;
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  bool localVideoRendered = false;
  String? agoraErrorMessage;
  bool isSpeakerEnabled = true;

  // Static constants for UI
  static const Widget _joiningText = Text(
    'Joining...',
    textAlign: TextAlign.center,
  );
  static const Widget _waitingText = Text(
    'Waiting for a remote user to join...',
    textAlign: TextAlign.center,
  );

  Future<bool> initializeAgora(String channelName) async {
    this.channelName = channelName;
    agoraErrorMessage = null;

    try {
      if (kIsWeb) {
        // Web-Specific Initialization
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ));
      } else {
        // Native Initialization
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));
      }

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
                "Flutter: Local user ${connection.localUid} joined channel: ${connection.channelId}");
            isJoined = true;
            agoraErrorMessage = null;
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("Flutter: Local user ${connection.localUid} left channel");
            isJoined = false;
            remoteUid = null;
            localVideoRendered = false;
          },
          onUserJoined: (RtcConnection connection, int remoteUId, int elapsed) {
            debugPrint(
                "Flutter: Remote user $remoteUId joined channel: ${connection.channelId}");
            remoteUid = remoteUId;
          },
          onUserOffline: (RtcConnection connection, int remoteUId,
              UserOfflineReasonType reason) {
            debugPrint(
                "Flutter: Remote user $remoteUId left channel: ${connection.channelId}");
            remoteUid = null;
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUId,
              int width, int height, int elapsed) {
            debugPrint(
                "Flutter: First remote video frame received for user: $remoteUId");
          },
          onError: (ErrorCodeType err, String msg) {
            //Changed the type
            print("Flutter: Agora Engine Error: code=$err, message=$msg");
            agoraErrorMessage = "Agora Engine Error: code=$err, message=$msg";
          },
        ),
      );

      // Conditional Video Configuration
      if (!kIsWeb) {
        // Enable video and set encoder configuration (matching your Android code)
        await engine!.enableVideo();
        await engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 15, //VideoFrameRate.fps15, // Assuming this is the equivalent
            bitrate: StandardBitrate
                .standardBitrate, //Corrected the StandardBitrate here
          ),
        );
      }

      await engine!.setClientRole(
          role: ClientRoleType.clientRoleBroadcaster); //Keep this here

      return true;
    } catch (e) {
      agoraErrorMessage = "Agora initialization error: $e";
      print("Flutter: Agora initialization error: $e");
      return false;
    }
  }

  Future<void> startLocalPreview() async {
    try {
      await engine!.startPreview();
    } catch (e) {
      agoraErrorMessage = "Error starting local preview: $e";
      print("Flutter: Error starting local preview: $e");
    }
  }

  Future<void> joinChannel(String channelName) async {
    print("Flutter: Attempting to join channel: $channelName");
    try {
      await engine?.joinChannel(
        token: "", // Provide an empty token if you're not using one
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
      print('Flutter: Successfully joined the channel: $channelName');
      agoraErrorMessage = null;
    } catch (e) {
      agoraErrorMessage = "Error joining channel: $e";
      print('Flutter: Error joining channel: $e');
    }
  }

  Future<void> leaveChannel() async {
    try {
      await engine?.leaveChannel();
      isJoined = false;
      remoteUid = null;
      localVideoRendered = false;
    } catch (e) {
      print('Flutter: Error leaving channel: $e');
    }
  }

  Future<void> toggleMute(bool muted) async {
    try {
      isMuted = muted;
      await engine?.muteLocalAudioStream(isMuted);
    } catch (e) {
      print("Flutter: Error toggling mute: $e");
      agoraErrorMessage = "Error toggling mute: $e";
    }
  }

  Future<void> switchCamera() async {
    try {
      await engine?.switchCamera();
    } catch (e) {
      print("Flutter: Error switching camera: $e");
      agoraErrorMessage = "Error switching camera: $e";
    }
  }

  Future<void> setEnableSpeakerphone(bool enable) async {
    try {
      await engine?.setEnableSpeakerphone(enable);
      isSpeakerEnabled = enable;
    } catch (e) {
      print("Flutter: Error setting speakerphone: $e");
      agoraErrorMessage = "Error setting speakerphone: $e";
    }
  }

  void dispose() {
    engine?.leaveChannel();
    engine?.release();
    engine = null;
  }
}*/



import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as StandardBitrate
    show standardBitrate; // Corrected import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AgoraService {
  static const String appId =
      "f0924810ffd04733b7a726cb961157cd"; // Replace with your Agora App ID
  RtcEngine? engine;
  String? channelName;
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  bool localVideoRendered = false;
  String? agoraErrorMessage;
  bool isSpeakerEnabled = true;

  // Static constants for UI
  static const Widget _joiningText = Text(
    'Joining...',
    textAlign: TextAlign.center,
  );
  static const Widget _waitingText = Text(
    'Waiting for a remote user to join...',
    textAlign: TextAlign.center,
  );

  Future<bool> initializeAgora(String channelName) async {
    this.channelName = channelName;
    agoraErrorMessage = null;

    try {
      if (kIsWeb) {
        // Web-Specific Initialization
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ));
      } else {
        // Native Initialization
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));
      }

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
                "Flutter: Local user ${connection.localUid} joined channel: ${connection.channelId}");
            isJoined = true;
            agoraErrorMessage = null;
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("Flutter: Local user ${connection.localUid} left channel");
            isJoined = false;
            remoteUid = null;
            localVideoRendered = false;
          },
          onUserJoined: (RtcConnection connection, int remoteUId, int elapsed) {
            debugPrint(
                "Flutter: Remote user $remoteUId joined channel: ${connection.channelId}");
            remoteUid = remoteUId;
          },
          onUserOffline: (RtcConnection connection, int remoteUId,
              UserOfflineReasonType reason) {
            debugPrint(
                "Flutter: Remote user $remoteUId left channel: ${connection.channelId}");
            remoteUid = null;
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUId,
              int width, int height, int elapsed) {
            debugPrint(
                "Flutter: First remote video frame received for user: $remoteUId");
          },
          onError: (ErrorCodeType err, String msg) {
            //Changed the type
            print("Flutter: Agora Engine Error: code=$err, message=$msg");
            agoraErrorMessage = "Agora Engine Error: code=$err, message=$msg";
          },
        ),
      );

      // Conditional Video Configuration
      if (!kIsWeb) {
        // Enable video and set encoder configuration (matching your Android code)
        await engine!.enableVideo();
        await engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 15, //VideoFrameRate.fps15, // Assuming this is the equivalent
            bitrate: StandardBitrate
                .standardBitrate, //Corrected the StandardBitrate here
          ),
        );
      }

      await engine!.setClientRole(
          role: ClientRoleType.clientRoleBroadcaster); //Keep this here

      return true;
    } catch (e) {
      agoraErrorMessage = "Agora initialization error: $e";
      print("Flutter: Agora initialization error: $e");
      return false;
    }
  }

  Future<void> startLocalPreview() async {
    try {
      await engine!.startPreview();
    } catch (e) {
      agoraErrorMessage = "Error starting local preview: $e";
      print("Flutter: Error starting local preview: $e");
    }
  }

  Future<void> joinChannel(String channelName) async {
    print("Flutter: Attempting to join channel: $channelName");
    try {
      await engine?.joinChannel(
        token: "", // Provide an empty token if you're not using one
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
      print('Flutter: Successfully joined the channel: $channelName');
      agoraErrorMessage = null;
    } catch (e) {
      agoraErrorMessage = "Error joining channel: $e";
      print('Flutter: Error joining channel: $e');
    }
  }

  Future<void> leaveChannel() async {
    try {
      await engine?.leaveChannel();
      isJoined = false;
      remoteUid = null;
      localVideoRendered = false;
    } catch (e) {
      print('Flutter: Error leaving channel: $e');
    }
  }

  Future<void> toggleMute(bool muted) async {
    try {
      isMuted = muted;
      await engine?.muteLocalAudioStream(isMuted);
    } catch (e) {
      print("Flutter: Error toggling mute: $e");
      agoraErrorMessage = "Error toggling mute: $e";
    }
  }

  Future<void> switchCamera() async {
    try {
      await engine?.switchCamera();
    } catch (e) {
      print("Flutter: Error switching camera: $e");
      agoraErrorMessage = "Error switching camera: $e";
    }
  }

  Future<void> setEnableSpeakerphone(bool enable) async {
    try {
      await engine?.setEnableSpeakerphone(enable);
      isSpeakerEnabled = enable;
    } catch (e) {
      print("Flutter: Error setting speakerphone: $e");
      agoraErrorMessage = "Error setting speakerphone: $e";
    }
  }

  void dispose() {
    engine?.leaveChannel();
    engine?.release();
    engine = null;
  }
}
