import 'package:flutter/material.dart';
import 'package:social_gallery/shared/widgets/async_tab_body.dart';

/// Pushed screen: minimal top bar (One UI).
class OneUiSubpageScaffold extends StatelessWidget {
  const OneUiSubpageScaffold({
    super.key,
    this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onBack,
    this.padding,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    this.empty,
    this.appBarTitle,
    this.onRetry,
  });

  final String? title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final Widget? empty;
  final String? appBarTitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
        title: appBarTitle != null ? Text(appBarTitle!) : null,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: false,
        child: AsyncTabBody(
          isLoading: isLoading,
          error: error,
          isEmpty: isEmpty,
          empty: empty,
          onRetry: onRetry,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: body,
          ),
        ),
      ),
    );
  }
}
