import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

Future<String?> showVaultPasswordDialog(
  BuildContext context, {
  required bool isNewPassword,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: !isNewPassword,
    builder: (context) => _VaultPasswordDialog(isNewPassword: isNewPassword),
  );
}

class _VaultPasswordDialog extends StatefulWidget {
  const _VaultPasswordDialog({required this.isNewPassword});

  final bool isNewPassword;

  @override
  State<_VaultPasswordDialog> createState() => _VaultPasswordDialogState();
}

class _VaultPasswordDialogState extends State<_VaultPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.length < 8) return;

    if (widget.isNewPassword) {
      if (password != _confirmController.text) return;
    }

    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.isNewPassword
            ? l10n.vaultPasswordSetTitle
            : l10n.vaultPasswordEnterTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isNewPassword
                ? l10n.vaultPasswordSetDescription
                : l10n.vaultPasswordEnterDescription,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: OneUiSpacing.md),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l10n.vaultPasswordLabel,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.isNewPassword) ...[
            const SizedBox(height: OneUiSpacing.sm),
            TextField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.vaultPasswordConfirmLabel,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.isNewPassword)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.actionOk),
        ),
      ],
    );
  }
}
