import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/ui_components.dart';
import 'package:saver/components/widgets/buttons.dart';


class CoreWidgets {
  static AppBar appBar({
    Widget? leading,
    Widget? trailing,
    Color? backgroundColor,
    bool showBackButton = true,
    List<Widget>? actions,
    String? title,
    Widget? titleWidget,
    void Function()? onBackButtonTap,
  }) => AppBar(
    backgroundColor: backgroundColor,
    automaticallyImplyLeading: showBackButton,
    title:
        titleWidget ?? Text(title ?? '', style: AppTextStyles.extraBodyLarge),
    leading: showBackButton
        ? Builder(
            builder: (BuildContext context) =>
                BackButtonWidget(onTap: onBackButtonTap ?? () => Get.back()),
          )
        : null,
    actions: actions,
  );

  /// A reusable styled dropdown used across the app. Mirrors the style used
  /// in Add Product screen and other forms.
  static Widget dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isExpanded = true,
    Widget? icon,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? AppUIComponents.borderRadius8,
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: isExpanded,
        underline: const SizedBox.shrink(),
        icon:
            icon ??
            Icon(Icons.keyboard_arrow_down, color: AppColors.primaryText),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
