import 'package:flutter/material.dart';

import '../theme.dart';

/// A scrolling screen with consistent padding and a subtle gradient.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Insets.screen,
      children: children,
    );
    final refresh = onRefresh;
    if (refresh != null) {
      list = RefreshIndicator(onRefresh: refresh, child: list);
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [AppColors.backgroundTop, AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: list,
          ),
        ),
      ),
    );
  }
}

/// A pushed screen with a back button.
class SubScreen extends StatelessWidget {
  const SubScreen({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBody(
        children: [
          ScreenHeader(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: title,
            subtitle: subtitle,
          ),
          ...children,
        ],
      ),
    );
  }
}

/// The title row at the top of each screen.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Insets.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Insets.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Insets.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A rounded panel, optionally tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = Insets.card,
    this.margin = const EdgeInsets.only(bottom: Insets.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A card with an icon, two lines of text and a trailing widget.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing = const Icon(Icons.chevron_right_rounded),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: Insets.md),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.blue),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: Insets.xs),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          trailing,
        ],
      ),
    );
  }
}

/// A tinted circle containing an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// A row of equally sized metric tiles.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.tiles});

  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: Insets.md),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

/// One metric.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        vertical: Insets.lg,
        horizontal: Insets.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: Insets.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: Insets.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small coloured status label.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.color,
    this.icon = Icons.circle,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: Insets.sm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows an SDK error.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red),
          const SizedBox(width: Insets.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
