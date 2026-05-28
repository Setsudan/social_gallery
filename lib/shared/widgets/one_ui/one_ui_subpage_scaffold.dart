import 'package:flutter/material.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

/// Pushed screen: minimal top bar + large in-body title (One UI).
class OneUiSubpageScaffold extends StatelessWidget {
  const OneUiSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onBack,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OneUiPageHeader(title: title, subtitle: subtitle),
          Expanded(
            child: Padding(padding: padding ?? EdgeInsets.zero, child: body),
          ),
        ],
      ),
    );
  }
}
