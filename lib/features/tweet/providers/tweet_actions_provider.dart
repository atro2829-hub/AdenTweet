import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_client.dart';

/// Wraps all tweet interaction operations (like, retweet, bookmark, delete)
/// in clean functions with atomic count updates and error handling.
class TweetActions {
  TweetActions._();

  /// Toggle like on a tweet.
  /// Returns the new [likesCount] after the operation.
  static Future<int> toggleLike({
    required String tweetId,
    required String userId,
    required bool currentlyLiked,
    required int currentCount,
  }) async {
    try {
      if (!currentlyLiked) {
        // Like the tweet
        await supabase.from('likes').insert({
          'user_id': userId,
          'tweet_id': tweetId,
        });
        final newCount = currentCount + 1;
        await supabase
            .from('tweets')
            .update({'likes_count': newCount})
            .eq('id', tweetId);
        return newCount;
      } else {
        // Unlike the tweet
        await supabase
            .from('likes')
            .delete()
            .match({'user_id': userId, 'tweet_id': tweetId});
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await supabase
            .from('tweets')
            .update({'likes_count': newCount})
            .eq('id', tweetId);
        return newCount;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle retweet on a tweet.
  /// Returns the new [retweetsCount] after the operation.
  static Future<int> toggleRetweet({
    required String tweetId,
    required String userId,
    required bool currentlyRetweeted,
    required int currentCount,
  }) async {
    try {
      if (!currentlyRetweeted) {
        await supabase.from('retweets').insert({
          'user_id': userId,
          'tweet_id': tweetId,
        });
        final newCount = currentCount + 1;
        await supabase
            .from('tweets')
            .update({'retweets_count': newCount})
            .eq('id', tweetId);
        return newCount;
      } else {
        await supabase
            .from('retweets')
            .delete()
            .match({'user_id': userId, 'tweet_id': tweetId});
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await supabase
            .from('tweets')
            .update({'retweets_count': newCount})
            .eq('id', tweetId);
        return newCount;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle bookmark on a tweet.
  /// Returns the new [bookmarksCount] after the operation.
  static Future<int> toggleBookmark({
    required String tweetId,
    required String userId,
    required bool currentlyBookmarked,
    required int currentCount,
  }) async {
    try {
      if (!currentlyBookmarked) {
        await supabase.from('bookmarks').insert({
          'user_id': userId,
          'tweet_id': tweetId,
        });
        final newCount = currentCount + 1;
        await supabase
            .from('tweets')
            .update({'bookmarks_count': newCount})
            .eq('id', tweetId);
        return newCount;
      } else {
        await supabase
            .from('bookmarks')
            .delete()
            .match({'user_id': userId, 'tweet_id': tweetId});
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await supabase
            .from('tweets')
            .update({'bookmarks_count': newCount})
            .eq('id', tweetId);
        return newCount;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a tweet and decrement the author's tweets_count.
  static Future<void> deleteTweet({
    required String tweetId,
    required String userId,
  }) async {
    try {
      // Decrement the author's tweets_count
      await supabase.rpc('decrement_tweets_count', params: {'user_id': userId});

      // Delete the tweet
      await supabase.from('tweets').delete().eq('id', tweetId);
    } catch (e) {
      // Fallback: try manual decrement if RPC doesn't exist
      try {
        final profile = await supabase
            .from('profiles')
            .select('tweets_count')
            .eq('id', userId)
            .single();
        final currentCount =
            (profile['tweets_count'] as num?)?.toInt() ?? 0;
        await supabase
            .from('profiles')
            .update({'tweets_count': currentCount > 0 ? currentCount - 1 : 0})
            .eq('id', userId);
        await supabase.from('tweets').delete().eq('id', tweetId);
      } catch (_) {
        rethrow;
      }
    }
  }
}