import 'package:flutter/material.dart';

class CustomLoadingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20.0),
                Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}