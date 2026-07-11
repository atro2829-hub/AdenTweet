import 'profile_model.dart';

class TweetModel {
  final String id;
  final String userId;
  final String content;
  final List<String> mediaUrls;
  final String tweetType;
  final String? replyToId;
  final String? quoteOfId;
  final String? retweetOfId;
  final List<String> mentions;
  final List<String> hashtags;
  final int viewsCount;
  final int likesCount;
  final int retweetsCount;
  final int repliesCount;
  final int bookmarksCount;
  final bool isPinned;
  final DateTime createdAt;
  // Extra fields from joins (not stored directly in the tweets table)
  final bool isLiked;
  final bool isRetweeted;
  final bool isBookmarked;
  final ProfileModel? author;

  const TweetModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.mediaUrls,
    required this.tweetType,
    this.replyToId,
    this.quoteOfId,
    this.retweetOfId,
    required this.mentions,
    required this.hashtags,
    required this.viewsCount,
    required this.likesCount,
    required this.retweetsCount,
    required this.repliesCount,
    required this.bookmarksCount,
    required this.isPinned,
    required this.createdAt,
    this.isLiked = false,
    this.isRetweeted = false,
    this.isBookmarked = false,
    this.author,
  });

  TweetModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? mediaUrls,
    String? tweetType,
    String? replyToId,
    String? quoteOfId,
    String? retweetOfId,
    List<String>? mentions,
    List<String>? hashtags,
    int? viewsCount,
    int? likesCount,
    int? retweetsCount,
    int? repliesCount,
    int? bookmarksCount,
    bool? isPinned,
    DateTime? createdAt,
    bool? isLiked,
    bool? isRetweeted,
    bool? isBookmarked,
    ProfileModel? author,
  }) {
    return TweetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tweetType: tweetType ?? this.tweetType,
      replyToId: replyToId ?? this.replyToId,
      quoteOfId: quoteOfId ?? this.quoteOfId,
      retweetOfId: retweetOfId ?? this.retweetOfId,
      mentions: mentions ?? this.mentions,
      hashtags: hashtags ?? this.hashtags,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      retweetsCount: retweetsCount ?? this.retweetsCount,
      repliesCount: repliesCount ?? this.repliesCount,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isRetweeted: isRetweeted ?? this.isRetweeted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      author: author ?? this.author,
    );
  }

  factory TweetModel.fromJson(Map<String, dynamic> json) {
    return TweetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tweetType: json['tweet_type'] as String? ?? 'tweet',
      replyToId: json['reply_to_id'] as String?,
      quoteOfId: json['quote_of_id'] as String?,
      retweetOfId: json['retweet_of_id'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      retweetsCount: (json['retweets_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarks_count'] as num?)?.toInt() ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool? ?? false,
      isRetweeted: json['is_retweeted'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      author: json['author'] != null
          ? ProfileModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a TweetModel from JSON, excluding extra join fields.
  /// Useful when parsing raw database rows without joins.
  factory TweetModel.fromRow(Map<String, dynamic> json) {
    return TweetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tweetType: json['tweet_type'] as String? ?? 'tweet',
      replyToId: json['reply_to_id'] as String?,
      quoteOfId: json['quote_of_id'] as String?,
      retweetOfId: json['retweet_of_id'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      retweetsCount: (json['retweets_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarks_count'] as num?)?.toInt() ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'tweet_type': tweetType,
      'reply_to_id': replyToId,
      'quote_of_id': quoteOfId,
      'retweet_of_id': retweetOfId,
      'mentions': mentions,
      'hashtags': hashtags,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'retweets_count': retweetsCount,
      'replies_count': repliesCount,
      'bookmarks_count': bookmarksCount,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}