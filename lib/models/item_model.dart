class ItemModel {
  final int id;
  final String name;
  final String description;
  final String emoji;
  final int price;
  final String category;
  final String rarity;
  final bool isAvailable;

  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.price,
    required this.category,
    required this.rarity,
    required this.isAvailable,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String,
      price: (json['price'] as num).toInt(),
      category: json['category'] as String,
      rarity: json['rarity'] as String? ?? 'comum',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  static const Map<String, String> rarityColors = {
    'comum': '#9E9E9E',
    'incomum': '#4CAF50',
    'raro': '#2196F3',
    'épico': '#9C27B0',
    'lendário': '#F5C518',
  };

  String get rarityColor => rarityColors[rarity] ?? rarityColors['comum']!;
}
