class CachedUser {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? syncedAt;
  final bool isDirty;

  CachedUser({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.isActive = true,
    this.isAdmin = false,
    this.createdAt,
    this.lastLoginAt,
    this.syncedAt,
    this.isDirty = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'is_active': isActive ? 1 : 0,
      'is_admin': isAdmin ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  factory CachedUser.fromMap(Map<String, dynamic> map) {
    return CachedUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      isActive: (map['is_active'] as int) == 1,
      isAdmin: (map['is_admin'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      isDirty: (map['is_dirty'] as int?) == 1,
    );
  }

  CachedUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isActive,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? syncedAt,
    bool? isDirty,
  }) {
    return CachedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
