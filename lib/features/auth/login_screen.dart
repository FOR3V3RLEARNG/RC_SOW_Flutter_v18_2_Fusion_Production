import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth_support.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.state});
  final AppState state;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String role = 'Site Supervisor';
  String parish = 'Hanover';
  bool busy = false;
  String? error;

  static const roles = [
    'Site Supervisor',
    'Regional Supervisor',
    'Construction Specialist',
    'Community Admin',
    'Technical Admin',
  ];
  static const parishes = [
    'Hanover',
    'Westmoreland',
    'St. James',
    'Trelawny',
    'St. Elizabeth',
    'St. Ann',
    'Clarendon',
    'Manchester',
    'St. Catherine',
    'Kingston',
    'St. Andrew',
    'St. Mary',
    'Portland',
    'St. Thomas',
  ];

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _stageRoleRequest();
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      // onAuthStateChange is the single session-return/callback coordinator.
    } catch (e) {
      if (mounted) setState(() => error = RcAuthSupport.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> google() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _stageRoleRequest();
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: RcAuthSupport.oauthRedirectUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
      if (!launched && mounted) {
        setState(() => error = 'Google sign-in could not be opened.');
      }
    } catch (e) {
      if (mounted) setState(() => error = RcAuthSupport.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _stageRoleRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingRequestedRole', role);
    await prefs.setString('pendingRequestedParish', parish);
  }

  Future<void> requestRole() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _stageRoleRequest();
      if (Supabase.instance.client.auth.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Role and parish saved. Sign in to submit the request for approval.',
              ),
            ),
          );
        }
        return;
      }
      await widget.state.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Role and parish request submitted for Admin approval.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = RcAuthSupport.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RcSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  RcExpressiveSurface(
                    shape: RcSurfaceShape.hero,
                    padding: const EdgeInsets.all(16),
                    tone: theme.colorScheme.primaryContainer.withValues(
                      alpha: .5,
                    ),
                    child: Image.asset(
                      'assets/brand/rc_sow_house_icon.png',
                      width: 88,
                      height: 88,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'RC SOW',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Controlled shelter production',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 28),
                  RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    padding: const EdgeInsets.all(22),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Secure field access',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Approved users keep their assigned access. New users can stage a role and parish request before signing in.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            onSubmitted: (_) => busy ? null : signIn(),
                            autofillHints: const [AutofillHints.password],
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: role,
                            decoration: const InputDecoration(
                              labelText: 'Requested role',
                            ),
                            items: roles
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text(x),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (x) => setState(() => role = x!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: parish,
                            decoration: const InputDecoration(
                              labelText: 'Requested parish',
                            ),
                            items: parishes
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text(x),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (x) => setState(() => parish = x!),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            RcExpressiveSurface(
                              shape: RcSurfaceShape.pill,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              tone: theme.colorScheme.errorContainer,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: busy ? null : signIn,
                            icon: const Icon(Icons.shield_outlined),
                            label: Text(
                              busy ? 'Please wait…' : 'Sign in securely',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: busy ? null : google,
                            icon: const Text(
                              'G',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            label: const Text('Continue with Google'),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: busy ? null : requestRole,
                            child: const Text('Request role / parish approval'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
