import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';

class ModePanel extends StatelessWidget {
  const ModePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings_input_component, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Wire Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (provider.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: provider.wireMode == '2W' 
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: provider.wireMode == '2W' 
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                        child: Text(
                          provider.wireMode.isNotEmpty 
                              ? provider.wireMode 
                              : 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: provider.wireMode == '2W' 
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Mode description
                if (provider.wireMode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _getModeDescription(provider.wireMode),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Mode switching buttons
                if (provider.isConnected) ...[
                  const Text(
                    'Switch Mode:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.wireMode == '2W' 
                              ? null 
                              : () => _setWireMode(context, provider, '2W'),
                          icon: const Icon(Icons.looks_two, size: 18),
                          label: const Text('2-Wire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.wireMode == '2W' 
                                ? Colors.blue.shade100
                                : null,
                            foregroundColor: provider.wireMode == '2W' 
                                ? Colors.blue.shade700
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.wireMode == '4W' 
                              ? null 
                              : () => _setWireMode(context, provider, '4W'),
                          icon: const Icon(Icons.looks_4, size: 18),
                          label: const Text('4-Wire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.wireMode == '4W' 
                                ? Colors.green.shade100
                                : null,
                            foregroundColor: provider.wireMode == '4W' 
                                ? Colors.green.shade700
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connect to device to switch wire mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
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

  String _getModeDescription(String mode) {
    switch (mode) {
      case '2W':
        return '2-Wire mode: Uses the same wires for current sourcing and voltage sensing. Simpler setup but less accurate for high current measurements.';
      case '4W':
        return '4-Wire mode: Uses separate wires for current sourcing and voltage sensing. More accurate measurements, especially at high currents.';
      default:
        return 'Wire mode determines how the power supply measures voltage and current.';
    }
  }

  Future<void> _setWireMode(BuildContext context, DeviceProvider provider, String mode) async {
    try {
      final success = await provider.setWireMode(mode);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Wire mode set to $mode successfully'
                  : 'Failed to set wire mode to $mode',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting wire mode: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
