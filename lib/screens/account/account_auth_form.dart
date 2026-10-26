import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Email, password, and reset-code fields for sign in, sign up, and reset.
class AccountAuthForm extends StatelessWidget {
  const AccountAuthForm({
    super.key,
    required this.creating,
    required this.resetting,
    required this.submitting,
    required this.intro,
    required this.submitLabel,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.nameController,
    required this.codeController,
    required this.error,
    required this.onSendResetCode,
    required this.onSetNewPassword,
    required this.onSubmit,
    required this.onToggleReset,
  });

  final bool creating;
  final bool resetting;
  final bool submitting;
  final String intro;
  final String submitLabel;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final String? error;
  final VoidCallback onSendResetCode;
  final VoidCallback onSetNewPassword;
  final VoidCallback onSubmit;
  final VoidCallback onToggleReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: context.pageGutter(top: 8, bottom: 32),
      children: [
        Text(intro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        _emailField(),
        if (creating) _nameField(),
        if (resetting) _codeField(),
        _passwordField(),
        if (creating || resetting) _confirmField(),
        if (error != null) _errorText(context),
        const SizedBox(height: 20),
        ..._actions(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: submitting ? null : onToggleReset,
            child: Text(resetting ? 'Back to sign in' : 'Forgot password?'),
          ),
        ),
      ],
    );
  }

  Widget _emailField() {
    return TextField(
      key: const Key('account-email'),
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(labelText: 'Email'),
    );
  }

  Widget _nameField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Display name (optional)'),
      ),
    );
  }

  Widget _codeField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        key: const Key('reset-code'),
        controller: codeController,
        decoration: const InputDecoration(labelText: 'Reset code'),
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        key: const Key('account-password'),
        controller: passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: resetting ? 'New password' : 'Password',
        ),
      ),
    );
  }

  Widget _confirmField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: confirmController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirm password'),
      ),
    );
  }

  Widget _errorText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        error!,
        key: const Key('account-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  List<Widget> _actions() {
    if (resetting) {
      return [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: submitting ? null : onSendResetCode,
            child: Text(submitting ? 'Please wait…' : 'Send reset code'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('account-submit'),
            onPressed: submitting ? null : onSetNewPassword,
            child: const Text('Set new password'),
          ),
        ),
      ];
    }
    return [
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('account-submit'),
          onPressed: submitting ? null : onSubmit,
          child: Text(submitting ? 'Please wait…' : submitLabel),
        ),
      ),
    ];
  }
}
