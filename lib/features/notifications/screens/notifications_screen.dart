import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/notification_model.dart';
import '../../../models/profile_model.dart';
import '../providers/notification_provider.dart';

/// Filter type for the notifications tab.
enum NotificationFilter { all, likes, follows }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          elevation: 0,
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryText,
            unselectedLabelColor: AppTheme.secondaryText,
            indicatorColor: AppTheme.accentBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'الإعجابات'),
              Tab(text: 'المتابعات الجديدة'),
            ],
          ),
        ),
        body: notificationsAsync.when(
          data: (state) {
            // Mark as read when viewed
            if (state.unreadCount > 0) {
              Future.microtask(
                  () => ref.read(markNotificationsReadProvider));
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(state.notifications, NotificationFilter.all),
                _buildNotificationList(state.notifications, NotificationFilter.likes),
                _buildNotificationList(state.notifications, NotificationFilter.follows),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentBlue),
          ),
          error: (_, __) => const Center(
            child: Text(
              'حدث خطأ في تحميل الإشعارات',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<NotificationModel> notifications,
    NotificationFilter filter,
  ) {
    final filtered = notifications.where((n) {
      switch (filter) {
        case NotificationFilter.all:
          return true;
        case NotificationFilter.likes:
          return n.type == 'like' || n.type == 'retweet';
        case NotificationFilter.follows:
          return n.type == 'follow';
      }
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إشعارات',
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accentBlue,
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
      },
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(filtered[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final actor = notification.actor;
    final timeAgo =
        DateFormatter.formatRelative(notification.createdAt, locale: 'ar');

    // Determine icon and color based on type
    IconData icon;
    Color iconColor;
    String description;

    switch (notification.type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = AppTheme.likeRed;
        description = 'أعجب @${actor?.username ?? ''} بتغريدتك';
        break;
      case 'retweet':
        icon = Icons.repeat;
        iconColor = AppTheme.retweetGreen;
        description = 'أعاد @${actor?.username ?? ''} نشر تغريدتك';
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = AppTheme.accentBlue;
        description = 'بدأ @${actor?.username ?? ''} بمتابعتك';
        break;
      case 'reply':
        icon = Icons.reply;
        iconColor = AppTheme.primaryText;
        description = 'رد @${actor?.username ?? ''} على تغريدتك';
        break;
      case 'mention':
        icon = Icons.alternate_email;
        iconColor = AppTheme.accentBlue;
        description = 'أشار إليك @${actor?.username ?? ''}';
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.secondaryText;
        description = 'إشعار جديد';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: () {
          // Navigate to relevant location
          if (notification.type == 'follow' && actor != null) {
            context.push('/profile/${actor.id}');
          } else if (notification.tweetId != null) {
            context.push('/tweet/${notification.tweetId}');
          } else if (actor != null) {
            context.push('/profile/${actor.id}');
          }
        },
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon indicator
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.15),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      if (actor != null) {
                        context.push('/profile/${actor.id}');
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.borderColor,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: actor != null && actor.avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: actor.avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _avatarPlaceholder(actor),
                            )
                          : _avatarPlaceholder(actor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              if (actor != null)
                                TextSpan(
                                  text: actor.displayName,
                                  style: const TextStyle(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              TextSpan(
                                text: description,
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(ProfileModel? profile) {
    final letter = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName[0]
        : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}