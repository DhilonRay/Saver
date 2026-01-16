import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/constants/ui_constants.dart';
import 'package:saver/components/ui_components.dart';
import 'package:saver/components/widgets/loading.dart';
import 'package:saver/components/widgets/space.dart';

class FilledButtonWidget extends StatelessWidget {
  const FilledButtonWidget({
    super.key,
    required this.onTap,
    this.onLongTap,
    this.child,
    this.minHeight = 40,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.buttonText = '',
    this.buttonTextStyle,
    this.isStretched = false,
    this.backgroundColor,
    this.borderRadiusValue = 8.0,
  });

  final void Function()? onTap;
  final void Function()? onLongTap;
  final String buttonText;
  final TextStyle? buttonTextStyle;
  final Widget? child;
  final double minHeight;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final bool isStretched;
  final Color? backgroundColor;
  final double borderRadiusValue;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        child: child ??
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: onTap != null
                  ? const TextStyle(color: Colors.white).merge(buttonTextStyle)
                  : const TextStyle(color: AppColors.primaryText),
            ),
      );
    }
    return FilledButton(
      onPressed: onTap,
      onLongPress: onLongTap,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: padding,
        elevation: 0,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
        ),
      ),
      child: child ??
          Text(
            buttonText,
            textAlign: TextAlign.center,
            style: onTap != null
                ? const TextStyle(color: Colors.white).merge(buttonTextStyle)
                : const TextStyle(color: AppColors.primaryText),
          ),
    );
  }
}

class IconedFilledButtonWidget extends StatelessWidget {
  const IconedFilledButtonWidget({
    super.key,
    this.onTap,
    this.onLongTap,
    required this.icon,
    this.child,
    this.minHeight = 40,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.backgrondColor,
    this.forgroundColor,
    this.isStretched = false,
    this.buttonText = '',
    this.buttonTextStyle,
    this.alignStart = false,
    this.borderRadiusValue,
  });

  final void Function()? onTap;
  final void Function()? onLongTap;
  final Widget icon;
  final String buttonText;
  final TextStyle? buttonTextStyle;
  final Widget? child;
  final bool isStretched;
  final double minHeight;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final Color? backgrondColor;
  final Color? forgroundColor;
  final bool alignStart;
  final double? borderRadiusValue;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        borderRadiusValue: borderRadiusValue,
        child: child ??
            _buildAlignedChild(buttonText, buttonTextStyle, onTap != null),
      );
    }
    return FilledButton(
      onPressed: onTap,
      onLongPress: onLongTap,
      style: FilledButton.styleFrom(
        backgroundColor: backgrondColor,
        foregroundColor: forgroundColor,
        padding: padding,
        elevation: 0,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        shape: borderRadiusValue != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadiusValue!),
              )
            : null,
      ),
      child: child ??
          _buildAlignedContent(
            icon,
            buttonText,
            buttonTextStyle,
            forgroundColor,
            onTap != null,
          ),
    );
  }

  Widget _buildAlignedChild(String label, TextStyle? style, bool isEnabled) {
    if (!alignStart) {
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.center,
        style: isEnabled
            ? TextStyle(
                color: forgroundColor ?? AppColors.primaryText,
              ).merge(style)
            : const TextStyle(color: Colors.white),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: isEnabled
                ? TextStyle(
                    color: forgroundColor ?? AppColors.primaryText,
                  ).merge(style)
                : const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAlignedContent(
    Widget icon,
    String label,
    TextStyle? style,
    Color? fgColor,
    bool isEnabled,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isUnbounded = constraints.maxWidth == double.infinity;

        if (!alignStart) {
          // default center aligned behavior
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              if (isUnbounded)
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: isEnabled
                      ? TextStyle(
                          color: fgColor ?? AppColors.primaryText,
                        ).merge(style)
                      : const TextStyle(color: Colors.white),
                )
              else
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: isEnabled
                        ? TextStyle(
                            color: fgColor ?? AppColors.primaryText,
                          ).merge(style)
                        : const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          );
        }
        // left aligned content
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            if (isUnbounded)
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: isEnabled
                    ? TextStyle(
                        color: fgColor ?? AppColors.primaryText,
                      ).merge(style)
                    : const TextStyle(color: Colors.white),
              )
            else
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: isEnabled
                      ? TextStyle(
                          color: fgColor ?? AppColors.primaryText,
                        ).merge(style)
                      : const TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}

class OutlinedButtonWidget extends StatelessWidget {
  const OutlinedButtonWidget({
    super.key,
    required this.onTap,
    this.child,
    this.minHeight = 40,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.onLongTap,
    this.buttonText = '',
    this.buttonTextStyle,
    this.isStretched = false,
    this.borderRadiusValue = 8.0,
  });

  final void Function()? onTap;
  final void Function()? onLongTap;
  final double minHeight;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final String buttonText;
  final TextStyle? buttonTextStyle;
  final Widget? child;
  final bool isStretched;
  final double borderRadiusValue;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingOutlinedButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        child: child ??
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: onTap != null ? buttonTextStyle : null,
            ),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      onLongPress: onLongTap,
      style: OutlinedButton.styleFrom(
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
        ),
      ),
      child: child ??
          Text(
            buttonText,
            textAlign: TextAlign.center,
            style: onTap != null ? buttonTextStyle : null,
          ),
    );
  }
}

class TonalButtonWidget extends StatelessWidget {
  const TonalButtonWidget({
    super.key,
    this.onTap,
    this.onLongTap,
    this.child,
    this.minHeight = 40,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.elevation,
    this.backgrondColor = AppColors.grayButton,
    this.forgroundColor = AppColors.primaryText,
    this.buttonText = '',
    this.buttonTextStyle,
    this.isStretched = false,
  });

  final void Function()? onTap;
  final void Function()? onLongTap;
  final String buttonText;
  final TextStyle? buttonTextStyle;
  final Widget? child;
  final bool isStretched;
  final double minHeight;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color backgrondColor;
  final Color forgroundColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        child: child ??
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: onTap != null
                  ? const TextStyle(
                      color: AppColors.primaryText,
                    ).merge(buttonTextStyle)
                  : const TextStyle(color: Colors.white),
            ),
      );
    }
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: backgrondColor,
        foregroundColor: forgroundColor,
        padding: padding,
        elevation: onTap == null ? 0 : elevation,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
      ),
      child: child ??
          Text(
            buttonText,
            textAlign: TextAlign.center,
            style: onTap != null
                ? const TextStyle(
                    color: AppColors.primaryText,
                  ).merge(buttonTextStyle)
                : const TextStyle(color: Colors.white),
          ),
    );
  }
}

class IconedTonalButtonWidget extends StatelessWidget {
  const IconedTonalButtonWidget({
    super.key,
    this.onTap,
    this.child,
    required this.icon,
    this.minHeight = 40,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.elevation,
    this.buttonText = '',
    this.buttonTextStyle,
    this.isStretched = false,
    this.backgrondColor = AppColors.grayButton,
    this.forgroundColor = AppColors.primaryText,
  });

  final void Function()? onTap;
  final String buttonText;
  final TextStyle? buttonTextStyle;
  final Widget? child;
  final bool isStretched;
  final Widget icon;
  final double minHeight;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color backgrondColor;
  final Color forgroundColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        child: child ??
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: onTap != null
                  ? const TextStyle(
                      color: AppColors.primaryText,
                    ).merge(buttonTextStyle)
                  : const TextStyle(color: Colors.white),
            ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: backgrondColor,
        foregroundColor: forgroundColor,
        padding: padding,
        elevation: onTap == null ? 0 : elevation,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
      ),
      icon: icon,
      label: child ??
          Text(
            buttonText,
            textAlign: TextAlign.center,
            style: onTap != null
                ? TextStyle(color: forgroundColor).merge(buttonTextStyle)
                : const TextStyle(color: Colors.white),
          ),
    );
  }
}

class FilledIconedButtonWidget extends StatelessWidget {
  const FilledIconedButtonWidget({
    super.key,
    this.onTap,
    required this.icon,
    this.minHeight = 40,
    this.borderRadiusValue = 10,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.elevation,
    this.buttonTextStyle,
    this.backgrondColor,
    this.forgroundColor,
  });

  final void Function()? onTap;
  final TextStyle? buttonTextStyle;
  final Widget icon;
  final double minHeight;
  final double borderRadiusValue;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgrondColor;
  final Color? forgroundColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingIconButtonWidget(
        icon: icon,
        borderRadiusValue: borderRadiusValue,
        minHeight: minHeight,
        minimumSize: minimumSize,
        padding: padding,
      );
    }
    return IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: backgrondColor,
        foregroundColor: forgroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        elevation: onTap == null ? 0 : elevation,
        minimumSize: Size(48, minHeight),
      ),
      icon: icon,
    );
  }
}

class TonalIconedButtonWidget extends StatelessWidget {
  const TonalIconedButtonWidget({
    super.key,
    this.onTap,
    required this.icon,
    this.minHeight = 40,
    this.borderRadiusValue = 10,
    this.minimumSize,
    this.isLoading = false,
    this.padding,
    this.elevation,
    this.buttonTextStyle,
    this.isStretched = false,
    this.backgrondColor = AppColors.grayButton,
    this.forgroundColor = AppColors.primaryText,
  });

  final void Function()? onTap;
  final TextStyle? buttonTextStyle;
  final bool isStretched;
  final Widget icon;
  final double minHeight;
  final double borderRadiusValue;
  final Size? minimumSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color backgrondColor;
  final Color forgroundColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      /*       return LoadingButtonWidget(
        minHeight: minHeight,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(30, minHeight),
        child:
            child ??
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: onTap != null
                  ? const TextStyle(
                      color: AppColors.primaryText,
                    ).merge(buttonTextStyle)
                  : const TextStyle(color: Colors.white),
            ),
      ); */
      return LoadingIconButtonWidget(
        icon: icon,
        borderRadiusValue: borderRadiusValue,
        minHeight: minHeight,
        minimumSize: minimumSize,
        padding: padding,
      );
    }
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: backgrondColor,
        foregroundColor: forgroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        elevation: onTap == null ? 0 : elevation,
        minimumSize: isStretched
            ? Size.fromHeight(minHeight)
            : minimumSize ?? Size(48, minHeight),
      ),
      icon: icon,
    );
  }
}

class TwoButtonRowWidget extends StatelessWidget {
  final Widget firstButtonWidget;
  final Widget secondButtonWidget;
  final double midSpaceWidth;
  const TwoButtonRowWidget({
    super.key,
    required this.firstButtonWidget,
    required this.secondButtonWidget,
    this.midSpaceWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: firstButtonWidget),
        HorizontalGap(midSpaceWidth),
        Expanded(child: secondButtonWidget),
      ],
    );
  }
}

class RawButtonWidget extends StatelessWidget {
  final Widget child;
  final void Function()? onTap;
  final double? borderRadiusValue;
  final Color? backgroundColor;
  final FocusNode? focusNode;
  final double elevation;
  final Color? shadowColor;
  final bool isCircleShape;
  final ShapeBorder? shape;

  const RawButtonWidget({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadiusValue,
    this.backgroundColor,
    this.focusNode,
    this.elevation = 0,
    this.shadowColor,
    this.isCircleShape = false,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: shape ?? (isCircleShape ? const CircleBorder() : null),
      borderRadius: isCircleShape
          ? null
          : borderRadiusValue != null
              ? BorderRadius.circular(borderRadiusValue!)
              : null,
      child: InkWell(
        onTap: onTap,
        customBorder: shape ?? (isCircleShape ? const CircleBorder() : null),
        borderRadius: isCircleShape
            ? null
            : borderRadiusValue != null
                ? BorderRadius.all(Radius.circular(borderRadiusValue!))
                : null,
        child: child,
      ),
    );
  }
}

class TightTextButtonWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final void Function()? onTap;
  const TightTextButtonWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
        minimumSize: Size(5, 5),
        padding: EdgeInsets.zero,
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: textStyle),
    );
  }
}

/// This icon button does not have any padding, margin around it
class BackgroundColoredIconButtonWidget extends StatelessWidget {
  final Widget icon;
  final void Function()? onTap;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Color? backgroundColor;
  const BackgroundColoredIconButtonWidget({
    super.key,
    required this.icon,
    this.onTap,
    this.constraints,
    this.padding,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      padding: padding,
      constraints: constraints,
      onPressed: onTap,
      icon: icon,
      color: iconColor,
      style: IconButton.styleFrom(
        padding: padding,
        backgroundColor: backgroundColor,
        foregroundColor: iconColor,
      ),
    );
  }
}

/// This icon button does not have any padding, margin around it
class TightIconButtonWidget extends StatelessWidget {
  final Widget icon;
  final void Function()? onTap;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  const TightIconButtonWidget({
    super.key,
    required this.icon,
    this.onTap,
    this.constraints,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: const VisualDensity(
        horizontal: VisualDensity.minimumDensity,
        vertical: VisualDensity.minimumDensity,
      ),
      constraints: constraints,
      onPressed: onTap,
      icon: icon,
      style: IconButton.styleFrom(padding: padding),
    );
  }
}

class BackButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  final Widget? icon;
  const BackButtonWidget({super.key, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      /*       icon: Icon(
        Icons.chevron_left,
        color: AppUIConstants.primaryColor,
        size: 30,
      ), */
      icon: icon ?? SvgPicture.asset(AppImages.backArrowSvg),
      onPressed: onTap,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}

class BottomSheetBackButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  const BottomSheetBackButtonWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: RawButtonWidget(
        onTap: onTap ?? () => Get.back(),
        borderRadiusValue: AppUIConstants.borderRadius10,
        backgroundColor: Colors.white,
        child: SizedBox.square(
          dimension: 40,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppUIComponents.borderRadius10,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: Icon(Icons.chevron_left),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FilterButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  const FilterButtonWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      borderRadiusValue: AppUIConstants.borderRadius10,
      backgroundColor: Colors.white,
      child: SizedBox.square(
        dimension: 44,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppUIComponents.borderRadius10,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: SvgPicture.asset(AppImages.filterSvg),
            ),
          ),
        ),
      ),
    );
  }
}

class AppBarPlusButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  const AppBarPlusButtonWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      borderRadiusValue: AppUIConstants.borderRadius8,
      child: SizedBox.square(
        dimension: 40,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppUIComponents.borderRadius8,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(Icons.add, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

class FloatingButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? icon;
  final String? toolTipMessage;
  final ShapeBorder? shape;
  final double? elevation;
  const FloatingButtonWidget({
    super.key,
    this.onTap,
    this.backgroundColor = AppColors.primary,
    this.icon,
    this.foregroundColor = Colors.white,
    this.toolTipMessage,
    this.shape,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: toolTipMessage,
      foregroundColor: foregroundColor,
      elevation: elevation,
      shape: shape ??
          RoundedRectangleBorder(borderRadius: AppUIComponents.borderRadius10),
      onPressed: onTap,
      backgroundColor: backgroundColor,
      child: icon,
    );
  }
}

class PlusIconButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  const PlusIconButtonWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledIconedButtonWidget(icon: Icon(Icons.add), onTap: onTap);
  }
}

class PlusFloatingIconButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  final ShapeBorder? shape;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? elevation;
  const PlusFloatingIconButtonWidget({
    super.key,
    this.onTap,
    this.shape,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingButtonWidget(
      icon: Icon(Icons.add),
      onTap: onTap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      shape: shape,
    );
  }
}

class WhitePlusFloatingIconButtonWidget extends StatelessWidget {
  final void Function()? onTap;
  final ShapeBorder shape;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final Widget? icon;
  const WhitePlusFloatingIconButtonWidget({
    super.key,
    this.onTap,
    this.shape = const CircleBorder(side: BorderSide(color: AppColors.border)),
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppColors.primary,
    this.elevation = 0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingButtonWidget(
      icon: icon ?? Icon(Icons.add),
      onTap: onTap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      shape: shape,
    );
  }
}

class PlusMinusSmallIconButton extends StatelessWidget {
  final bool isIconMinus;
  final void Function()? onTap;
  const PlusMinusSmallIconButton({
    super.key,
    this.isIconMinus = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      backgroundColor: AppColors.border,
      borderRadiusValue: 4,
      child: SizedBox.square(
        dimension: 32,
        child: Icon(isIconMinus ? Icons.remove : Icons.add),
      ),
    );
  }
}
