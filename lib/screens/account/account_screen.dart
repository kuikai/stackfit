import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/app_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.startOnCreate = false});

  final bool startOnCreate;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _resetting = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.startOnCreate && !_resetting;
    return Scaffold(
      appBar: AppBar(title: Text(_title(creating))),
      body: ListView(
        padding: context.pageGutter(top: 8, bottom: 32),
        children: [
          Text(_intro(creating), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            key: const Key('account-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (creating) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name (optional)',
              ),
            ),
          ],
          if (_resetting) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('reset-code'),
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Reset code'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('account-password'),
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _resetting ? 'New password' : 'Password',
            ),
          ),
          if (creating || _resetting) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('account-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          if (_resetting) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _submitting ? null : _sendResetCode,
                child: Text(_submitting ? 'Please wait…' : 'Send reset code'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('account-submit'),
                onPressed: _submitting ? null : _setNewPassword,
                child: const Text('Set new password'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('account-submit'),
                onPressed: _submitting ? null : () => _submit(creating),
                child: Text(
                  _submitting ? 'Please wait…' : _submitLabel(creating),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _submitting ? null : _toggleReset,
              child: Text(_resetting ? 'Back to sign in' : 'Forgot password?'),
            ),
          ),
        ],
      ),
    );
  }

  String _title(bool creating) {
    if (_resetting) {
      return 'Reset password';
    }
    return creating ? 'Create account' : 'Sign in';
  }

  String _intro(bool creating) {
    if (_resetting) {
      return 'Enter your email and tap the button. If the account exists, '
          'the local server window prints a reset code. Enter that code and a new password.';
    }
    if (creating) {
      return 'Use an email and a password of at least 8 characters. '
          'The app still works if you skip this.';
    }
    return 'Sign in to bring your workouts and history onto this device.';
  }

  String _submitLabel(bool creating) {
    return creating ? 'Create account' : 'Sign in';
  }

  Future<void> _sendResetCode() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(accountApiProvider)
          .requestPasswordReset(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error =
            'If that account exists, read the reset code in the server window.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _setNewPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await _submitReset();
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    await _finishSignedIn();
  }

  void _toggleReset() {
    setState(() {
      _resetting = !_resetting;
      _error = null;
    });
  }

  Future<void> _submit(bool creating) async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = _resetting
        ? await _submitReset()
        : await _submitCredentials(creating);
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    await _finishSignedIn();
  }

  Future<void> _finishSignedIn() async {
    if (ref.read(accountProvider).promptMove) {
      final shouldMove = await _askToMoveDeviceData(context);
      ref.read(accountProvider.notifier).clearMovePrompt();
      if (shouldMove) {
        await ref.read(accountProvider.notifier).moveDeviceData();
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<String?> _submitCredentials(bool creating) async {
    final passwordError = _validatePassword(
      _passwordController.text,
      confirm: creating ? _confirmController.text : null,
    );
    if (passwordError != null) {
      return passwordError;
    }
    final notifier = ref.read(accountProvider.notifier);
    if (creating) {
      return notifier.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    }
    return notifier.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<String?> _submitReset() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      return 'Enter the reset code from the server window.';
    }

    final passwordError = _validatePassword(
      _passwordController.text,
      confirm: _confirmController.text,
    );
    if (passwordError != null) {
      return passwordError;
    }
    try {
      await ref
          .read(accountApiProvider)
          .resetPassword(
            email: _emailController.text.trim(),
            code: code,
            password: _passwordController.text,
          );
      return ref
          .read(accountProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (error) {
      return error.toString();
    }
  }
}

Future<bool> _askToMoveDeviceData(BuildContext context) async {
  final move = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Move workouts to your account?'),
        content: const Text(
          'This device has workouts and history that are not on your account yet. '
          'You can move them now, or later from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Move'),
          ),
        ],
      );
    },
  );
  return move == true;
}

String? _validateEmail(String value) {
  final email = value.trim();
  final at = email.indexOf('@');
  if (at <= 0 || !email.substring(at + 1).contains('.')) {
    return 'Enter a valid email.';
  }
  return null;
}

String? _validatePassword(String password, {String? confirm}) {
  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (confirm != null && password != confirm) {
    return 'Passwords do not match.';
  }
  return null;
}
