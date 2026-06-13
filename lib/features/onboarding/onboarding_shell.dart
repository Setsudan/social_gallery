import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.pageIndex,
    required this.pageCount,
    required this.child,
    this.onBack,
    required this.onNext,
    this.nextLabel = 'Next',
    this.nextEnabled = true,
    this.showBack = true,
    this.showSkip = false,
    this.onSkip,
    this.footer,
  });

  final int pageIndex;
  final int pageCount;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool nextEnabled;
  final bool showBack;
  final bool showSkip;
  final VoidCallback? onSkip;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.md,
              ),
              child: Row(
                children: [
                  if (showBack && pageIndex > 0)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: _OnboardingDots(
                      count: pageCount,
                      index: pageIndex,
                    ),
                  ),
                  if (showSkip && onSkip != null)
                    TextButton(onPressed: onSkip, child: const Text('Skip'))
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: child),
            ?footer,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.lg,
              ),
              child: FilledButton(
                onPressed: nextEnabled ? onNext : null,
                child: Text(nextLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
