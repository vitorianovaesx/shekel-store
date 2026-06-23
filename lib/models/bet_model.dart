class BetModel {
  final int id;
  final String userId;
  final String gameType;
  final int amount;
  final String outcome;
  final int payout;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const BetModel({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.amount,
    required this.outcome,
    required this.payout,
    this.details,
    required this.createdAt,
  });

  factory BetModel.fromJson(Map<String, dynamic> json) {
    return BetModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      gameType: json['game_type'] as String,
      amount: (json['amount'] as num).toInt(),
      outcome: json['outcome'] as String,
      payout: (json['payout'] as num).toInt(),
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isWin => outcome == 'win';
  int get profit => payout - amount;

  String get gameLabel {
    switch (gameType) {
      case 'coin_flip':
        return 'Cara ou Coroa';
      case 'dice':
        return 'Dado';
      case 'slots':
        return 'Caça-Níquel';
      default:
        return gameType;
    }
  }

  String get gameEmoji {
    switch (gameType) {
      case 'coin_flip':
        return '🪙';
      case 'dice':
        return '🎲';
      case 'slots':
        return '🎰';
      default:
        return '🎮';
    }
  }
}
