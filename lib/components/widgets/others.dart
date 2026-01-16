import 'dart:io';

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/constants/ui_constants.dart';
import 'package:saver/components/loader.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/ui_components.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/loading.dart';
import 'package:saver/components/widgets/space.dart';


class SvgPictureAssetWidget extends StatelessWidget {
  final String assetName;
  final double? height;
  final double? width;
  final Color? color;
  final String? package;
  final BoxFit fit;
  const SvgPictureAssetWidget(
    this.assetName, {
    super.key,
    this.height,
    this.width,
    this.color,
    this.package,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      height: height,
      width: width,
      fit: fit,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class OtpWidget extends StatelessWidget {
  final int length;
  final TextEditingController? controller;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String value)? onCompleted;
  const OtpWidget({
    super.key,
    this.length = 6,
    this.controller,
    this.onCompleted,
    this.errorText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Pinput(
      crossAxisAlignment: CrossAxisAlignment.center,
      errorText: errorText,
      controller: controller,
      length: length,
      validator: validator,
      autofillHints: const [AutofillHints.oneTimeCode],
      defaultPinTheme: PinTheme(
        width: 51,
        height: 44,
        textStyle: TextStyle(color: AppColors.primaryText, fontSize: 14),
        decoration: BoxDecoration(
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 1, color: AppColors.border2),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 51,
        height: 44,
        textStyle: TextStyle(color: AppColors.primaryText, fontSize: 14),
        decoration: BoxDecoration(
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 1, color: AppColors.secondaryText),
        ),
      ),
      errorPinTheme: PinTheme(
        width: 51,
        height: 44,
        textStyle: TextStyle(color: AppColors.error, fontSize: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 1, color: AppColors.error),
        ),
      ),
      submittedPinTheme: PinTheme(
        width: 51,
        height: 44,
        textStyle: TextStyle(color: AppColors.primaryText, fontSize: 14),
        decoration: BoxDecoration(
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 1, color: AppColors.secondaryText),
        ),
      ),
      followingPinTheme: PinTheme(
        width: 51,
        height: 44,
        textStyle: TextStyle(color: AppColors.primaryText, fontSize: 14),
        decoration: BoxDecoration(
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 1, color: AppColors.border2),
        ),
      ),
      onCompleted: onCompleted,
    );
  }
}

class OrangeCheckboxWidget extends StatelessWidget {
  final bool? value;
  final void Function(bool?)? onChanged;
  const OrangeCheckboxWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.white;
        }),
      ),
    );
  }
}

class CheckboxWidget extends StatelessWidget {
  final bool? value;
  final void Function(bool?)? onChanged;
  const CheckboxWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: Checkbox(value: value, onChanged: onChanged),
    );
  }
}

class RadioWidget<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final void Function(T? value)? onChanged;
  const RadioWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: Radio(value: value, groupValue: groupValue, onChanged: onChanged),
    );
  }
}

class CachedNetworkImageWidget extends StatelessWidget {
  final String imageURL;
  final BoxFit boxFit;
  final int? cacheHeight;
  final int? cacheWidth;
  final String placeholderAssetRasterImage;
  final Widget Function(
    BuildContext context,
    ImageProvider<Object> imageProvider,
  )?
  imageBuilder;
  const CachedNetworkImageWidget({
    super.key,
    required this.imageURL,
    this.boxFit = BoxFit.cover,
    this.cacheHeight,
    this.cacheWidth,
    this.imageBuilder,
    this.placeholderAssetRasterImage = AppImages.imagePlaceHolderIconPng,
  });

  @override
  Widget build(BuildContext context) {
    return imageURL.isEmpty
        ? imageBuilder == null
              ? Image.asset(placeholderAssetRasterImage, fit: BoxFit.contain)
              : imageBuilder!(
                  context,
                  Image.asset(AppImages.imagePlaceHolderIconPng).image,
                )
        : CachedNetworkImage(
            imageUrl: imageURL,
            placeholder: (context, url) => LoadingImagePlaceholderWidget(
              loadingAssetImageLocation: placeholderAssetRasterImage,
            ),
            errorWidget: (context, url, error) => const ErrorLoadedIconWidget(),
            imageBuilder: imageBuilder,
            memCacheHeight: cacheHeight,
            memCacheWidth: cacheWidth,
            fit: boxFit,
          );
  }
}

class ErrorLoadedIconWidget extends StatelessWidget {
  final bool isLargeIcon;
  const ErrorLoadedIconWidget({super.key, this.isLargeIcon = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.error_outline,
        size: isLargeIcon ? 40 : null,
        color: AppColors.error,
      ),
    );
  }
}

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 4,
        width: 96,
        decoration: ShapeDecoration(
          shape: StadiumBorder(),
          color: Color(0xFFE8EAEB),
        ),
      ),
    );
  }
}

class ChipWidget extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final EdgeInsets padding;
  const ChipWidget({
    super.key,
    required this.label,
    this.labelStyle,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.bodyMedium.merge(labelStyle),
      elevation: 0,
      side: BorderSide.none,
      labelPadding: EdgeInsets.zero,
      visualDensity: VisualDensity(
        horizontal: VisualDensity.minimumDensity,
        vertical: VisualDensity.minimumDensity,
      ),
      padding: padding,
      shape: StadiumBorder(),
      backgroundColor:
          backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

class DividerWidget extends StatelessWidget {
  final Color color;
  final double height;
  const DividerWidget({
    super.key,
    this.color = AppColors.border,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(height: height, thickness: height, color: AppColors.border);
  }
}

class ScaffoldBottomWidget extends StatelessWidget {
  final Widget child;
  final double bottomGaps;
  const ScaffoldBottomWidget({
    super.key,
    required this.child,
    this.bottomGaps = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppUIConstants.sidePadding,
        5,
        AppUIConstants.sidePadding,
        context.mediaQueryViewPadding.bottom + bottomGaps,
      ),
      child: child,
    );
  }
}

class CardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? overrideBorderRadius;
  final Color backgroundColor;
  final double borderRadius;
  final AlignmentGeometry alignment;
  final double elevation;
  final BorderSide borderSide;
  const CardWidget({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = Colors.white,
    this.borderRadius = AppUIConstants.borderRadius20,
    this.alignment = AlignmentDirectional.topStart,
    this.elevation = 10,
    this.overrideBorderRadius,
    this.borderSide = BorderSide.none,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: backgroundColor,
      margin: EdgeInsets.zero,
      shadowColor: const Color(0x0F1C330F).withValues(alpha: 0.06),
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        side: borderSide,
      ).copyWith(borderRadius: overrideBorderRadius),
      child: Padding(
        padding: padding,
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

class ImageBackgroundWidget extends StatelessWidget {
  final Widget child;
  final double? squareSize;
  final double? height;
  final double? width;
  final bool isSquareShape;
  final double iconSize;
  final Color color;
  final BorderRadiusGeometry? borderRadius;
  const ImageBackgroundWidget({
    super.key,
    required this.child,
    this.squareSize,
    this.height,
    this.width,
    this.isSquareShape = true,
    this.color = AppColors.gray,
    this.iconSize = 24,
    this.borderRadius = AppUIComponents.borderRadius8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isSquareShape ? squareSize : height,
      width: isSquareShape ? squareSize : width,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: SizedBox.square(dimension: iconSize, child: child),
    );
  }
}

class HorizontalDashedLineWidget extends StatelessWidget {
  const HorizontalDashedLineWidget({
    super.key,
    this.height = 1,
    this.color = AppColors.border,
  });
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

class VerticalDashedLineWidget extends StatelessWidget {
  const VerticalDashedLineWidget({
    super.key,
    this.width = 1,
    this.color = AppColors.border,
  });
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxHeight = constraints.constrainWidth();
        const dashHeight = 4.0;
        final dashWidth = width;
        final dashCount = (boxHeight / (2 * dashHeight)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.vertical,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

class ListTileWidget extends StatelessWidget {
  final void Function()? onTap;
  final Widget? prefix;
  final double prefixSpace;
  final Widget? suffix;
  final double suffixSpace;
  final double? afterSuffixSpace;
  final Widget content;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final Color backgroundColor;
  const ListTileWidget({
    super.key,
    this.onTap,
    this.prefix,
    this.prefixSpace = 8,
    this.suffix,
    this.suffixSpace = 8,
    required this.content,
    this.afterSuffixSpace,
    this.elevation = 10,
    this.padding = const EdgeInsets.all(8),
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadiusValue: AppUIConstants.borderRadius10,
      shadowColor: Color(0x0F1C330D),
      elevation: elevation,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (prefix != null) prefix!,
            if (prefix != null) HorizontalGap(prefixSpace),
            Expanded(child: content),
            if (suffix != null) HorizontalGap(suffixSpace),
            if (suffix != null) suffix!,
            if (afterSuffixSpace != null) HorizontalGap(afterSuffixSpace),
          ],
        ),
      ),
    );
  }
}

class IconLabelListTileWidget extends StatelessWidget {
  final String label;
  final Widget icon;
  final TextStyle? textStyle;
  final void Function()? onTap;
  final double iconSquareSize;
  final Color imageBackgroundColor;
  final double prefixSpace;
  final double iconSize;
  final double elevation;
  const IconLabelListTileWidget({
    super.key,
    required this.label,
    required this.icon,
    this.textStyle,
    this.onTap,
    this.iconSquareSize = 40,
    this.imageBackgroundColor = AppColors.gray,
    this.prefixSpace = 8,
    this.iconSize = 24,
    this.elevation = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListTileWidget(
      onTap: onTap,
      elevation: elevation,
      prefix: ImageBackgroundWidget(
        squareSize: iconSquareSize,
        color: imageBackgroundColor,
        iconSize: iconSize,
        child: icon,
      ),
      prefixSpace: prefixSpace,
      content: Text(label, style: AppTextStyles.bodyMedium.merge(textStyle)),
      suffix: SvgPicture.asset(AppImages.chevonRightSvg),
    );
  }
}

class ColoredSmallCircleWidget extends StatelessWidget {
  final double dimension;
  final Widget child;
  final Color color;
  final void Function()? onTap;
  const ColoredSmallCircleWidget({
    super.key,
    required this.dimension,
    required this.child,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      isCircleShape: true,
      backgroundColor: color,
      child: Container(
        height: dimension,
        width: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class ColoredMarkedSmallCircleWidget extends StatelessWidget {
  final double dimension;
  final Widget child;
  final Color color;
  final void Function()? onTap;
  const ColoredMarkedSmallCircleWidget({
    super.key,
    required this.dimension,
    required this.child,
    this.color = Colors.green,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RawButtonWidget(
      onTap: onTap,
      isCircleShape: true,
      backgroundColor: color,
      child: Container(
        height: dimension,
        width: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class MixedImageWidget extends StatelessWidget {
  final dynamic imageData;
  final BoxFit boxFit;
  final int? cacheHeight;
  final int? cacheWidth;
  final String placeholderAssetRasterImage;
  final Widget Function(
    BuildContext context,
    ImageProvider<Object> imageProvider,
  )?
  imageBuilder;
  const MixedImageWidget({
    super.key,
    required this.imageData,
    this.boxFit = BoxFit.cover,
    this.cacheHeight,
    this.cacheWidth,
    this.imageBuilder,
    this.placeholderAssetRasterImage = AppImages.imagePlaceHolderIconPng,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderImageWidget = Image.asset(
      placeholderAssetRasterImage,
      fit: BoxFit.contain,
    );
    final xfileImageWidget = Image.file(
      (imageData is XFile) ? File((imageData as XFile).path) : File(''),
    );
    final fileImageWidget = Image.file(
      (imageData is File) ? (imageData as File) : File(''),
    );
    final memoryImageWidget = Image.memory(
      (imageData is Uint8List) ? (imageData as Uint8List) : Uint8List(0),
    );
    if (imageData is String) {
      return imageData.isEmpty
          ? imageBuilder == null
                ? Image.asset(placeholderAssetRasterImage, fit: BoxFit.contain)
                : imageBuilder!.call(
                    context,
                    Image.asset(
                      placeholderAssetRasterImage,
                      fit: BoxFit.contain,
                    ).image,
                  )
          : CachedNetworkImage(
              imageUrl: imageData,
              placeholder: (context, url) =>
                  const LoadingImagePlaceholderWidget(),
              errorWidget: (context, url, error) =>
                  const ErrorLoadedIconWidget(),
              imageBuilder: imageBuilder,
              memCacheHeight: cacheHeight,
              memCacheWidth: cacheWidth,
              fit: boxFit,
            );
    }
    if (imageData is XFile) {
      return imageBuilder == null
          ? Image.file(
              imageData.path,
              fit: boxFit,
              cacheHeight: cacheHeight,
              cacheWidth: cacheWidth,
            )
          : imageBuilder!.call(context, xfileImageWidget.image);
    }
    if (imageData is File) {
      return imageBuilder == null
          ? Image.file(
              imageData,
              fit: boxFit,
              cacheHeight: cacheHeight,
              cacheWidth: cacheWidth,
            )
          : imageBuilder!.call(context, fileImageWidget.image);
    }
    if (imageData is Uint8List) {
      return imageBuilder == null
          ? Image.memory(
              imageData,
              fit: boxFit,
              cacheHeight: cacheHeight,
              cacheWidth: cacheWidth,
            )
          : imageBuilder!.call(context, memoryImageWidget.image);
    }
    return imageBuilder == null
        ? placeholderImageWidget
        : imageBuilder!.call(context, placeholderImageWidget.image);
  }
}

class ProfileImageWidget extends StatelessWidget {
  final dynamic imageData;
  final void Function(dynamic imageData)? onImageTap;
  final void Function()? onTakeImageButtonTap;
  final bool showUploadImageButton;
  final bool isLoading;
  final double size;
  final String placeholderAssetRasterImage;
  const ProfileImageWidget({
    super.key,
    this.imageData,
    this.onImageTap,
    this.onTakeImageButtonTap,
    this.showUploadImageButton = true,
    this.isLoading = false,
    this.size = 120,
    this.placeholderAssetRasterImage = AppImages.userPng,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MixedImageWidget(
                      imageData: imageData,
                      placeholderAssetRasterImage: placeholderAssetRasterImage,
                      imageBuilder: (context, imageProvider) => RawButtonWidget(
                        borderRadiusValue: size / 2,
                        onTap: ((onImageTap == null) || imageData == null)
                            ? null
                            : () => onImageTap!(imageData),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Center(child: Loader()),
                      ),
                    ),
                ],
              ),
            ),
            if (showUploadImageButton) const VerticalGap(12),
          ],
        ),
        if (showUploadImageButton)
          Positioned(
            bottom: -6,
            child: isLoading
                ? LoadingPlaceholderWidget(
                    child: ColoredSmallCircleWidget(
                      onTap: onTakeImageButtonTap,
                      dimension: 34,
                      color: AppColors.primary,
                      child: SvgPicture.asset(AppImages.cameraSvg),
                    ),
                  )
                : ColoredSmallCircleWidget(
                    onTap: onTakeImageButtonTap,
                    dimension: 34,
                    color: AppColors.primary,
                    child: SvgPicture.asset(AppImages.cameraSvg),
                  ),
          ),
      ],
    );
  }
}

class StoreProfileImageWidget extends StatelessWidget {
  final dynamic imageData;
  final void Function(dynamic imageData)? onImageTap;
  final void Function()? onTakeImageButtonTap;
  final bool showUploadImageButton;
  final bool isLoading;
  final double size;
  final String placeholderAssetRasterImage;
  const StoreProfileImageWidget({
    super.key,
    this.imageData,
    this.onImageTap,
    this.onTakeImageButtonTap,
    this.showUploadImageButton = true,
    this.isLoading = false,
    this.size = 120,
    this.placeholderAssetRasterImage = AppImages.userPng,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MixedImageWidget(
                      imageData: imageData,
                      placeholderAssetRasterImage: placeholderAssetRasterImage,
                      imageBuilder: (context, imageProvider) => RawButtonWidget(
                        borderRadiusValue: size / 2,
                        onTap: ((onImageTap == null) || imageData == null)
                            ? null
                            : () => onImageTap!(imageData),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: Colors.transparent,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bodyTextColor,
                            width: 2,
                          ),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
            if (showUploadImageButton) const VerticalGap(12),
          ],
        ),
        if (showUploadImageButton)
          Positioned(
            right: -5,
            bottom: 10,
            child: isLoading
                ? LoadingPlaceholderWidget(
                    child: ColoredSmallCircleWidget(
                      onTap: onTakeImageButtonTap,
                      dimension: 34,
                      color: AppColors.primary,
                      child: SvgPicture.asset(AppImages.cameraSvg),
                    ),
                  )
                : ColoredSmallCircleWidget(
                    onTap: onTakeImageButtonTap,
                    dimension: 34,
                    color: AppColors.primary,
                    child: SvgPicture.asset(AppImages.cameraSvg),
                  ),
          ),
      ],
    );
  }
}

class VerticalLabelValueWidget extends StatelessWidget {
  final String label;
  final TextStyle? labelTextStyle;
  final String value;
  final TextStyle? valueTextStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final int? valueMaxLines;
  final TextAlign? valueTextAlign;
  const VerticalLabelValueWidget({
    super.key,
    required this.label,
    this.labelTextStyle,
    required this.value,
    this.valueTextStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.valueMaxLines,
    this.valueTextAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium
              .copyWith(fontSize: 10)
              .merge(labelTextStyle),
        ),
        const VerticalGap(4),
        Text(
          value,
          textAlign: valueTextAlign,
          maxLines: valueMaxLines,
          overflow: valueMaxLines == null ? null : TextOverflow.ellipsis,
          style: AppTextStyles.body
              .copyWith(fontSize: 10)
              .merge(valueTextStyle),
        ),
      ],
    );
  }
}

class LabelValueRowWidget extends StatelessWidget {
  final String label;
  final TextStyle? labelTextStyle;
  final String valueText;
  final TextStyle? valueTextStyle;
  final Widget? value;
  const LabelValueRowWidget({
    super.key,
    required this.label,
    this.valueText = '',
    this.value,
    this.labelTextStyle,
    this.valueTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(color: AppColors.secondary).merge(labelTextStyle),
          ),
          TextSpan(
            text: ':',
            style: TextStyle(color: AppColors.secondary).merge(labelTextStyle),
          ),
          WidgetSpan(child: const HorizontalGap(5)),
          value != null
              ? WidgetSpan(
                  child: value!,
                  alignment: PlaceholderAlignment.middle,
                )
              : TextSpan(text: valueText, style: valueTextStyle),
        ],
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class PieChartWidget extends StatelessWidget {
  final void Function(int touchedIndex)? onTouch;
  final FlBorderData? border;
  final double sectionSpace;
  final double? centerSpaceRadius;
  final double? startDegreeOffset;
  final List<PieChartSectionData>? sections;
  const PieChartWidget({
    super.key,
    this.onTouch,
    this.border,
    this.sectionSpace = 0,
    this.centerSpaceRadius,
    this.sections,
    this.startDegreeOffset,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: onTouch != null,
          touchCallback: onTouch == null
              ? null
              : (FlTouchEvent event, pieTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    onTouch?.call(-1);
                    return;
                  }
                  onTouch?.call(
                    pieTouchResponse.touchedSection!.touchedSectionIndex,
                  );
                },
        ),
        borderData: border,
        sectionsSpace: sectionSpace,
        centerSpaceRadius: centerSpaceRadius,
        sections: sections,
        startDegreeOffset: startDegreeOffset,
      ),
    );
  }
}

class ChartColorLabelWidget extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle? labelStyle;
  const ChartColorLabelWidget({
    super.key,
    required this.color,
    required this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 8,
          child: ColoredBox(
            color: color,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
        const HorizontalGap(4),
        Text(label, style: AppTextStyles.bodySmall.merge(labelStyle)),
      ],
    );
  }
}

class StatusChipWidget extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final Color? color;
  final String text;
  final TextStyle? textStyle;
  final Widget? child;
  const StatusChipWidget({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.color,
    this.text = '',
    this.textStyle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      elevation: 0,
      borderRadius: 4,
      padding: EdgeInsetsGeometry.symmetric(horizontal: 6, vertical: 3),
      backgroundColor:
          (color?.withValues(alpha: 0.1) ?? backgroundColor) ?? Colors.white,
      child: text.isEmpty
          ? (child ?? SizedBox.shrink())
          : Text(
              text,
              style: AppTextStyles.bodySmallMedium
                  .copyWith(color: (color ?? textColor))
                  .merge(textStyle),
            ),
    );
  }
}

class SwitchWidget extends StatelessWidget {
  final bool value;
  final Function(bool)? onChanged;
  const SwitchWidget({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      width: 55,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.success,
        inactiveThumbColor: AppColors.error,
        inactiveTrackColor: AppColors.error.withValues(alpha: 0.3),
      ),
    );
  }
}

class LabelValueFullRowWidget extends StatelessWidget {
  final String label;
  final TextStyle? labelTextStyle;
  final String valueText;
  final TextStyle? valueTextStyle;
  final Widget? valueWidget;
  const LabelValueFullRowWidget({
    super.key,
    required this.label,
    this.valueText = '',
    this.valueWidget,
    this.labelTextStyle,
    this.valueTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body
              .copyWith(color: AppColors.secondaryText)
              .merge(labelTextStyle),
        ),
        const HorizontalGap(5),
        Expanded(
          child: valueText.isEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [valueWidget ?? SizedBox.shrink()],
                )
              : Text(
                  valueText,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyMedium.merge(valueTextStyle),
                ),
        ),
      ],
    );
  }
}
