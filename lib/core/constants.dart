class AppConstants {
  static const String exchangeRateUrl = 'https://open.er-api.com/v6/latest/ILS';

  static const int initialBalance = 1000;
  static const int dailyBonusAmount = 100;

  static const int coinFlipMultiplier = 2;
  static const int diceSingleMultiplier = 5;
  static const Map<String, int> slotMultipliers = {
    'jackpot': 10,
    'triple': 5,
    'double': 2,
  };

  static const String notificationChannelId = 'shekels_channel';
  static const String notificationChannelName = 'ShekelStore';
  static const int dailyBonusNotificationId = 1;
  static const int winNotificationId = 2;
  static const int lossNotificationId = 3;
  static const int purchaseNotificationId = 4;

  static const String dbName = 'shekelstore.db';
  static const int dbVersion = 1;

  static const String sessionKey = 'current_user_id';
  static const String passwordSalt = 'shekelstore_v1_salt';

  // Gemma 3 1B IT int4 (~600 MB) — compatível com flutter_gemma 0.5.1
  // Token HF necessário se o repo for gated (aceite a licença em huggingface.co)
  static const String rabbiModelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.litertlm';
  static const String huggingFaceToken = ''; // preencha com hf_token se necessário
  static const String rabbiModelInstalledKey = 'rabbi_model_installed';
}
