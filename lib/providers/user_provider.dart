import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  int get balance => _user?.shekelBalance ?? 0;

  Future<void> loadProfile() async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await LocalDbService.fetchProfile(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> claimDailyBonus() async {
    if (_user == null) return;

    final claimed = await LocalDbService.claimDailyBonus(
      _user!.id,
      AppConstants.dailyBonusAmount,
    );

    if (claimed) {
      _user = _user!.copyWith(
        shekelBalance: _user!.shekelBalance + AppConstants.dailyBonusAmount,
      );
      await NotificationService.notifyDailyBonus(AppConstants.dailyBonusAmount);
      notifyListeners();
    }
  }

  Future<bool> deductBalance(int amount) async {
    if (_user == null || _user!.shekelBalance < amount) return false;
    _user = _user!.copyWith(shekelBalance: _user!.shekelBalance - amount);
    notifyListeners();
    return true;
  }

  void addToBalance(int amount) {
    if (_user == null) return;
    _user = _user!.copyWith(shekelBalance: _user!.shekelBalance + amount);
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    await LocalDbService.updateDisplayName(_user!.id, name);
    _user = _user!.copyWith(displayName: name);
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String localPath) async {
    if (_user == null) return;
    await LocalDbService.updateAvatarPath(_user!.id, localPath);
    _user = _user!.copyWith(avatarUrl: localPath);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshBalance() async {
    if (_user == null) return;
    final refreshed = await LocalDbService.fetchProfile(_user!.id);
    if (refreshed != null) {
      _user = refreshed;
      notifyListeners();
    }
  }

  Future<void> syncStats() async {
    if (_user == null) return;
    final fresh = await LocalDbService.fetchProfile(_user!.id);
    if (fresh != null) {
      _user = fresh;
      notifyListeners();
    }
  }
}
