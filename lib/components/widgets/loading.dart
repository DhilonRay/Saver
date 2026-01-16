
import 'package:flutter/material.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/ui_components.dart';
import 'package:shimmer/shimmer.dart';

class LoadingButtonWidget extends StatelessWidget {
  const LoadingButtonWidget({
    super.key,
    required this.child,
    this.minHeight = 44,
    this.minimumSize,
    this.borderRadiusValue,
  });

  final Widget child;
  final double minHeight;
  final Size? minimumSize;
  final double? borderRadiusValue;

  @override
  Widget build(BuildContext context) {
    return LoadingPlaceholderWidget(
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: minimumSize ?? Size(30, minHeight),
          shape: borderRadiusValue != null
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadiusValue!),
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

class LoadingIconButtonWidget extends StatelessWidget {
  const LoadingIconButtonWidget({
    super.key,
    required this.icon,
    this.minHeight = 48,
    this.minimumSize,
    this.borderRadiusValue,
    this.padding,
  });

  final Widget icon;
  final double minHeight;
  final Size? minimumSize;
  final double? borderRadiusValue;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LoadingPlaceholderWidget(
      child: IconButton.filled(
        onPressed: () {},
        style: IconButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10),
          ),
          elevation: 0,
          minimumSize: Size(48, minHeight),
        ),
        icon: icon,
      ),
    );
  }
}

class LoadingOutlinedButtonWidget extends StatelessWidget {
  const LoadingOutlinedButtonWidget({
    super.key,
    required this.child,
    this.minHeight = 44,
    this.minimumSize,
  });

  final Widget child;
  final double minHeight;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    return LoadingPlaceholderWidget(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize ?? Size(30, minHeight),
        ),
        child: child,
      ),
    );
  }
}

class DropdownButtonFormFieldLoadingWidget extends StatelessWidget {
  const DropdownButtonFormFieldLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingPlaceholderWidget(
      child: Container(
        height: 60,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: AppUIComponents.borderRadius10,
          border: Border.all(width: 2),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 125, child: LoadingTextWidget()),
              Spacer(),
              Icon(Icons.keyboard_arrow_down, color: AppColors.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingTextWidget extends StatelessWidget {
  final double height;
  const LoadingTextWidget({super.key, this.height = 15});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}

class LoadingPlaceholderWidget extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  const LoadingPlaceholderWidget({
    super.key,
    required this.child,
    this.baseColor = AppColors.shimmerDark,
    this.highlightColor = AppColors.shimmerLight,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class LoadingImagePlaceholderWidget extends StatelessWidget {
  const LoadingImagePlaceholderWidget({
    super.key,
    this.height,
    this.width,
    this.loadingAssetImageLocation = AppImages.imagePlaceHolderIconPng,
    this.baseColor = AppColors.shimmerDark,
    this.highlightColor = AppColors.shimmerLight,
  });
  final double? height;
  final double? width;
  final String loadingAssetImageLocation;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: LoadingPlaceholderWidget(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Image.asset(loadingAssetImageLocation),
      ),
    );
  }
}
