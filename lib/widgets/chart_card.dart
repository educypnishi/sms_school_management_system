import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../theme/app_theme.dart';

/// A widget to display a chart card on the dashboard
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chartWidget;
  final List<Widget>? actions;
  final double height;
  final VoidCallback? onTap;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chartWidget,
    this.actions,
    this.height = 300,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.lightTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...[
                    ...actions!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Chart
              SizedBox(
                height: height,
                child: chartWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget to display a simple bar chart
class SimpleBarChart extends StatelessWidget {
  final List<DataPoint> dataPoints;
  final bool showLabels;
  final bool showValues;
  final double maxValue;
  final double barWidth;
  final double spacing;

  SimpleBarChart({
    super.key,
    required this.dataPoints,
    this.showLabels = true,
    this.showValues = true,
    double? maxValue,
    this.barWidth = 30,
    this.spacing = 16,
  }) : maxValue = maxValue ?? _calculateMaxValue(dataPoints);

  static double _calculateMaxValue(List<DataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 100;
    return dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: max(constraints.maxWidth, (barWidth + spacing) * dataPoints.length),
            padding: const EdgeInsets.only(bottom: 24, top: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dataPoints.map((point) {
                final barHeight = (point.value / maxValue) * (constraints.maxHeight - 80);
                
                return Container(
                  width: barWidth,
                  margin: EdgeInsets.only(right: spacing),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showValues) ...[
                        Text(
                          point.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: point.color ?? AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 8),
                        Text(
                          point.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightTextColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// A widget to display a simple pie chart
class SimplePieChart extends StatelessWidget {
  final List<DataPoint> dataPoints;
  final bool showLabels;
  final bool showValues;
  final double size;

  const SimplePieChart({
    super.key,
    required this.dataPoints,
    this.showLabels = true,
    this.showValues = true,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Placeholder for pie chart (in a real app, use a charting library)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'Pie Chart\n(Placeholder)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
        ),
        
        if (showLabels) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: dataPoints.map((point) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: point.color ?? AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${point.label}${showValues ? ': ${point.value.toStringAsFixed(1)}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// A widget to display a simple line chart
class SimpleLineChart extends StatelessWidget {
  final List<DataPoint> dataPoints;
  final bool showLabels;
  final bool showValues;
  final double maxValue;

  SimpleLineChart({
    super.key,
    required this.dataPoints,
    this.showLabels = true,
    this.showValues = true,
    double? maxValue,
  }) : maxValue = maxValue ?? _calculateMaxValue(dataPoints);

  static double _calculateMaxValue(List<DataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 100;
    return dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'Line Chart\n(Placeholder)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

double max(double a, double b) => a > b ? a : b;
