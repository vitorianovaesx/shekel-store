import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import 'local_db_service.dart';

class AuthService {
  static const _uuid = Uuid();

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.sessionKey);
  }

  static Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.sessionKey, userId);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sessionKey);
  }

  static String _hash(String password) {
    final bytes = utf8.encode(password + AppConstants.passwordSalt);
    return sha256.convert(bytes).toString();
  }

  static Future<String> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final lowerEmail = email.trim().toLowerCase();
    final lowerUsername = username.trim().toLowerCase();

    if (await LocalDbService.emailExists(lowerEmail)) {
      throw Exception('Este email já está cadastrado');
    }
    if (await LocalDbService.usernameExists(lowerUsername)) {
      throw Exception('Este nome de usuário já está em uso');
    }

    final userId = _uuid.v4();
    await LocalDbService.createUser(
      id: userId,
      username: lowerUsername,
      displayName: displayName.trim(),
      email: lowerEmail,
      passwordHash: _hash(password),
    );

    await _saveSession(userId);
    return userId;
  }

  static Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final userId = await LocalDbService.validateCredentials(
      email.trim().toLowerCase(),
      _hash(password),
    );

    if (userId == null) throw Exception('Email ou senha incorretos');

    await _saveSession(userId);
    return userId;
  }
}
