import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../providers/account_provider.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/delete_account_dialog.dart';

class AccountSettingsCard extends ConsumerStatefulWidget {
  const AccountSettingsCard({super.key});

  @override
  ConsumerState<AccountSettingsCard> createState() =>
      _AccountSettingsCardState();
}

class _AccountSettingsCardState extends ConsumerState<AccountSettingsCard> {
  late final TextEditingController _nameController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(accountProvider).session?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final theme = Theme.of(context);
    ref.listen<AccountState>(accountProvider, (previous, next) {
      if (previous?.session?.email == next.session?.email) {
        return;
      }
      final name = next.session?.displayName ?? '';
      _nameController.text = name;
    });

    final server = Uri.tryParse(AppConstants.accountServerUrl);
    final accountsAvailable =
        !kReleaseMode || (server != null && server.isScheme('https'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: account.isSignedIn
            ? _SignedInAccount(
                email: account.session!.email,
                saveLabel: accountSaveLabel(account.saveStatus),
                errorMessage: account.saveStatus == SaveStatus.error
                    ? account.errorMessage
                    : null,
                showRetry:
                    account.saveStatus == SaveStatus.offline ||
                    account.saveStatus == SaveStatus.error,
                showMove: account.hasUnmovedDeviceData,
                nameController: _nameController,
                nameError: _nameError,
                onSaveName: _saveName,
                onRetry: () =>
                    ref.read(accountProvider.notifier).syncIfSignedIn(),
                onMove: () => _move(context),
                onSignOut: () => ref.read(accountProvider.notifier).signOut(),
                onDelete: () => _deleteAccount(context),
              )
            : _SignedOutAccount(
                theme: theme,
                accountsAvailable: accountsAvailable,
                onCreate: () => _openAccount(context, startOnCreate: true),
                onSignIn: () => _openAccount(context),
              ),
      ),
    );
  }

  Future<void> _saveName() async {
    final error = await ref
        .read(accountProvider.notifier)
        .updateDisplayName(_nameController.text);
    if (!mounted) {
      return;
    }
    setState(() => _nameError = error);
  }

  Future<void> _move(BuildContext context) async {
    final error = await ref.read(accountProvider.notifier).moveDeviceData();
    if (!context.mounted || error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (password == null || !context.mounted) {
      return;
    }
    final error = await ref
        .read(accountProvider.notifier)
        .deleteAccount(password);
    if (!context.mounted || error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _openAccount(BuildContext context, {bool startOnCreate = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountScreen(startOnCreate: startOnCreate),
      ),
    );
  }
}

class _SignedOutAccount extends StatelessWidget {
  const _SignedOutAccount({
    required this.theme,
    required this.accountsAvailable,
    required this.onCreate,
    required this.onSignIn,
  });

  final ThemeData theme;
  final bool accountsAvailable;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          accountsAvailable
              ? 'An account keeps your workouts and history if you replace this phone. '
                    'Without an account, everything stays on this device.'
              : 'Workouts and history stay on this phone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        if (accountsAvailable) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('create-account'),
              onPressed: onCreate,
              child: const Text('Create account'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('sign-in'),
              onPressed: onSignIn,
              child: const Text('Sign in'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SignedInAccount extends StatelessWidget {
  const _SignedInAccount({
    required this.email,
    required this.saveLabel,
    required this.errorMessage,
    required this.showRetry,
    required this.showMove,
    required this.nameController,
    required this.nameError,
    required this.onSaveName,
    required this.onRetry,
    required this.onMove,
    required this.onSignOut,
    required this.onDelete,
  });

  final String email;
  final String saveLabel;
  final String? errorMessage;
  final bool showRetry;
  final bool showMove;
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onSaveName;
  final VoidCallback onRetry;
  final VoidCallback onMove;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(email, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          saveLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Display name',
            errorText: nameError,
            helperText: 'Optional. Used later when you share something.',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSaveName,
            child: const Text('Save name'),
          ),
        ),
        if (showRetry) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry save'),
            ),
          ),
        ],
        if (showMove) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onMove,
              child: const Text("Move this device's workouts to my account"),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('delete-account'),
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete account'),
          ),
        ),
      ],
    );
  }
}

String accountSaveLabel(SaveStatus status) {
  return switch (status) {
    SaveStatus.localOnly => 'Saved on this device',
    SaveStatus.saved => 'Saved',
    SaveStatus.saving => 'Saving…',
    SaveStatus.offline => 'Offline — will save when online',
    SaveStatus.error => 'Not saved to your account yet',
  };
}
