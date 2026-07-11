import 'profile_model.dart';

class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String storyType;
  final DateTime expiresAt;
  final DateTime createdAt;
  final ProfileModel? author;
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.storyType,
    required this.expiresAt,
    required this.createdAt,
    this.author,
    this.isViewed = false,
  });

  StoryModel copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    String? storyType,
    DateTime? expiresAt,
    DateTime? createdAt,
    ProfileModel? author,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      storyType: storyType ?? this.storyType,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String? ?? '',
      storyType: json['story_type'] as String? ?? 'image',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? ProfileModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }

  /// Creates a StoryModel from a raw database row without joins.
  factory StoryModel.fromRow(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String? ?? '',
      storyType: json['story_type'] as String? ?? 'image',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'story_type': storyType,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}