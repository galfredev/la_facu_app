import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_auth_service.g.dart';

@Riverpod(keepAlive: true)
class GoogleAuth extends _$GoogleAuth {
  GoogleSignIn? _googleSignIn;

  @override
  GoogleSignInAccount? build() {
    if (!Platform.isWindows) {
      _googleSignIn = GoogleSignIn(
        clientId: '42417471798-conp6cgh134d0hojvqmts2pff65gsj11.apps.googleusercontent.com',
        scopes: [
          'email',
          'https://www.googleapis.com/auth/calendar.events',
          'https://www.googleapis.com/auth/calendar.readonly',
        ],
      );

      _googleSignIn?.onCurrentUserChanged.listen((account) {
        state = account;
      });

      _googleSignIn?.signInSilently();
    }

    return null;
  }

  Future<GoogleSignInAccount?> login() async {
    if (Platform.isWindows) {
      throw Exception('Google Sign-In no disponible en Windows');
    }
    
    try {
      final account = await _googleSignIn?.signIn();
      return account;
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _googleSignIn?.signOut();
    state = null;
  }

  bool get isAuthenticated => state != null;
  
  String? get userEmail => state?.email;
  String? get userName => state?.displayName;
  String? get userAvatar => state?.photoUrl;
  
  // Para obtener los headers de autenticación necesarios para los requests de la API
  Future<Map<String, String>> get authHeaders async {
    if (state == null) return {};
    return await state!.authHeaders;
  }
}
