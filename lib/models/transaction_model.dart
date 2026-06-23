class TransactionModel {
  final int id;
  final String userId;
  final String type;
  final int amount;
  final String? description;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCredit => amount > 0;

  String get typeLabel {
    switch (type) {
      case 'bet_win':
        return 'Vitória na aposta';
      case 'bet_loss':
        return 'Derrota na aposta';
      case 'purchase':
        return 'Compra na loja';
      case 'bonus':
        return 'Bônus diário';
      case 'registration':
        return 'Bônus de registro';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'bet_win':
        return '🏆';
      case 'bet_loss':
        return '💸';
      case 'purchase':
        return '🛒';
      case 'bonus':
        return '🎁';
      case 'registration':
        return '🎉';
      default:
        return '💰';
    }
  }
}
