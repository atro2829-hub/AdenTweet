import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

/// Bottom navigation bar for the main shell with 5 tabs in RTL order.
class BottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  /// Tab definitions in RTL visual order.
  static const _tabs = [
    _NavBarItem(icon: Icons.home, label: 'الرئيسية', route: '/home'),
    _NavBarItem(
        icon: Icons.search, label: 'البحث', route: '/search'),
    _NavBarItem(
        icon: Icons.notifications,
        label: 'الإشعارات',
        route: '/notifications',
        hasBadge: true),
    _NavBarItem(
        icon: Icons.mail_outline, label: 'الرسائل', route: '/messages'),
    _NavBarItem(
        icon: Icons.person_outline,
        label: 'الملف الشخصي',
        route: '/profile/currentUserId'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

    // Build final tabs with resolved profile route
    final tabs = _tabs.map((tab) {
      if (tab.route == '/profile/currentUserId') {
        return _NavBarItem(
          icon: tab.icon,
          label: tab.label,
          route: '/profile/$currentUserId',
        );
      }
      return tab;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 0.5),
          ),
          color: AppTheme.scaffoldBackground,
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;
                final isNotification = tab.hasBadge;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isNotification) {
                        context.go(tab.route);
                      } else {
                        context.go(tab.route);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icon
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? (isNotification
                                      ? Icons.notifications
                                      : tab.icon)
                                  : (isNotification
                                      ? Icons.notifications_outlined
                                      : tab.icon),
                              color: isSelected
                                  ? AppTheme.primaryText
                                  : AppTheme.secondaryText,
                              size: 26,
                            ),
                          ],
                        ),
                        // Unread badge for notifications
                        if (isNotification && unreadCount > 0)
                          Positioned(
                            left: 0,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentBlue,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99
                                      ? '99+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String label;
  final String route;
  final bool hasBadge;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.hasBadge = false,
  });
}