import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/supabase_client.dart';
import '../../../models/profile_model.dart';
import '../../../models/tweet_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Fetches a single user profile by [userId].
final userProfileProvider =
    FutureProvider.family<ProfileModel, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  } catch (e) {
    throw Exception('فشل تحميل الملف الشخصي');
  }
});

/// Fetches tweets authored by [userId].
final userTweetsProvider =
    FutureProvider.family<List<TweetModel>, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('tweets')
        .select('*, author:profiles!tweets_user_id_fkey(*)')
        .eq('user_id', userId)
        .eq('tweet_type', 'tweet')
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List)
        .map((e) => TweetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Fetches reply tweets authored by [userId].
final userRepliesProvider =
    FutureProvider.family<List<TweetModel>, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('tweets')
        .select('*, author:profiles!tweets_user_id_fkey(*)')
        .eq('user_id', userId)
        .eq('tweet_type', 'reply')
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List)
        .map((e) => TweetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Fetches liked tweets for [userId].
final userLikesProvider =
    FutureProvider.family<List<TweetModel>, String>((ref, userId) async {
  try {
    // First get liked tweet IDs
    final likesResponse = await supabase
        .from('likes')
        .select('tweet_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    final tweetIds =
        (likesResponse as List).map((e) => e['tweet_id'] as String).toList();

    if (tweetIds.isEmpty) return [];

    // Then fetch those tweets
    final tweetsResponse = await supabase
        .from('tweets')
        .select('*, author:profiles!tweets_user_id_fkey(*)')
        .inFilter('id', tweetIds)
        .order('created_at', ascending: false);

    return (tweetsResponse as List)
        .map((e) => TweetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Fetches followers (profiles that follow [userId]).
final userFollowersProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('follows')
        .select('follower:profiles!follows_follower_id_fkey(*)')
        .eq('following_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List)
        .map((e) =>
            ProfileModel.fromJson(e['follower'] as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Fetches following (profiles that [userId] follows).
final userFollowingProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  try {
    final response = await supabase
        .from('follows')
        .select('following:profiles!follows_following_id_fkey(*)')
        .eq('follower_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List)
        .map((e) =>
            ProfileModel.fromJson(e['following'] as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Checks if the current user follows [targetId].
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetId) async {
  final myId = ref.read(currentUserProvider)?.id;
  if (myId == null || myId == targetId) return false;
  try {
    final response = await supabase
        .from('follows')
        .select()
        .eq('follower_id', myId)
        .eq('following_id', targetId);
    return (response as List).isNotEmpty;
  } catch (e) {
    return false;
  }
});

/// Provider that exposes a toggle-follow function.
final toggleFollowProvider = Provider<Future<void> Function(String targetId)>(
  (ref) {
    return (String targetId) async {
      final myId = ref.read(currentUserProvider)?.id;
      if (myId == null) return;

      try {
        // Check if follow already exists
        final existing = await supabase
            .from('follows')
            .select()
            .eq('follower_id', myId)
            .eq('following_id', targetId);

        if ((existing as List).isNotEmpty) {
          // Unfollow
          await supabase
              .from('follows')
              .delete()
              .eq('follower_id', myId)
              .eq('following_id', targetId);

          // Decrement followers count on target
          final target = await supabase
              .from('profiles')
              .select('followers_count')
              .eq('id', targetId)
              .single();
          final fc = (target['followers_count'] as num?)?.toInt() ?? 0;
          await supabase
              .from('profiles')
              .update({'followers_count': fc > 0 ? fc - 1 : 0})
              .eq('id', targetId);
          // Decrement following count on self
          final self = await supabase
              .from('profiles')
              .select('following_count')
              .eq('id', myId)
              .single();
          final fg = (self['following_count'] as num?)?.toInt() ?? 0;
          await supabase
              .from('profiles')
              .update({'following_count': fg > 0 ? fg - 1 : 0})
              .eq('id', myId);
        } else {
          // Follow
          await supabase.from('follows').insert({
            'follower_id': myId,
            'following_id': targetId,
          });

          // Increment followers count on target
          final target = await supabase
              .from('profiles')
              .select('followers_count')
              .eq('id', targetId)
              .single();
          final fc = (target['followers_count'] as num?)?.toInt() ?? 0;
          await supabase
              .from('profiles')
              .update({'followers_count': fc + 1})
              .eq('id', targetId);
          // Increment following count on self
          final self = await supabase
              .from('profiles')
              .select('following_count')
              .eq('id', myId)
              .single();
          final fg = (self['following_count'] as num?)?.toInt() ?? 0;
          await supabase
              .from('profiles')
              .update({'following_count': fg + 1})
              .eq('id', myId);
        }
      } catch (e) {
        rethrow;
      }
    };
  },
);