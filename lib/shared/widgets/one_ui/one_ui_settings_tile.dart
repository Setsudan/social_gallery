import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

/// Pastel icon badge colors used on Samsung-style settings rows.
class OneUiSettingsIcon {
  const OneUiSettingsIcon({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  static const display = OneUiSettingsIcon(
    icon: Icons.dark_mode_outlined,
    background: Color(0xFFE8E0F5),
    foreground: Color(0xFF7B61A8),
  );

  static const language = OneUiSettingsIcon(
    icon: Icons.translate_rounded,
    background: Color(0xFFE8F5E9),
    foreground: Color(0xFF2E7D32),
  );

  static const text = OneUiSettingsIcon(
    icon: Icons.format_size_rounded,
    background: Color(0xFFDCE9FF),
    foreground: Color(0xFF0381FE),
  );

  static const motion = OneUiSettingsIcon(
    icon: Icons.motion_photos_auto_outlined,
    background: Color(0xFFE0F2F1),
    foreground: Color(0xFF00897B),
  );

  static const palette = OneUiSettingsIcon(
    icon: Icons.palette_outlined,
    background: Color(0xFFFCE4EC),
    foreground: Color(0xFFE91E63),
  );

  static const gallery = OneUiSettingsIcon(
    icon: Icons.photo_library_outlined,
    background: Color(0xFFFFF3E0),
    foreground: Color(0xFFEF6C00),
  );

  static const folder = OneUiSettingsIcon(
    icon: Icons.folder_outlined,
    background: Color(0xFFE3F2FD),
    foreground: Color(0xFF1976D2),
  );

  static const travel = OneUiSettingsIcon(
    icon: Icons.flight_takeoff_rounded,
    background: Color(0xFFE8F5E9),
    foreground: Color(0xFF43A047),
  );

  static const organize = OneUiSettingsIcon(
    icon: Icons.swipe_rounded,
    background: Color(0xFFF3E5F5),
    foreground: Color(0xFF8E24AA),
  );

  static const trash = OneUiSettingsIcon(
    icon: Icons.delete_sweep_outlined,
    background: Color(0xFFFFEBEE),
    foreground: Color(0xFFE53935),
  );

  static const storage = OneUiSettingsIcon(
    icon: Icons.storage_outlined,
    background: Color(0xFFECEFF1),
    foreground: Color(0xFF546E7A),
  );

  static const widgets = OneUiSettingsIcon(
    icon: Icons.widgets_outlined,
    background: Color(0xFFE3F2FD),
    foreground: Color(0xFF1565C0),
  );

  static const info = OneUiSettingsIcon(
    icon: Icons.info_outline_rounded,
    background: Color(0xFFE8EAF6),
    foreground: Color(0xFF5C6BC0),
  );

  static const share = OneUiSettingsIcon(
    icon: Icons.share_outlined,
    background: Color(0xFFE0F7FA),
    foreground: Color(0xFF00ACC1),
  );

  static const privacy = OneUiSettingsIcon(
    icon: Icons.privacy_tip_outlined,
    background: Color(0xFFFFF8E1),
    foreground: Color(0xFFF9A825),
  );

  static const license = OneUiSettingsIcon(
    icon: Icons.article_outlined,
    background: Color(0xFFF1F8E9),
    foreground: Color(0xFF689F38),
  );

  static const cloud = OneUiSettingsIcon(
    icon: Icons.cloud_upload_outlined,
    background: Color(0xFFE3F2FD),
    foreground: Color(0xFF1565C0),
  );

  static const device = OneUiSettingsIcon(
    icon: Icons.smartphone_outlined,
    background: Color(0xFFEDE7F6),
    foreground: Color(0xFF5E35B1),
  );

  static const sync = OneUiSettingsIcon(
    icon: Icons.sync_rounded,
    background: Color(0xFFE0F2F1),
    foreground: Color(0xFF00695C),
  );
}

/// Single tappable row inside a [OneUiSettingsGroup].
class OneUiSettingsTile extends StatelessWidget {
  const OneUiSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.showChevron = true,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final OneUiSettingsIcon? icon;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showChevron;
  final bool destructive;

  static const double _iconSize = 28;
  static const double _badgeSize = 36;
  static const double _horizontalPadding = 18;
  static const double _dividerInset = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final canTap = onTap != null;

    final hasInteractiveTrailing = trailing != null;
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && (value != null || (showChevron && canTap))) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Flexible(
              child: Text(
                value!,
                style: valueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          if (value != null && showChevron && canTap)
            const SizedBox(width: 2),
          if (showChevron && canTap)
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
        ],
      );
    }

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasInteractiveTrailing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: OneUiSpacing.listItemVertical,
          ),
          child: Row(
            crossAxisAlignment: subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: subtitle != null ? 2 : 0),
                  child: _IconBadge(icon: icon!),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );

    if (!showDivider) return row;

    return Column(
      children: [
        row,
        Padding(
          padding: EdgeInsets.only(
            left: icon != null ? _dividerInset : _horizontalPadding,
          ),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final OneUiSettingsIcon icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? icon.foreground.withValues(alpha: 0.18)
        : icon.background;
    final fg = isDark ? icon.foreground.withValues(alpha: 0.95) : icon.foreground;

    return Container(
      width: OneUiSettingsTile._badgeSize,
      height: OneUiSettingsTile._badgeSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon.icon, size: OneUiSettingsTile._iconSize - 4, color: fg),
    );
  }
}

/// Rounded grouped list container for settings rows (One UI).
class OneUiSettingsGroup extends StatelessWidget {
  const OneUiSettingsGroup({
    super.key,
    required this.children,
    this.margin,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          margin ??
          const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Section label plus grouped settings rows.
class OneUiSettingsSection extends StatelessWidget {
  const OneUiSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.headerPadding,
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? headerPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OneUiSectionHeader(title, padding: headerPadding),
        OneUiSettingsGroup(children: children),
      ],
    );
  }
}

/// Scrollable One UI bottom sheet (avoids RenderFlex overflow).
Future<T?> showOneUiSettingsSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
      return AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.lg),
            child: builder(context),
          ),
        ),
      );
    },
  );
}

/// Radio-style option picker presented as a One UI bottom sheet.
Future<T?> showOneUiSettingsPicker<T>({
  required BuildContext context,
  required String title,
  required List<OneUiPickerOption<T>> options,
  required T selected,
}) {
  return showOneUiSettingsSheet<T>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md,
            ),
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          ...options.map((option) {
            final isSelected = option.value == selected;
            return ListTile(
              title: Text(option.label),
              subtitle: option.subtitle != null
                  ? Text(option.subtitle!)
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, option.value),
            );
          }),
        ],
      );
    },
  );
}

class OneUiPickerOption<T> {
  const OneUiPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}
