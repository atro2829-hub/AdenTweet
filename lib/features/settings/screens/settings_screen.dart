import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Account
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'الحساب',
                onTap: () {
                  // Navigate to account settings
                },
              ),
              const Divider(color: AppTheme.borderColor, height: 0.5),

              // Privacy
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'الخصوصية',
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
              const Divider(color: AppTheme.borderColor, height: 0.5),

              // Notifications
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                onTap: () {
                  // Navigate to notification settings
                },
              ),
              const Divider(color: AppTheme.borderColor, height: 0.5),

              // About
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'حول التطبيق',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'AdenTweet',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppTheme.accentBlue,
                    ),
                  );
                },
              ),
              const Divider(color: AppTheme.borderColor, height: 0.5),

              const SizedBox(height: 32),

              // Sign Out
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardSurface,
                          title: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(color: AppTheme.primaryText),
                          ),
                          content: const Text(
                            'هل تريد تسجيل الخروج؟',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'خروج',
                                style: TextStyle(color: AppTheme.likeRed),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await ref.read(authStateProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.likeRed,
                      side: const BorderSide(color: AppTheme.likeRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryText, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}