import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/ui_constants.dart';

class VerticalGap extends StatelessWidget {
  const VerticalGap(this.height, {super.key});
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class HorizontalGap extends StatelessWidget {
  const HorizontalGap(this.width, {super.key});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}

class SidePaddedWidget extends StatelessWidget {
  const SidePaddedWidget({
    required this.child,
    super.key,
    this.padding = AppUIConstants.sidePadding,
  });
  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
  }
}

class ScreenBottomGap extends StatelessWidget {
  const ScreenBottomGap({
    super.key,
    this.height,
    this.includeViewPadding = true,
  });
  final bool includeViewPadding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return VerticalGap(
      (height ?? 0) +
          (includeViewPadding ? context.mediaQueryViewPadding.bottom : 0),
    );
  }
}
