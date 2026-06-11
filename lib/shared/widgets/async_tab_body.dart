import 'package:flutter/material.dart';
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return EmptyState(
        title: 'Could not load',
        message: error.toString(),
        icon: Icons.error_outline,
      );
    }
    if (isEmpty) {
      return empty ??
          const EmptyState(
            title: 'Nothing here',
            icon: Icons.inbox_outlined,
          );
    }
    return child;
  }
}
