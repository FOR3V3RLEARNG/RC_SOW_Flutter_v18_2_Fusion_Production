import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_policy.dart';
import '../../core/supabase_config.dart';
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (busy) {
      return;
    }
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
      await widget.state.synchronizeAuthSession(reason: 'password-sign-in');
    } catch (e) {
      if (mounted) {
        setState(() => error = _friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> google() async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await _stageRoleRequest();
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.oauthRedirectUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes:
            'openid email profile https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send',
        queryParams: const {
          'prompt': 'select_account consent',
          'access_type': 'offline',
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = _friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _stageRoleRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingRequestedRole', role);
    await prefs.setString('pendingRequestedParish', parish);
  }

  Future<void> requestRole() async {
    if (busy) {
      return;
    }
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
                'Role and parish saved. Sign in to submit them for Admin approval.',
              ),
            ),
          );
        }
        return;
      }
      await widget.state.synchronizeAuthSession(reason: 'role-request');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role/parish request submitted for Admin approval.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = _friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  String _friendlyError(Object errorValue) {
    final message = '$errorValue';
    if (message.toLowerCase().contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (message.toLowerCase().contains('network')) {
      return 'Could not reach RC SOW. Check connectivity and try again.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Image.asset(
                    'assets/brand/rc_sow_house_icon.png',
                    width: 94,
                    height: 94,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'RC SOW',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: RcColors.brand,
                    ),
                  ),
                  Text(
                    'Premium Field Operations',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Secure account access',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Approved users keep their assigned access. New or pending users request a role and parish for administrator approval.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: role,
                            decoration:
                                const InputDecoration(labelText: 'Requested role'),
                            items: RcPolicy.roles
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (value) => setState(() => role = value!),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: parish,
                            decoration: const InputDecoration(
                              labelText: 'Requested parish',
                            ),
                            items: RcPolicy.parishes
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (value) => setState(() => parish = value!),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              error!,
                              style: const TextStyle(color: RcColors.danger),
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
                          const SizedBox(height: 10),
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
