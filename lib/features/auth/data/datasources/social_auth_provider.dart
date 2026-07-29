import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthResult {
  final String idToken;
  final String? name;

  const SocialAuthResult({required this.idToken, this.name});
}

class SocialAuthProvider {
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static Future<SocialAuthResult> signInWithGoogle() async {
    // Sign out first to always show the account picker
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    try {
      final parts = idToken.split('.');
      if (parts.length == 3) {
        var payload = parts[1];
        // Base64url → Base64
        payload = payload.replaceAll('-', '+').replaceAll('_', '/');
        switch (payload.length % 4) {
          case 2: payload += '=='; break;
          case 3: payload += '='; break;
        }
        final decoded = utf8.decode(base64Decode(payload));
        final json = const JsonDecoder().convert(decoded);
        print('=== Google ID Token Payload ===');
        print(const JsonEncoder.withIndent('  ').convert(json));
        print('===============================');
      }
    } catch (e) {
      print('Failed to decode ID token: $e');
    }

    return SocialAuthResult(idToken: idToken, name: account.displayName);
  }

  static Future<SocialAuthResult> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Failed to get Apple ID token');
    }

    String? name;
    if (credential.givenName != null || credential.familyName != null) {
      name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (name.isEmpty) name = null;
    }

    return SocialAuthResult(idToken: idToken, name: name);
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
