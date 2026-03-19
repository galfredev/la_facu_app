import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth/googleapis_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_facu/core/services/google_calendar_service.dart';
import 'package:la_facu/features/subjects/data/subject_repository.dart';

// Provider para la API de Calendario
final calendarApiProvider = FutureProvider<calendar.CalendarApi?>((ref) async {
  final googleAuth = ref.watch(googleAuthProvider.notifier);
  final account = ref.watch(googleAuthProvider);

  if (account == null) {
    return null;
  }

  // GoogleSignInAccount tiene el método `authHeaders` que nos da el token
  final headers = await googleAuth.authHeaders;

  // Creamos un cliente HTTP que inyecte los headers de autenticación automáticamente
  final authenticatedClient = GoogleAuthClient(headers);
  
  return calendar.CalendarApi(authenticatedClient);
});

// Helper para inyectar headers en peticiones http.Client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
