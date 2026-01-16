import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/widgets/space.dart';


/// Model for chart data
class ChartDataModel {
  final String label;
  final double value;
  final Color color;

  ChartDataModel({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Reusable Pie Chart Widget
class ReusablePieChart extends StatelessWidget {
  final List<ChartDataModel> data;
  final double? centerValue;
  final String? centerLabel;
  final double radius;
  final double centerSpaceRadius;
  final bool showLegend;
  final String? title;

  const ReusablePieChart({
    super.key,
    required this.data,
    this.centerValue,
    this.centerLabel,
    this.radius = 80,
    this.centerSpaceRadius = 50,
    this.showLegend = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // More conservative responsive sizing to prevent overflow
    final responsiveRadius = isMobile ? 50.0 : (radius * 0.9);
    final responsiveCenterSpaceRadius =
        isMobile ? 30.0 : (centerSpaceRadius * 0.9);
    final responsivePadding = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style:
                  isMobile
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLargeSemibold,
            ),
            VerticalGap(isMobile ? 12 : 16),
          ],
          // Constrained container to prevent overflow
          Container(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 220 : 300,
              maxWidth: double.infinity,
            ),
            child:
                isMobile && showLegend
                    ? Column(
                      children: [
                        // Pie Chart section for mobile
                        SizedBox(
                          height: responsiveRadius * 2 + 20,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius:
                                        responsiveCenterSpaceRadius,
                                    sections:
                                        data.asMap().entries.map((entry) {
                                          final isLargest =
                                              entry.value.value ==
                                              data
                                                  .map((e) => e.value)
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  );
                                          return PieChartSectionData(
                                            color: entry.value.color,
                                            value: entry.value.value,
                                            title: '',
                                            radius:
                                                isLargest
                                                    ? responsiveRadius + 3
                                                    : responsiveRadius,
                                            titleStyle: const TextStyle(
                                              fontSize: 0,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                // Center Content
                                if (centerValue != null) ...[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${centerValue!.toInt()}%',
                                        style: AppTextStyles.extraLargeBodyLarge
                                            .copyWith(
                                              fontSize: isMobile ? 14 : 20,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      if (centerLabel != null)
                                        Text(
                                          centerLabel!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.secondaryText,
                                                fontSize: isMobile ? 8 : 12,
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const VerticalGap(12),
                        // Legend below for mobile
                        if (showLegend)
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  data.map((item) {
                                    return SizedBox(
                                      width: (screenWidth - 80) / 2,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: item.color,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const HorizontalGap(4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.label,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(fontSize: 9),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '\$${item.value.toInt()}',
                                                  style: AppTextStyles
                                                      .bodySmallSemibold
                                                      .copyWith(fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    )
                    : Row(
                      children: [
                        // Pie Chart
                        Expanded(
                          flex: showLegend ? 2 : 1,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius:
                                        responsiveCenterSpaceRadius,
                                    sections:
                                        data.asMap().entries.map((entry) {
                                          final isLargest =
                                              entry.value.value ==
                                              data
                                                  .map((e) => e.value)
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  );
                                          return PieChartSectionData(
                                            color: entry.value.color,
                                            value: entry.value.value,
                                            title: '',
                                            radius:
                                                isLargest
                                                    ? responsiveRadius + 5
                                                    : responsiveRadius,
                                            titleStyle: const TextStyle(
                                              fontSize: 0,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                // Center Content
                                if (centerValue != null) ...[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${centerValue!.toInt()}%',
                                        style: AppTextStyles.extraLargeBodyLarge
                                            .copyWith(
                                              fontSize: isMobile ? 16 : 20,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      if (centerLabel != null)
                                        Text(
                                          centerLabel!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.secondaryText,
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Legend
                        if (showLegend) ...[
                          const HorizontalGap(16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  data.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: item.color,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const HorizontalGap(8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.label,
                                                  style:
                                                      AppTextStyles.bodySmall,
                                                ),
                                                Text(
                                                  '\$${item.value.toInt()}',
                                                  style:
                                                      AppTextStyles
                                                          .bodySmallSemibold,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Bar Chart Widget
class ReusableBarChart extends StatelessWidget {
  final List<ChartDataModel> data;
  final String? title;
  final double maxY;
  final Color? primaryColor;
  final bool showGrid;
  final String xAxisLabel;
  final String yAxisLabel;

  const ReusableBarChart({
    super.key,
    required this.data,
    this.title,
    required this.maxY,
    this.primaryColor,
    this.showGrid = true,
    this.xAxisLabel = '',
    this.yAxisLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final responsivePadding = isMobile ? 12.0 : 16.0;
    final chartHeight = isMobile ? 150.0 : 200.0;
    final barWidth = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style:
                  isMobile
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLargeSemibold,
            ),
            VerticalGap(isMobile ? 12 : 16),
          ],
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 30 : 40,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 25 : 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.length) {
                          return Text(
                            data[value.toInt()].label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    data.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: entry.value.color,
                            width: barWidth,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats Card Widget
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Widget? icon;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final responsivePadding = isMobile ? 12.0 : 16.0;
    final valueFontSize = isMobile ? 20.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(responsivePadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ),
                if (icon != null)
                  Transform.scale(scale: isMobile ? 0.8 : 1.0, child: icon!),
              ],
            ),
            VerticalGap(isMobile ? 6 : 8),
            Text(
              value,
              style: AppTextStyles.extraLargeBodyLarge.copyWith(
                color: valueColor ?? AppColors.primary,
                fontSize: valueFontSize,
              ),
            ),
            if (subtitle != null) ...[
              VerticalGap(isMobile ? 3 : 4),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress Card Widget
class ProgressCard extends StatelessWidget {
  final String title;
  final double progress; // 0.0 to 1.0
  final String progressText;
  final Color? progressColor;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressText,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final responsivePadding = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                isMobile
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.bodyLargeSemibold,
          ),
          VerticalGap(isMobile ? 8 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progressText,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.bodySemibold.copyWith(
                  color: progressColor ?? AppColors.primary,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
          VerticalGap(isMobile ? 6 : 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? AppColors.primary,
            ),
            borderRadius: BorderRadius.circular(4),
            minHeight: isMobile ? 5 : 6,
          ),
        ],
      ),
    );
  }
}
