class CachedShop {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? syncedAt;
  final bool isDirty;

  CachedShop({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.isActive = true,
    this.createdAt,
    this.syncedAt,
    this.isDirty = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  factory CachedShop.fromMap(Map<String, dynamic> map) {
    return CachedShop(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      isDirty: (map['is_dirty'] as int?) == 1,
    );
  }

  CachedShop copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    DateTime? syncedAt,
    bool? isDirty,
  }) {
    return CachedShop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
