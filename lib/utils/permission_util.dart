// permission_util.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> requestPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    bool allGranted = statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;

    if (!allGranted) {
      // Check if permissions are permanently denied
      bool cameraPermanentlyDenied = statuses[Permission.camera]!.isPermanentlyDenied;
      bool microphonePermanentlyDenied = statuses[Permission.microphone]!.isPermanentlyDenied;

      if (cameraPermanentlyDenied || microphonePermanentlyDenied) {
        showSettingsDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera and microphone permissions are required')),
        );
      }
      return false;
    }

    return true;
  }

  static void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'You have permanently denied some permissions. Please go to settings to enable them.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Go to Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}