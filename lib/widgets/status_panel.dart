import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

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
                  'Device Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                
                if (provider.isConnected) ...[
                  // System status indicators
                  if (provider.systemStatus != null) ...[
                    _buildStatusGrid(context, provider),
                    const SizedBox(height: 12),
                  ],
                  
                  // Device information
                  _buildDeviceInfo(context, provider),
                  
                  // Error information
                  if (provider.lastError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildErrorInfo(context, provider),
                  ],
                ] else ...[
                  // Not connected message
                  _buildNotConnectedMessage(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusGrid(BuildContext context, DeviceProvider provider) {
    final status = provider.systemStatus!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Output',
                status.outputString,
                status.isOutputOn ? Colors.green : Colors.red,
                status.isOutputOn ? Icons.power : Icons.power_off,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Mode',
                status.modeString,
                status.isCCMode ? Colors.orange : Colors.blue,
                status.isCCMode ? Icons.flash_on : Icons.electrical_services,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Wire Mode',
                status.wireString,
                Colors.purple,
                Icons.cable,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusIndicator(
                context,
                'Timer',
                status.timerString,
                status.isTimerOn ? Colors.green : Colors.grey,
                status.isTimerOn ? Icons.timer : Icons.timer_off,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatusIndicator(
          context,
          'Display',
          status.displayString,
          Colors.indigo,
          status.isWaveformDisplay ? Icons.show_chart : Icons.monitor,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context, DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Text(
                'Device Information',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          if (provider.deviceInfo.isNotEmpty) ...[
            _buildInfoRow('Device', provider.deviceInfo),
          ],
          
          if (provider.systemVersion.isNotEmpty) ...[
            _buildInfoRow('Version', provider.systemVersion),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorInfo(BuildContext context, DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(
                'Last Error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            provider.lastError,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.link_off,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Not Connected',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect to the SPD1305X to view device status',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
