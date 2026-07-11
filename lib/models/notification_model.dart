import 'profile_model.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final String type;
  final String? tweetId;
  final bool isRead;
  final DateTime createdAt;
  final ProfileModel? actor;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.tweetId,
    required this.isRead,
    required this.createdAt,
    this.actor,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? type,
    String? tweetId,
    bool? isRead,
    DateTime? createdAt,
    ProfileModel? actor,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      tweetId: tweetId ?? this.tweetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actor: actor ?? this.actor,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String? ?? '',
      tweetId: json['tweet_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actor: json['actor'] != null
          ? ProfileModel.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a NotificationModel from a raw database row without joins.
  factory NotificationModel.fromRow(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String? ?? '',
      tweetId: json['tweet_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'tweet_id': tweetId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}