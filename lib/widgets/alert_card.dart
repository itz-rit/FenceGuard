import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AlertCard extends StatelessWidget {
  final String deviceId;
  final String message;
  final String severity;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const AlertCard({
    super.key,
    required this.deviceId,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.onTap,
    this.onAcknowledge,
  });

  Color _getSeverityColor() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppConstants.statusCritical;
      case 'warning':
        return AppConstants.statusWarning;
      default:
        return AppConstants.statusSafe;
    }
  }

  IconData _getSeverityIcon() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.report_problem;
      default:
        return Icons.info;
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Severity Indicator
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),

              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSeverityIcon(),
                  color: color,
                  size: AppConstants.iconMedium,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppConstants.fontSizeMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Device: $deviceId • ${_getTimeAgo()}',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Severity Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: AppConstants.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Acknowledge Button (if provided)
              if (onAcknowledge != null) ...[
                const SizedBox(width: AppConstants.paddingSmall),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppConstants.primaryColor,
                  onPressed: onAcknowledge,
                  tooltip: 'Acknowledge',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}