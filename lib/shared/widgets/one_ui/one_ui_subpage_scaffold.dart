import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/shared/widgets/async_tab_body.dart';
import 'package:social_gallery/shared/widgets/nav_back_leading.dart';

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
    final canPop =
        onBack != null ||
        GoRouter.of(context).canPop() ||
        Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop
            ? NavBackLeading(
                onPressed:
                    onBack ??
                    () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
              )
            : null,
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
          child: Padding(padding: padding ?? EdgeInsets.zero, child: body),
        ),
      ),
    );
  }
}
