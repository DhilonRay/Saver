import 'dart:ui';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Admin Design System – Premium Dark Glassmorphism
/// ──────────────────────────────────────────────────────────────────────────────
class AdminTheme {
  AdminTheme._();

  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF080F1A);
  static const Color bgPrimary = Color(0xFF0D1B2A);
  static const Color bgCard = Color(0xFF13243B);
  static const Color bgSurface = Color(0xFF1B2838);
  static const Color bgElevated = Color(0xFF243447);

  static const Color accent = Color(0xFF00E5FF);
  static const Color accentGlow = Color(0xFF00B8D4);
  static const Color accentSoft = Color(0xFF006A7A);

  static const Color green = Color(0xFF00E676);
  static const Color greenDark = Color(0xFF1B5E20);
  static const Color orange = Color(0xFFFF9100);
  static const Color orangeDark = Color(0xFFE65100);
  static const Color red = Color(0xFFFF5252);
  static const Color redDark = Color(0xFFB71C1C);
  static const Color purple = Color(0xFFE040FB);
  static const Color purpleDark = Color(0xFF6A1B9A);
  static const Color amber = Color(0xFFFFD740);
  static const Color blue = Color(0xFF448AFF);
  static const Color blueDark = Color(0xFF1A237E);

  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);
  static const Color divider = Color(0xFF1E3348);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgPrimary, Color(0xFF0A1628)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00838F), Color(0xFF006064)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x15FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  // ─── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration get glassCard => BoxDecoration(
        color: bgCard.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration glassCardAccent(Color color) => BoxDecoration(
        color: bgCard.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration glowDecoration(Color color) => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // ─── Text Styles ───────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle stat = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Admin Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A premium glassmorphism card wrapper.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accentColor,
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = accentColor != null
        ? AdminTheme.glassCardAccent(accentColor!)
        : AdminTheme.glassCard;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// A premium stat card with glowing icon.
class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: AdminTheme.stat.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AdminTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AdminTheme.caption.copyWith(color: color.withOpacity(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header with accent underline.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color = AdminTheme.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: AdminTheme.heading3.copyWith(color: color),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Premium filter chip for period selection.
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.accent : AdminTheme.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                selected ? AdminTheme.accent : Colors.white.withOpacity(0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AdminTheme.accent.withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AdminTheme.bgDeep : AdminTheme.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Detail row used in bottom sheets and detail pages.
class AdminDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const AdminDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: AdminTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AdminTheme.body.copyWith(
                color: AdminTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search bar with glassmorphism.
class AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AdminTheme.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: TextField(
            controller: controller,
            style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AdminTheme.body.copyWith(color: AdminTheme.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AdminTheme.accent.withOpacity(0.6), size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              suffixIcon: controller.text.isNotEmpty && onClear != null
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AdminTheme.textMuted, size: 18),
                      onPressed: onClear,
                    )
                  : null,
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Status badge with color.
class AdminStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AdminStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Admin App Bar – consistent across all screens.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AdminTheme.heading2,
      ),
      backgroundColor: AdminTheme.bgDeep,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: showBack,
      iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
      actions: actions,
    );
  }
}

/// Mini tag used in lists.
class AdminMiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const AdminMiniTag({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
