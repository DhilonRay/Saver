import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:saver/components/constants/ui_constants.dart';

class AppUIComponents {
  static const radius10 = Radius.circular(AppUIConstants.borderRadius10);
  static const radius20 = Radius.circular(AppUIConstants.borderRadius20);
  static const borderRadius2 = BorderRadius.all(Radius.circular(2));
  static const borderRadius4 = BorderRadius.all(Radius.circular(4));
  static const borderRadius8 = BorderRadius.all(Radius.circular(8));
  static const borderRadius10 = BorderRadius.all(radius10);
  static const borderRadius20 = BorderRadius.all(radius20);

  static PieChartSectionData pieChartSectionData({
    Color? color,
    double? value,
    bool showTitle = false,
    double? radius,
    TextStyle? textStyle,
    String? title,
  }) => PieChartSectionData(  
    color: color,
    value: value,
    title: title,
    showTitle: showTitle,
    radius: radius,
    titleStyle: textStyle,
  );
}
