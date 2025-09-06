import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../theme/app_theme.dart';

/// A widget to display a metric card on the dashboard
class MetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.metric,
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
              // Icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: metric.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      metric.icon,
                      color: metric.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metric.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Value
              Text(
                metric.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Subtitle if available
              if (metric.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  metric.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
              
              // Change percentage if available
              if (metric.changePercentage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      metric.isPositiveChange
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: metric.isPositiveChange
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${metric.changePercentage!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: metric.isPositiveChange
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'vs last period',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
