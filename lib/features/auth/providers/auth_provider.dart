import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_client.dart';
import '../../../models/profile_model.dart';

/// Auth state representing the current authentication status.
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
}

/// Holds the current app authentication state and optional profile.
/// Named AppAuthState to avoid conflict with Supabase's AuthState.
class AppAuthState {
  final AuthStatus status;
  final User? user;
  final ProfileModel? profile;
  final String? errorMessage;

  const AppAuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.profile,
    this.errorMessage,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    User? user,
    ProfileModel? profile,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// StateNotifier that manages authentication state.
class AuthNotifier extends StateNotifier<AppAuthState> {
  StreamSubscription? _authSubscription;

  AuthNotifier() : super(const AppAuthState()) {
    _initAuth();
  }

  void _initAuth() {
    // Check current user immediately
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      _loadProfile(currentUser.id);
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearProfile: true,
      );
    }

    // Listen to real-time auth state changes
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (event) {
        final user = event.session?.user;
        if (user != null && state.status != AuthStatus.loading) {
          _loadProfile(user.id);
        } else if (user == null) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            clearProfile: true,
            clearError: true,
          );
        }
      },
    );
  }

  Future<void> _loadProfile(String userId) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final profile = ProfileModel.fromJson(response);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: supabase.auth.currentUser,
        profile: profile,
        clearError: true,
      );
    } catch (e) {
      // Profile might not exist yet — user is still authenticated
      final user = supabase.auth.currentUser;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'فشل تحميل الملف الشخصي',
          clearProfile: true,
        );
      }
    }
  }

  /// Sign in with email and password.
  Future<void> signIn(String email, String password) async {
    try {
      state = state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      );

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response.user.id;
      if (userId.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'فشل تسجيل الدخول',
        );
        return;
      }
      await _loadProfile(userId);
    } on AuthException catch (e) {
      String message;
      if (e.message.contains('Invalid login')) {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'يرجى تأكيد البريد الإلكتروني أولاً';
      } else {
        message = 'فشل تسجيل الدخول: ${e.message}';
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'حدث خطأ غير متوقع أثناء تسجيل الدخول',
      );
    }
  }

  /// Sign up with email, password, username, and display name.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      state = state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      );

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': displayName,
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'فشل إنشاء الحساب',
        );
        return;
      }

      // Wait briefly for the DB trigger to create the profile
      await Future.delayed(const Duration(seconds: 2));

      // Verify profile exists; create manually if trigger failed
      try {
        final profileResponse = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        final profile = ProfileModel.fromJson(profileResponse);

        // Ensure username and displayName are synced
        if (profile.username != username || profile.displayName != displayName) {
          await supabase.from('profiles').update({
            'username': username,
            'display_name': displayName,
          }).eq('id', userId);

          final updatedResponse = await supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
            profile: ProfileModel.fromJson(updatedResponse),
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
            profile: profile,
          );
        }
      } on PostgrestException {
        // Profile doesn't exist — create it manually
        await supabase.from('profiles').insert({
          'id': userId,
          'username': username,
          'display_name': displayName,
          'bio': '',
          'avatar_url': '',
          'cover_url': '',
          'website': '',
          'location': '',
          'gender': '',
          'is_verified': false,
          'followers_count': 0,
          'following_count': 0,
          'tweets_count': 0,
        });

        final profileResponse = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          profile: ProfileModel.fromJson(profileResponse),
        );
      }
    } on AuthException catch (e) {
      String message;
      if (e.message.contains('already registered')) {
        message = 'البريد الإلكتروني مسجل مسبقاً';
      } else if (e.message.contains('Password')) {
        message = 'كلمة المرور ضعيفة، يجب أن تكون ٦ أحرف على الأقل';
      } else {
        message = 'فشل إنشاء الحساب: ${e.message}';
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'حدث خطأ غير متوقع أثناء إنشاء الحساب',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      state = const AppAuthState(
        status: AuthStatus.unauthenticated,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'فشل تسجيل الخروج',
      );
    }
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Convenience getter for current user.
  User? get currentUser => state.user;

  /// Convenience getter for current profile.
  ProfileModel? get currentProfile => state.profile;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for the auth state notifier.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider that exposes only the current [ProfileModel].
final currentProfileProvider = Provider<ProfileModel?>((ref) {
  return ref.watch(authStateProvider).profile;
});

/// Convenience provider that exposes only the current [User].
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// Provider that emits `true` when the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).status == AuthStatus.authenticated;
});