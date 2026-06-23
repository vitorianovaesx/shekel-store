class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int shekelBalance;
  final int totalWon;
  final int totalLost;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.shekelBalance,
    required this.totalWon,
    required this.totalLost,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      shekelBalance: (json['shekel_balance'] as num).toInt(),
      totalWon: (json['total_won'] as num?)?.toInt() ?? 0,
      totalLost: (json['total_lost'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    int? shekelBalance,
    int? totalWon,
    int? totalLost,
  }) {
    return UserModel(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      shekelBalance: shekelBalance ?? this.shekelBalance,
      totalWon: totalWon ?? this.totalWon,
      totalLost: totalLost ?? this.totalLost,
      createdAt: createdAt,
    );
  }

  int get netProfit => totalWon - totalLost;
  double get winRate => (totalWon + totalLost) == 0 ? 0 : totalWon / (totalWon + totalLost) * 100;
}
