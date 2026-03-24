import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_auth_service.g.dart';

@Riverpod(keepAlive: true)
class GoogleAuth extends _$GoogleAuth {
  UserInfo? _currentUser;
  bool _hasWarnedMissingCredentials = false;

  static const _desktopClientId =
      '453274240916-5jn4l3f4lu80mrolkk81ome1eojl3oml.apps.googleusercontent.com';
  static const _androidClientId =
      '453274240916-aujidgi1oemn2io0774lcd1ovatdfjmq.apps.googleusercontent.com';

  static const _scopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  @override
  UserInfo? build() => _currentUser;

  Future<UserInfo?> login() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _signInDesktop();
    }
    return _signInMobile();
  }

  Future<UserInfo?> _signInMobile() async {
    try {
      final result = await _authenticateWithGoogle();
      if (result != null) {
        _currentUser = result;
        state = _currentUser;
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Error en autenticacion movil: $e');
      return null;
    }
  }

  Future<UserInfo?> _signInDesktop() async {
    try {
      final authResult = await _getAuthorizationCodeDesktop();
      if (authResult == null) {
        return null;
      }

      final userInfo = await _getUserInfoFromCode(
        authResult.code,
        authResult.redirectUri,
        authResult.codeVerifier,
      );

      if (userInfo != null) {
        _currentUser = userInfo;
        state = userInfo;
      }

      return userInfo;
    } catch (e) {
      debugPrint('Error en autenticacion de escritorio: $e');
      return null;
    }
  }

  Future<UserInfo?> _authenticateWithGoogle() async {
    final clientId = _authClientId;
    if (clientId.isEmpty) {
      _warnMissingCredentials();
      return null;
    }

    const redirectUri = 'la-facu://oauth2callback';
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallengeS256(codeVerifier);

    final state = DateTime.now().millisecondsSinceEpoch.toString();
    final authUrl = Uri.parse(
      'https://accounts.google.com/o/oauth2/v2/auth'
      '?client_id=${Uri.encodeComponent(clientId)}'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&response_type=code'
      '&scope=${Uri.encodeComponent(_scopes.join(' '))}'
      '&state=$state'
      '&access_type=offline'
      '&prompt=consent'
      '&code_challenge=${Uri.encodeComponent(codeChallenge)}'
      '&code_challenge_method=S256',
    );

    try {
      await Clipboard.setData(ClipboardData(text: authUrl.toString()));

      final response = await _waitForCode(duration: const Duration(minutes: 5));

      if (response != null && response.isNotEmpty) {
        return _getUserInfoFromCode(response, redirectUri, codeVerifier);
      }
    } catch (e) {
      debugPrint('Error en autenticacion: $e');
    }

    return null;
  }

  Future<_DesktopAuthResult?> _getAuthorizationCodeDesktop() async {
    final clientId = _authClientId;
    if (clientId.isEmpty) {
      _warnMissingCredentials();
      return null;
    }

    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: true,
    );
    final redirectUri = 'http://localhost:${server.port}/callback';
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallengeS256(codeVerifier);
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final authUrl = Uri(
      scheme: 'https',
      host: 'accounts.google.com',
      path: '/o/oauth2/v2/auth',
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'state': state,
        'access_type': 'offline',
        'prompt': 'consent',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    debugPrint('OAuth URL: ${authUrl.toString()}');
    await Clipboard.setData(ClipboardData(text: authUrl.toString()));

    if (!await _openBrowser(authUrl.toString())) {
      debugPrint(
        'No se pudo abrir el navegador automaticamente. La URL esta en el portapapeles.',
      );
    }

    final completer = Completer<_DesktopAuthResult?>();

    unawaited(() async {
      try {
        await for (final request in server) {
          if (request.uri.path != '/callback') {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            continue;
          }

          final code = request.uri.queryParameters['code'];
          request.response.headers.contentType = ContentType.html;
          request.response.write(_buildOAuthResponse(code != null));
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(
              code == null
                  ? null
                  : _DesktopAuthResult(
                      code: code,
                      redirectUri: redirectUri,
                      codeVerifier: codeVerifier,
                    ),
            );
          }

          await server.close(force: true);
          break;
        }
      } catch (e) {
        debugPrint('Error en servidor OAuth: $e');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }());

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () async {
        await server.close(force: true);
        return null;
      },
    );
  }

  Future<UserInfo?> _getUserInfoFromCode(
    String authCode,
    String redirectUri,
    String codeVerifier,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _authClientId,
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String? ?? '';

      final userResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        return null;
      }

      final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
      return UserInfo(
        id: userData['id'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        displayName: userData['name'] as String? ?? '',
        photoUrl: userData['picture'] as String?,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('Error obteniendo userinfo: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    state = null;
  }

  bool get isAuthenticated => _currentUser != null;

  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userAvatar => _currentUser?.photoUrl;

  Future<Map<String, String>> get authHeaders async {
    final accessToken = _currentUser?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return {};
    }

    return {'Authorization': 'Bearer $accessToken'};
  }

  void _warnMissingCredentials() {
    if (_hasWarnedMissingCredentials) {
      return;
    }

    _hasWarnedMissingCredentials = true;
    debugPrint('Faltan credenciales de Google para autenticacion.');
  }

  String get _authClientId {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _desktopClientId;
    }
    return _androidClientId;
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _codeChallengeS256(String codeVerifier) {
    final bytes = sha256.convert(utf8.encode(codeVerifier)).bytes;
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

Future<bool> _openBrowser(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.start('powershell', [
        '-NoProfile',
        '-Command',
        'Start-Process -FilePath "${url.replaceAll('"', '`"')}"',
      ]);
      return true;
    }

    if (Platform.isMacOS) {
      await Process.start('open', [url]);
      return true;
    }

    if (Platform.isLinux) {
      await Process.start('xdg-open', [url]);
      return true;
    }
  } catch (_) {
    return false;
  }

  return false;
}

String _buildOAuthResponse(bool success) {
  final title = success ? 'SesiÃ³n conectada' : 'No pudimos conectar';
  final color = success ? '#2e7d32' : '#d32f2f';
  final message = success
      ? 'Ya podés volver a La Facu. Esta pestaña se puede cerrar.'
      : 'VolvÃ© a la app e intentÃ¡ de nuevo.';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>La Facu</title>
</head>
<body style="margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center; background:linear-gradient(180deg,#f7f9ff 0%,#eef4ff 100%); font-family: Inter, Arial, sans-serif;">
  <div style="width:min(560px, calc(100vw - 32px)); padding:32px; border-radius:28px; background:rgba(255,255,255,0.92); box-shadow:0 18px 60px rgba(27,78,163,0.12); border:1px solid rgba(46,125,50,0.08);">
    <div style="display:flex; align-items:center; gap:14px; margin-bottom:18px;">
      <div style="width:52px; height:52px; border-radius:16px; background:linear-gradient(135deg, #1b74e4, #7fc8a9); display:flex; align-items:center; justify-content:center; color:white; font-size:22px;">Ã¢Å“â€œ</div>
      <div>
        <div style="font-size:13px; text-transform:uppercase; letter-spacing:2px; color:#5f6c82;">La Facu Ã‚Â· Google</div>
        <h2 style="margin:4px 0 0; color:$color; font-size:28px; line-height:1.1;">$title</h2>
      </div>
    </div>
    <p style="margin:0 0 10px; color:#304056; font-size:16px; line-height:1.6;">$message</p>
    <p style="margin:0; color:#6b778c; font-size:13px;">Galfred Dev</p>
  </div>
  <script>
    setTimeout(() => window.close(), 1200);
  </script>
</body>
</html>
''';
}

class UserInfo {
  UserInfo({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accessToken,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? accessToken;
}

Future<String?> _waitForCode({required Duration duration}) async {
  final completer = Completer<String?>();
  Timer(duration, () {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });
  return completer.future;
}

class _DesktopAuthResult {
  const _DesktopAuthResult({
    required this.code,
    required this.redirectUri,
    required this.codeVerifier,
  });

  final String code;
  final String redirectUri;
  final String codeVerifier;
}
