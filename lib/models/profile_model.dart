class ProfileModel {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final String website;
  final String location;
  final DateTime? birthDate;
  final String gender;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final int tweetsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.coverUrl,
    required this.website,
    required this.location,
    this.birthDate,
    required this.gender,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    required this.tweetsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  ProfileModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? website,
    String? location,
    DateTime? birthDate,
    String? gender,
    bool? isVerified,
    int? followersCount,
    int? followingCount,
    int? tweetsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      website: website ?? this.website,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      tweetsCount: tweetsCount ?? this.tweetsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      website: json['website'] as String? ?? '',
      location: json['location'] as String? ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      tweetsCount: (json['tweets_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'website': website,
      'location': location,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'is_verified': isVerified,
      'followers_count': followersCount,
      'following_count': followingCount,
      'tweets_count': tweetsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}