import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/supabase_client.dart';
import '../../../models/tweet_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tweet/providers/tweet_actions_provider.dart';

/// Provider that fetches the home feed of tweets.
///
/// Fetches the latest 20 tweets with author data, then enriches each tweet
/// with the current user's like / retweet / bookmark status.
final tweetFeedProvider = FutureProvider<List<TweetModel>>((ref) async {
  final profile = ref.read(currentProfileProvider);
  if (profile == null) return [];

  final userId = profile.id;

  // Fetch tweets with author profile
  final response = await supabase.from('tweets').select('''
    *,
    author:profiles!tweets_user_id_fkey(*)
  ''').order('created_at', ascending: false).limit(20);

  // Fetch current user's interaction status in parallel
  final results = await Future.wait([
    supabase.from('likes').select('tweet_id').eq('user_id', userId),
    supabase.from('retweets').select('tweet_id').eq('user_id', userId),
    supabase.from('bookmarks').select('tweet_id').eq('user_id', userId),
  ]);

  final likedIds =
      (results[0] as List).map((e) => e['tweet_id'] as String).toSet();
  final retweetedIds =
      (results[1] as List).map((e) => e['tweet_id'] as String).toSet();
  final bookmarkedIds =
      (results[2] as List).map((e) => e['tweet_id'] as String).toSet();

  // Map rows to TweetModel with interaction flags
  final tweets = (response as List).map((row) {
    final tweet = TweetModel.fromJson(row as Map<String, dynamic>);
    return tweet.copyWith(
      isLiked: likedIds.contains(tweet.id),
      isRetweeted: retweetedIds.contains(tweet.id),
      isBookmarked: bookmarkedIds.contains(tweet.id),
    );
  }).toList();

  return tweets;
});

/// Provider that creates a new tweet.
///
/// Expects a map with keys:
/// - content (String) - the tweet text
/// - mediaUrls (List) - attached media URLs
/// - mentions (List) - mentioned usernames
/// - hashtags (List) - extracted hashtags
///
/// Returns the newly created tweets ID.
final createTweetProvider =
    FutureProvider.family<String, Map<String, dynamic>>((ref, data) async {
  final profile = ref.read(currentProfileProvider);
  if (profile == null) throw Exception('غير مسجل الدخول');

  final content = data['content'] as String? ?? '';
  final mediaUrls = data['mediaUrls'] as List<String>? ?? [];
  final mentions = data['mentions'] as List<String>? ?? [];
  final hashtags = data['hashtags'] as List<String>? ?? [];
  final replyToId = data['replyToId'] as String?;

  // Build insert payload
  final payload = <String, dynamic>{
    'user_id': profile.id,
    'content': content,
    'media_urls': mediaUrls,
    'tweet_type': replyToId != null ? 'reply' : 'tweet',
    'mentions': mentions,
    'hashtags': hashtags,
  };
  if (replyToId != null) {
    payload['reply_to_id'] = replyToId;
  }

  // Insert the tweet
  final response = await supabase.from('tweets').insert(payload).select('id').single();

  final newTweetId = response['id'] as String;

  // Increment the author's tweets_count
  await supabase
      .from('profiles')
      .update({'tweets_count': profile.tweetsCount + 1})
      .eq('id', profile.id);

  // If this is a reply, increment the parent tweet's replies_count
  if (replyToId != null) {
    await supabase.rpc('increment_replies_count', params: {'tweet_id': replyToId});
  }

  return newTweetId;
});

/// Provider that toggles a like on a tweet.
/// Expects `{'tweetId': String, 'currentCount': int, 'isLiked': bool}`.
final likeTweetProvider =
    FutureProvider.family<int, Map<String, dynamic>>((ref, data) async {
  final profile = ref.read(currentProfileProvider);
  if (profile == null) throw Exception('غير مسجل الدخول');

  return TweetActions.toggleLike(
    tweetId: data['tweetId'] as String,
    userId: profile.id,
    currentlyLiked: data['isLiked'] as bool,
    currentCount: (data['currentCount'] as num).toInt(),
  );
});

/// Provider that toggles a retweet on a tweet.
/// Expects `{'tweetId': String, 'currentCount': int, 'isRetweeted': bool}`.
final retweetProvider =
    FutureProvider.family<int, Map<String, dynamic>>((ref, data) async {
  final profile = ref.read(currentProfileProvider);
  if (profile == null) throw Exception('غير مسجل الدخول');

  return TweetActions.toggleRetweet(
    tweetId: data['tweetId'] as String,
    userId: profile.id,
    currentlyRetweeted: data['isRetweeted'] as bool,
    currentCount: (data['currentCount'] as num).toInt(),
  );
});

/// Provider that toggles a bookmark on a tweet.
/// Expects `{'tweetId': String, 'currentCount': int, 'isBookmarked': bool}`.
final bookmarkProvider =
    FutureProvider.family<int, Map<String, dynamic>>((ref, data) async {
  final profile = ref.read(currentProfileProvider);
  if (profile == null) throw Exception('غير مسجل الدخول');

  return TweetActions.toggleBookmark(
    tweetId: data['tweetId'] as String,
    userId: profile.id,
    currentlyBookmarked: data['isBookmarked'] as bool,
    currentCount: (data['currentCount'] as num).toInt(),
  );
});

/// Provider that deletes a tweet and decrements the author's count.
/// Expects `{'tweetId': String, 'userId': String}`.
final deleteTweetProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  await TweetActions.deleteTweet(
    tweetId: data['tweetId'] as String,
    userId: data['userId'] as String,
  );
});

/// Provider that fetches replies for a given tweet.
final tweetRepliesProvider =
    FutureProvider.family<List<TweetModel>, String>((ref, tweetId) async {
  final profile = ref.read(currentProfileProvider);
  final userId = profile?.id;

  final response = await supabase.from('tweets').select('''
    *,
    author:profiles!tweets_user_id_fkey(*)
  ''').eq('reply_to_id', tweetId).order('created_at', ascending: true);

  if (userId == null || userId.isEmpty) {
    return (response as List)
        .map((row) => TweetModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // Fetch interaction status for replies
  final results = await Future.wait([
    supabase.from('likes').select('tweet_id').eq('user_id', userId),
    supabase.from('retweets').select('tweet_id').eq('user_id', userId),
    supabase.from('bookmarks').select('tweet_id').eq('user_id', userId),
  ]);

  final likedIds =
      (results[0] as List).map((e) => e['tweet_id'] as String).toSet();
  final retweetedIds =
      (results[1] as List).map((e) => e['tweet_id'] as String).toSet();
  final bookmarkedIds =
      (results[2] as List).map((e) => e['tweet_id'] as String).toSet();

  return (response as List).map((row) {
    final tweet = TweetModel.fromJson(row as Map<String, dynamic>);
    return tweet.copyWith(
      isLiked: likedIds.contains(tweet.id),
      isRetweeted: retweetedIds.contains(tweet.id),
      isBookmarked: bookmarkedIds.contains(tweet.id),
    );
  }).toList();
});

/// Provider that fetches a single tweet by ID with its author.
final singleTweetProvider =
    FutureProvider.family<TweetModel, String>((ref, tweetId) async {
  final profile = ref.read(currentProfileProvider);
  final userId = profile?.id;

  final response = await supabase.from('tweets').select('''
    *,
    author:profiles!tweets_user_id_fkey(*)
  ''').eq('id', tweetId).single();

  final tweet = TweetModel.fromJson(response);

  if (userId != null && userId.isNotEmpty) {
    final results = await Future.wait([
      supabase.from('likes').select('tweet_id').eq('user_id', userId).eq('tweet_id', tweetId),
      supabase.from('retweets').select('tweet_id').eq('user_id', userId).eq('tweet_id', tweetId),
      supabase.from('bookmarks').select('tweet_id').eq('user_id', userId).eq('tweet_id', tweetId),
    ]);

    return tweet.copyWith(
      isLiked: (results[0] as List).isNotEmpty,
      isRetweeted: (results[1] as List).isNotEmpty,
      isBookmarked: (results[2] as List).isNotEmpty,
    );
  }

  return tweet;
});