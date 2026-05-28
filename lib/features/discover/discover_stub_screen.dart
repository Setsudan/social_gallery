import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class DiscoverStubScreen extends StatelessWidget {
  const DiscoverStubScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OneUiPageHeader(title: title, subtitle: message),
          Expanded(
            child: Center(
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
