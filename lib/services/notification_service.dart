import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Notificações da ShekelStore',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(id, title, body, details);
  }

  static Future<void> notifyWin(int amount, String game) async {
    await _show(
      id: AppConstants.winNotificationId,
      title: '🏆 Você ganhou!',
      body: 'Parabéns! Você ganhou $amount shekels no $game!',
    );
  }

  static Future<void> notifyLoss(int amount, String game) async {
    await _show(
      id: AppConstants.lossNotificationId,
      title: '💸 Que pena...',
      body: 'Você perdeu $amount shekels no $game. Tente novamente!',
    );
  }

  static Future<void> notifyPurchase(String itemName) async {
    await _show(
      id: AppConstants.purchaseNotificationId,
      title: '🛒 Compra realizada!',
      body: '$itemName foi adicionado ao seu inventário.',
    );
  }

  static Future<void> notifyDailyBonus(int amount) async {
    await _show(
      id: AppConstants.dailyBonusNotificationId,
      title: '🎁 Bônus diário coletado!',
      body: 'Você recebeu $amount shekels de bônus diário!',
    );
  }
}
