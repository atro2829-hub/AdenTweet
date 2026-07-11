import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/supabase_client.dart';
import '../../../models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Holds the notifications state including the list and unread count.
class NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Fetches notifications for the current user with unread count.
final notificationsProvider =
    FutureProvider<NotificationsState>((ref) async {
  final myId = ref.read(currentUserProvider)?.id;
  if (myId == null) return const NotificationsState();

  try {
    final response = await supabase
        .from('notifications')
        .select('*, actor:profiles!notifications_actor_id_fkey(*)')
        .eq('user_id', myId)
        .order('created_at', ascending: false)
        .limit(30);

    final notifications = (response as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final unreadCount =
        notifications.where((n) => !n.isRead).length;

    return NotificationsState(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  } catch (e) {
    return const NotificationsState();
  }
});

/// Unread notification count only (lightweight).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.when(
    data: (data) => data.unreadCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Marks all notifications as read for the current user.
final markNotificationsReadProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final myId = ref.read(currentUserProvider)?.id;
  if (myId == null) return;

  try {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', myId)
        .eq('is_read', false);
  } catch (e) {
    // Silently fail
  }
});