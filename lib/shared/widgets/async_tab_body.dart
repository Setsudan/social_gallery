import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';

class AsyncTabBody extends StatelessWidget {
  const AsyncTabBody({
    super.key,
    required this.isLoading,
    required this.child,
    this.header,
    this.error,
    this.isEmpty = false,
    this.empty,
    this.onRetry,
  });

  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final Widget? header;
  final Widget child;
  final Widget? empty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (header != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header!,
          Expanded(child: _buildBody(context)),
        ],
      );
    }
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return EmptyState(
        title: l10n.errorCouldNotLoad,
        message: error.toString(),
        icon: Icons.error_outline,
      );
    }
    if (isEmpty) {
      return empty ??
          EmptyState(
            title: l10n.emptyNothingHere,
            icon: Icons.inbox_outlined,
          );
    }
    return child;
  }
}
