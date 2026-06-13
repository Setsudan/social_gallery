import 'package:flutter/material.dart';
import 'package:social_gallery/shared/widgets/async_tab_body.dart';

/// Shell tab screen: large in-body title + scrollable content.
class OneUiTabPageScaffold extends StatelessWidget {
  const OneUiTabPageScaffold({
    super.key,
    this.title,
    required this.body,
    this.subtitle,
    this.extendBody = false,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    this.empty,
    this.floatingActionButton,
  });

  final String? title;
  final String? subtitle;
  final Widget body;
  final bool extendBody;
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final Widget? empty;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      body: AsyncTabBody(
        isLoading: isLoading,
        error: error,
        isEmpty: isEmpty,
        empty: empty,
        child: body,
      ),
    );
  }
}
