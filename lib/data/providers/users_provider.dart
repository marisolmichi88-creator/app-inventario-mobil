import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserCreationResult {
  final bool requiresEmailConfirmation;

  const UserCreationResult({required this.requiresEmailConfirmation});
}

class UsersProvider with ChangeNotifier {
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _loadError;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  final _supabase = Supabase.instance.client;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .order('name');
      _users = response.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      // Sin esto la pantalla anunciaba "No hay usuarios registrados" cuando en
      // realidad la consulta falló: dos diagnósticos opuestos con la misma cara.
      _loadError = describeError(e);
      debugPrint('Error fetching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Traduce el fallo de la Edge Function a la frase que devolvió ella misma.
  static String _functionErrorMessage(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (details is String && details.isNotEmpty) return details;
    return 'La gestión de usuarios falló (HTTP ${e.status}).';
  }

  static Exception _functionMissing(String operacion) {
    return Exception(
      'Falta desplegar la función "admin-users" en Supabase. '
      'Sin ella no se puede $operacion, porque esa operación necesita una '
      'llave que no puede vivir dentro de la app.',
    );
  }

  Future<UserCreationResult> addUser(UserModel user) async {
    try {
      await _supabase.functions.invoke(
        'admin-users',
        body: {
          'action': 'create',
          'email': user.email.trim().toLowerCase(),
          'password': user.password,
          'name': user.name,
          'role': user.role,
        },
      );
      await fetchUsers();
      // La función crea la cuenta ya confirmada, así que el usuario entra de
      // inmediato y no hay ningún correo que esperar.
      return const UserCreationResult(requiresEmailConfirmation: false);
    } on FunctionException catch (e) {
      if (e.status == 404) {
        // Todavía no está desplegada: se usa el camino anterior para no dejar
        // al panel sin poder dar de alta a nadie.
        return _addUserViaPublicSignup(user);
      }
      throw Exception(_functionErrorMessage(e));
    }
  }

  /// Alta por el endpoint público de registro. Es el camino previo a la Edge
  /// Function y se conserva solo como respaldo: obliga a dejar abierta el alta
  /// de usuarios en Supabase y no puede confirmar el correo por su cuenta.
  Future<UserCreationResult> _addUserViaPublicSignup(UserModel user) async {
    try {
      final url = Uri.parse(
        'https://xzegdfhcxypnffurfvwc.supabase.co/auth/v1/signup',
      );
      final response = await http.post(
        url,
        headers: {
          'apikey': 'sb_publishable_WqoRr7eEbZnsGKZHctLUJQ_MyIv1B0n',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email.trim().toLowerCase(),
          'password': user.password,
          'data': {'name': user.name, 'role': user.role},
        }),
      );

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final authResponse = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      final nestedUser = authResponse['user'];
      final authUser = nestedUser is Map
          ? Map<String, dynamic>.from(nestedUser)
          : authResponse;
      final authUserId = authUser['id']?.toString();

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          authUserId != null) {
        // Supabase oculta que un correo ya esté registrado: responde 200 con un
        // usuario falso y la lista de identidades vacía. Sin esta comprobación
        // se crea un perfil huérfano, apuntando a un id de Auth inexistente,
        // que aparece en la lista pero nunca puede iniciar sesión.
        final identities = authUser['identities'];
        if (identities is List && identities.isEmpty) {
          throw Exception(
            'Ese correo ya tiene una cuenta en Supabase Auth. Búscala en '
            'Authentication > Users: si quedó de un intento anterior, '
            'elimínala ahí y vuelve a crearla, o usa otro correo.',
          );
        }

        final data = user.toMap();
        data.remove('id'); // Remove id so we don't update the primary key
        data['auth_user_id'] = authUserId;
        data['email'] = user.email.trim().toLowerCase();

        // El trigger crea un perfil inactivo y sin privilegios. La sesión del
        // administrador es la única que puede activarlo y asignarle el rol.
        //
        // Aquí no se usa maybeSingle(): en postgrest 2.8.0 no devuelve null con
        // cero filas, sino que lanza el 406 PGRST116 que responde PostgREST. Una
        // lista vacía es la misma pregunta sin depender de ese comportamiento.
        List<Map<String, dynamic>> updated;
        try {
          updated = await _supabase
              .from('user_profiles')
              .update(data)
              .eq('auth_user_id', authUserId)
              .select();
        } on PostgrestException catch (e) {
          throw Exception(_describePostgrest(e, 'activar el perfil'));
        }
        Map<String, dynamic>? profile = updated.isEmpty ? null : updated.first;

        if (profile == null) {
          // Un UPDATE bloqueado por RLS no lanza error: afecta cero filas. Hay
          // que distinguir ese caso de que el perfil todavía no exista, porque
          // el mensaje para el administrador es completamente distinto.
          List<Map<String, dynamic>> existing;
          try {
            existing = await _supabase
                .from('user_profiles')
                .select()
                .eq('auth_user_id', authUserId)
                .limit(1);
          } on PostgrestException catch (_) {
            existing = const [];
          }

          if (existing.isNotEmpty) {
            throw Exception(
              'La cuenta se creó en Auth, pero la base de datos no dejó '
              'activar su perfil. Tu sesión no está pasando el control de '
              'administrador (RLS): revisa que tu propio perfil tenga '
              'role = admin e is_active = true, y que se haya ejecutado '
              'supabase_account_security.sql en Supabase.',
            );
          }

          // El trigger es síncrono, pero este respaldo permite recuperar una
          // instalación antigua donde todavía no se hubiera creado.
          try {
            profile = await _supabase
                .from('user_profiles')
                .insert(data)
                .select()
                .single();
          } on PostgrestException catch (e) {
            throw Exception(_describePostgrest(e, 'crear el perfil'));
          }
        }

        final profileIsValid =
            profile['auth_user_id']?.toString() == authUserId &&
            profile['role'] == user.role &&
            profile['is_active'] == true &&
            profile['email']?.toString().toLowerCase() ==
                user.email.trim().toLowerCase();
        if (!profileIsValid) {
          throw Exception(
            'La cuenta se creó en autenticación, pero su perfil quedó como '
            'rol "${profile['role']}", activo=${profile['is_active']}, '
            'correo "${profile['email']}". Desactívala y contacta a soporte '
            'antes de entregarla al usuario.',
          );
        }

        await fetchUsers();
        final requiresConfirmation =
            authResponse['access_token'] == null &&
            authResponse['session'] == null &&
            authUser['email_confirmed_at'] == null;
        return UserCreationResult(
          requiresEmailConfirmation: requiresConfirmation,
        );
      } else {
        final message =
            authResponse['msg'] ??
            authResponse['message'] ??
            authResponse['error_description'] ??
            authResponse['error'] ??
            'No se pudo registrar al usuario en Supabase.';
        // El código de Auth se conserva: es lo único que permite distinguir un
        // límite de correos de un registro deshabilitado sin abrir los logs.
        final code = authResponse['error_code'] ?? authResponse['code'];
        final detalle = code == null
            ? 'Auth ${response.statusCode}'
            : 'Auth ${response.statusCode} / $code';
        throw Exception(
          '${_translateSignupError(message.toString())} [$detalle]',
        );
      }
    } catch (e) {
      debugPrint('Error adding user: $e');
      rethrow;
    }
  }

  static String _translateSignupError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('already registered') ||
        normalized.contains('already exists') ||
        normalized.contains('user_already_exists')) {
      return 'Ese correo ya tiene una cuenta. Si fue eliminada de la lista, '
          'reactívala desde Supabase Auth o usa otro correo.';
    }
    if (normalized.contains('signup') &&
        (normalized.contains('not allowed') ||
            normalized.contains('disabled'))) {
      return 'Supabase tiene desactivado el alta de usuarios. Actívala en '
          'Authentication > Sign In / Providers > Allow new users to sign up.';
    }
    if (normalized.contains('email rate limit') ||
        normalized.contains('over_email_send_rate_limit')) {
      return 'Supabase llegó a su límite de correos por hora: el SMTP de '
          'prueba envía muy pocos. Espera una hora o configura un SMTP propio.';
    }
    if (normalized.contains('password') &&
        (normalized.contains('short') || normalized.contains('characters'))) {
      return 'La contraseña no cumple la longitud mínima requerida.';
    }
    if (normalized.contains('email') && normalized.contains('invalid')) {
      return 'El correo electrónico no es válido.';
    }
    if (normalized.contains('rate') || normalized.contains('too many')) {
      return 'Se hicieron demasiados intentos. Espera unos minutos.';
    }
    return message;
  }

  /// Traduce cualquier fallo del panel de usuarios a una frase accionable, sin
  /// perder el código técnico: es lo que permite distinguir un bloqueo de RLS
  /// de una columna faltante sin tener que abrir los logs de Supabase.
  static String describeError(Object error) {
    if (error is PostgrestException) {
      return _describePostgrest(error, 'guardar el usuario');
    }
    final text = error.toString().replaceAll('Exception: ', '');
    final normalized = text.toLowerCase();
    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('clientexception') ||
        normalized.contains('timeoutexception')) {
      return 'No hay conexión con el servidor. Revisa tu internet e '
          'inténtalo de nuevo.';
    }
    return text;
  }

  static String _describePostgrest(PostgrestException e, String accion) {
    final detalle = '[${e.code ?? 'sin código'}] ${e.message}';
    switch (e.code) {
      case '42501':
        return 'La base de datos bloqueó $accion por seguridad (RLS). Tu '
            'sesión no está reconocida como administrador activo, o falta '
            'ejecutar supabase_account_security.sql en Supabase. $detalle';
      case '23505':
        return 'Ya existe un perfil con ese correo o esa cuenta de Auth. '
            'Revisa la lista antes de volver a crearlo. $detalle';
      case '23502':
        return 'La tabla user_profiles exige una columna que la app no envía. '
            'Dale un valor por defecto o permite nulos. $detalle';
      case '23503':
        return 'El perfil apunta a una cuenta de Auth que ya no existe. '
            '$detalle';
      case '42703':
        return 'La tabla user_profiles no tiene alguna de las columnas que la '
            'app envía (name, email, role, is_active, auth_user_id). $detalle';
      case '42P01':
        return 'No existe la tabla user_profiles en esta base de datos. '
            '$detalle';
      case 'PGRST116':
        return 'La consulta no devolvió el perfil esperado, probablemente '
            'porque RLS lo oculta para tu sesión. $detalle';
      default:
        return 'No se pudo $accion. $detalle';
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _supabase.functions.invoke(
        'admin-users',
        body: {
          'action': 'update',
          'id': user.id,
          'name': user.name,
          'role': user.role,
          'email': user.email.trim().toLowerCase(),
          'is_active': user.isActive,
        },
      );
      await fetchUsers();
    } on FunctionException catch (e) {
      if (e.status != 404) throw Exception(_functionErrorMessage(e));

      // Sin la función desplegada solo se puede tocar la copia del perfil. El
      // correo de acceso vive en Auth, así que cambiarlo aquí dejaría la
      // pantalla mostrando uno con el que nadie puede iniciar sesión.
      final anterior = _users.where((u) => u.id == user.id).firstOrNull;
      final correoCambio =
          anterior != null &&
          anterior.email.toLowerCase() != user.email.trim().toLowerCase();
      if (correoCambio) throw _functionMissing('cambiar el correo');

      await _updateProfileOnly(user);
    }
  }

  Future<void> _updateProfileOnly(UserModel user) async {
    final data = user.toMap();
    data.remove('id');
    data.remove('email');
    try {
      await _supabase.from('user_profiles').update(data).eq('id', user.id!);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error updating user: $e. Retrying without is_active.');
      data.remove('is_active');
      try {
        await _supabase.from('user_profiles').update(data).eq('id', user.id!);
        await fetchUsers();
      } catch (e2) {
        debugPrint('Error updating user again: $e2');
        rethrow;
      }
    }
  }

  /// Elimina la cuenta de acceso y su perfil a la vez. Solo existe a través de
  /// la Edge Function: borrar únicamente la fila de `user_profiles` deja una
  /// cuenta de Auth huérfana, invisible desde la app, que además bloquea ese
  /// correo para cualquier alta futura.
  Future<void> deleteUser(String profileId) async {
    try {
      await _supabase.functions.invoke(
        'admin-users',
        body: {'action': 'delete', 'id': profileId},
      );
      await fetchUsers();
    } on FunctionException catch (e) {
      if (e.status == 404) throw _functionMissing('eliminar cuentas');
      throw Exception(_functionErrorMessage(e));
    }
  }

  /// Desactivar es lo que conviene en la mayoría de los casos: conserva el
  /// historial de movimientos del usuario y es reversible. Eliminar de verdad
  /// existe más arriba, en deleteUser(), y borra también la cuenta de acceso.
  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      await fetchUsers();
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      rethrow;
    }
  }
}
