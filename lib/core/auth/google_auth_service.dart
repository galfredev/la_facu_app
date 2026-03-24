import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'google_auth_service.g.dart';

@Riverpod(keepAlive: true)
class GoogleAuth extends _$GoogleAuth {
  UserInfo? _currentUser;
  bool _hasWarnedMissingCredentials = false;
  bool _didRestoreSession = false;
  String? _lastAuthFailure;

  static const _desktopClientId =
      '453274240916-5jn4l3f4lu80mrolkk81ome1eojl3oml.apps.googleusercontent.com';
  static const _androidClientId =
      '453274240916-aujidgi1oemn2io0774lcd1ovatdfjmq.apps.googleusercontent.com';

  static const _scopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  @override
  UserInfo? build() {
    if (!_didRestoreSession) {
      _didRestoreSession = true;
      unawaited(_restoreSession());
    }
    return _currentUser;
  }

  Future<UserInfo?> login() async {
    _lastAuthFailure = null;
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
        await _persistSession(result);
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Error en autenticacion movil: $e');
      return null;
    }
  }

  Future<UserInfo?> _signInDesktop() async {
    try {
      final userInfo = await _authenticateDesktop();
      if (userInfo != null) {
        _currentUser = userInfo;
        state = userInfo;
        await _persistSession(userInfo);
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

  Future<UserInfo?> _authenticateDesktop() async {
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
    final redirectUri = 'http://127.0.0.1:${server.port}';
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

    final completer = Completer<UserInfo?>();

    unawaited(() async {
      try {
        await for (final request in server) {
          final requestPath = request.uri.path;
          if (requestPath.isNotEmpty && requestPath != '/') {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            continue;
          }

          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];
          UserInfo? userInfo;

          if (code != null) {
            userInfo = await _getUserInfoFromCode(
              code,
              redirectUri,
              codeVerifier,
            );
          } else if (error != null) {
            debugPrint('Google devolvio un error de OAuth: $error');
          }

          request.response.headers.contentType = ContentType.html;
          request.response.write(_buildOAuthResponse(userInfo != null));
          await request.response.close();

          if (!completer.isCompleted) {
            completer.complete(userInfo);
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
        await _setLastAuthFailure(
          'token_exchange_failed ${response.statusCode}: ${response.body}',
        );
        debugPrint(
          'Error intercambiando code por token: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String? ?? '';
      final idToken = data['id_token'] as String?;

      final userFromIdToken = _userInfoFromIdToken(idToken, accessToken);
      if (userFromIdToken != null) {
        return userFromIdToken;
      }

      final userResponse = await http.get(
        Uri.parse('https://openidconnect.googleapis.com/v1/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        await _setLastAuthFailure(
          'userinfo_failed ${userResponse.statusCode}: ${userResponse.body}',
        );
        debugPrint(
          'Error obteniendo userinfo: ${userResponse.statusCode} ${userResponse.body}',
        );
        return null;
      }

      final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
      return UserInfo(
        id: userData['id'] as String? ?? userData['sub'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        displayName: userData['name'] as String? ?? '',
        photoUrl: userData['picture'] as String?,
        accessToken: accessToken,
      );
    } catch (e) {
      await _setLastAuthFailure('userinfo_exception: $e');
      debugPrint('Error obteniendo userinfo: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    state = null;
    _lastAuthFailure = null;
    await _clearSession();
  }

  bool get isAuthenticated => _currentUser != null;

  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userAvatar => _currentUser?.photoUrl;
  String? get lastAuthFailure => _lastAuthFailure;

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

  Future<void> _persistSession(UserInfo user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_user_id', user.id);
    await prefs.setString('google_user_email', user.email);
    await prefs.setString('google_user_name', user.displayName);
    await prefs.setString('google_user_photo', user.photoUrl ?? '');
    await prefs.setString('google_user_access_token', user.accessToken ?? '');
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('google_user_email') ?? '';
    if (email.isEmpty) {
      return;
    }

    final restoredUser = UserInfo(
      id: prefs.getString('google_user_id') ?? '',
      email: email,
      displayName: prefs.getString('google_user_name') ?? '',
      photoUrl: (prefs.getString('google_user_photo') ?? '').trim().isEmpty
          ? null
          : prefs.getString('google_user_photo'),
      accessToken:
          (prefs.getString('google_user_access_token') ?? '').trim().isEmpty
          ? null
          : prefs.getString('google_user_access_token'),
    );

    _currentUser = restoredUser;
    state = restoredUser;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_user_id');
    await prefs.remove('google_user_email');
    await prefs.remove('google_user_name');
    await prefs.remove('google_user_photo');
    await prefs.remove('google_user_access_token');
  }

  Future<void> _setLastAuthFailure(String message) async {
    _lastAuthFailure = message;
    debugPrint('Google auth failure: $message');

    try {
      final logFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}la_facu_google_auth.log',
      );
      final timestamp = DateTime.now().toIso8601String();
      await logFile.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Best-effort debug trace only.
    }
  }

  UserInfo? _userInfoFromIdToken(String? idToken, String accessToken) {
    if (idToken == null || idToken.isEmpty) {
      return null;
    }

    try {
      final parts = idToken.split('.');
      if (parts.length < 2) {
        return null;
      }

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalizedPayload)))
              as Map<String, dynamic>;

      return UserInfo(
        id: payload['sub'] as String? ?? '',
        email: payload['email'] as String? ?? '',
        displayName: payload['name'] as String? ?? '',
        photoUrl: payload['picture'] as String?,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('No se pudo parsear el id_token: $e');
      return null;
    }
  }
}

Future<bool> _openBrowser(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.start('rundll32.exe', ['url.dll,FileProtocolHandler', url]);
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
  final title = success
      ? 'Conexion completada'
      : 'No pudimos completar la conexion';
  final accent = success ? '#10b981' : '#fb7185';
  final message = success
      ? 'La verificacion con Google se realizo correctamente. Ya podes cerrar esta pestana y volver a la app.'
      : 'Google no termino de validar la sesion en la app. Volve y reintenta.';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>La Facu</title>
</head>
<body style="margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center; background:radial-gradient(circle at top right, rgba(99,102,241,0.34), transparent 30%), radial-gradient(circle at bottom left, rgba(16,185,129,0.15), transparent 24%), linear-gradient(180deg,#0f172a 0%,#111827 100%); font-family: Manrope, Segoe UI, Arial, sans-serif; color:#e5eefc;">
  <div style="width:min(480px, calc(100vw - 32px)); padding:42px 30px 34px; border-radius:32px; background:rgba(15,23,42,0.88); box-shadow:0 18px 60px rgba(0,0,0,0.28); border:1px solid rgba(99,102,241,0.16); backdrop-filter: blur(16px); text-align:center;">
    <div style="width:72px; height:72px; margin:0 auto 22px; border-radius:24px; background:linear-gradient(135deg, rgba(99,102,241,0.95), rgba(16,185,129,0.9)); display:flex; align-items:center; justify-content:center; box-shadow:0 18px 38px rgba(99,102,241,0.24);">
      <div style="width:26px; height:15px; border-left:4px solid white; border-bottom:4px solid white; transform:rotate(-45deg); margin-top:-4px;"></div>
    </div>
    <h1 style="margin:0; color:#f8fafc; font-size:20px; line-height:1.2; font-weight:700; letter-spacing:0;">La Facu</h1>
    <p style="margin:6px 0 0; color:#10b981; font-size:12px; font-weight:700; letter-spacing:2.6px; text-transform:uppercase;">ESTUDIANTE ENFOCADO</p>
    <p style="margin:26px 0 0; color:#f8fafc; font-size:22px; font-weight:700; line-height:1.3;">$title</p>
    <p style="margin:12px auto 0; max-width:340px; color:#c7d8ff; font-size:15px; line-height:1.7;">$message</p>
    <p style="margin:18px 0 0; color:$accent; font-size:13px; font-weight:600;">Google</p>
  </div>
  <script>
    setTimeout(() => window.close(), 2200);
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
