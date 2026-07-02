import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final session = SupabaseConfig.client.auth.currentSession;
    _user = session?.user;
    if (_user != null) await _fetchProfile(_user!.id);
    _loading = false;
    notifyListeners();

    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _fetchProfile(_user!.id);
      } else {
        _profile = null;
      }
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _profile = Map<String, dynamic>.from(data);
    } catch (_) {
      _profile = null;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Errore durante il login. Riprova.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String birthdate,
    required String gender,
  }) async {
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await SupabaseConfig.client.from('profiles').insert({
          'id': response.user!.id,
          'name': name,
          'lastName': lastName,
          'birthdate': birthdate,
          'gender': gender,
        });
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Errore durante la registrazione. Riprova.';
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Errore durante il cambio password.';
    }
  }

  Future<String?> updateProfile(Map<String, dynamic> data) async {
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update(data)
          .eq('id', _user!.id);
      await _fetchProfile(_user!.id);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Errore durante l\'aggiornamento del profilo.';
    }
  }

  Future<String?> uploadAvatar(List<int> fileBytes, String fileName) async {
    try {
      final path = '${_user!.id}/$fileName';
      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(path, Uint8List.fromList(fileBytes),
              fileOptions: const FileOptions(upsert: true));
      final url = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(path);
      await updateProfile({'profileImage': url});
      return null;
    } catch (e) {
      return 'Errore durante il caricamento dell\'immagine.';
    }
  }

  Future<String?> deleteAccount() async {
    try {
      await SupabaseConfig.client.rpc('delete_user_data',
          params: {'user_id': _user!.id});
      await SupabaseConfig.client.auth.signOut();
      return null;
    } catch (e) {
      return 'Errore durante l\'eliminazione dell\'account.';
    }
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _fetchProfile(_user!.id);
      notifyListeners();
    }
  }
}
