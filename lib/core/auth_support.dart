import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

abstract final class RcAuthSupport {
  static const oauthRedirectUri = SupabaseConfig.oauthRedirectUri;

  static String friendlyMessage(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login') ||
          message.contains('invalid credentials')) {
        return 'Email or password is incorrect.';
      }
      if (message.contains('email not confirmed')) {
        return 'Confirm your email before signing in.';
      }
      if (message.contains('rate') || message.contains('too many')) {
        return 'Too many sign-in attempts. Try again shortly.';
      }
      if (message.contains('network') || message.contains('socket')) {
        return 'Could not reach the secure sign-in service. Check your connection.';
      }
      return 'Secure sign-in could not be completed. Please try again.';
    }
    return 'Something interrupted sign-in. Please try again.';
  }
}
