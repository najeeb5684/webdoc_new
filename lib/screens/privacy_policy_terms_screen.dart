import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/global.dart';

class PrivacyPolicyTermsScreen extends StatefulWidget {
  const PrivacyPolicyTermsScreen({Key? key}) : super(key: key);

  @override
  _PrivacyPolicyTermsScreenState createState() =>
      _PrivacyPolicyTermsScreenState();
}

class _PrivacyPolicyTermsScreenState extends State<PrivacyPolicyTermsScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;
  String _url = '';
  String _title = '';

  @override
  void initState() {
    super.initState();

    if (Global.privacyTermsUrl == "privacy") {
      _url = "https://webdoc.com.pk/applinks/privacy.html";
      _title = "Privacy Policy";
    } else if (Global.privacyTermsUrl == "terms") {
      _url = "https://webdoc.com.pk/applinks/tandc.html";
      _title = "Terms & Conditions";
    } else if (Global.privacyTermsUrl == "faqs") {
      _url = "https://webdoc.com.pk/applinks/faqs.html";
      _title = "FAQ'S";
    } else if (Global.privacyTermsUrl == "delete") {
      _url = "https://webdoc.com.pk/deletionform/";
      _title = "Delete Account";
    }  else if (Global.privacyTermsUrl == "package") {
      _url = "https://webdoc.com.pk/applinks/producttc.html";
      _title = "Terms & Condition";
    }


    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingProgress = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingProgress = 1.0;
            });

            // Delay the reset of _loadingProgress
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                // Check if the widget is still mounted
                setState(() {
                  _loadingProgress = 0;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
            setState(() {
              _loadingProgress = 0;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_url))
      ..runJavaScript(
          'document.body.style.backgroundColor = "white";'); // Set background using javascript
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // Stay in the current route (webview)
        } else {
          return true; // Allow the route to be popped.
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_title), // Use _title here
        ),
        body: Column(
          children: [
            if (_loadingProgress > 0 && _loadingProgress < 1)
              LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.grey[300],
              ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loadingProgress > 0 && _loadingProgress < 1)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Loading...", style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}