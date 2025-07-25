import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';

class MeasurementPanel extends StatelessWidget {
  const MeasurementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel 1 Measurements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                
                // Voltage measurement
                _buildMeasurementRow(
                  context,
                  'Voltage',
                  provider.ch1Voltage,
                  'V',
                  Icons.electrical_services,
                  Colors.blue,
                ),
                
                const SizedBox(height: 8),
                
                // Current measurement
                _buildMeasurementRow(
                  context,
                  'Current',
                  provider.ch1Current,
                  'A',
                  Icons.flash_on,
                  Colors.orange,
                ),
                
                const SizedBox(height: 8),
                
                // Power measurement
                _buildMeasurementRow(
                  context,
                  'Power',
                  provider.ch1Power,
                  'W',
                  Icons.power,
                  Colors.red,
                ),
                
                const SizedBox(height: 12),
                
                // Mode indicator
                if (provider.systemStatus != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: provider.systemStatus!.isCCMode
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: provider.systemStatus!.isCCMode
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.systemStatus!.isCCMode
                              ? Icons.flash_on
                              : Icons.electrical_services,
                          size: 16,
                          color: provider.systemStatus!.isCCMode
                              ? Colors.orange
                              : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.systemStatus!.modeString} Mode',
                          style: TextStyle(
                            color: provider.systemStatus!.isCCMode
                                ? Colors.orange
                                : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementRow(
    BuildContext context,
    String label,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(3)} $unit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
