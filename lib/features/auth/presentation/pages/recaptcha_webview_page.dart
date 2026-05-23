import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class RecaptchaWebViewPage extends StatefulWidget {
  final String phone;
  const RecaptchaWebViewPage({super.key, required this.phone});

  @override
  State<RecaptchaWebViewPage> createState() => _RecaptchaWebViewPageState();
}

class _RecaptchaWebViewPageState extends State<RecaptchaWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const _apiKey = 'AIzaSyA2wFEmMGKxs82LHlFUwa4bztB5HHYFKx0';
  static const _authDomain = 'studio-6503153993-be5d6.firebaseapp.com';
  static const _projectId = 'studio-6503153993-be5d6';
  static const _messagingSenderId = '844365789676';

  static const _html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #ffffff;
      font-family: -apple-system, sans-serif;
    }
    p {
      margin-bottom: 28px;
      color: #555;
      font-size: 15px;
      text-align: center;
      padding: 0 24px;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <p>Please complete the security check to receive your SMS code.</p>
  <div id="recaptcha-container"></div>

  <script type="module">
    import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
    import { getAuth, RecaptchaVerifier } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';

    const app = initializeApp({
      apiKey: '$_apiKey',
      authDomain: '$_authDomain',
      projectId: '$_projectId',
      messagingSenderId: '$_messagingSenderId',
    });

    const auth = getAuth(app);
    auth.useDeviceLanguage();

    const verifier = new RecaptchaVerifier(auth, 'recaptcha-container', {
      size: 'normal',
      callback: (token) => {
        RecaptchaChannel.postMessage(token);
      },
    });

    verifier.render();
  </script>
</body>
</html>
''';

  void _onRecaptchaToken(String token) {
    if (!mounted) return;
    context.read<AuthBloc>().add(
      AuthSendOtpRestEvent(phone: widget.phone, recaptchaToken: token),
    );
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (msg) => _onRecaptchaToken(msg.message),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ))
      ..loadHtmlString(_html, baseUrl: 'https://$_authDomain');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
