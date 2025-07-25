import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import '../network_test.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({super.key});

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<DeviceProvider>();
    _ipController.text = provider.ipAddress;
    _portController.text = provider.port.toString();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

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
                Text(
                  'Connection Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    // IP Address field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _ipController,
                        enabled: !provider.isConnected,
                        decoration: const InputDecoration(
                          labelText: 'IP Address / Hostname',
                          hintText: 'spd1305x',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            provider.setConnectionSettings(
                              value,
                              int.tryParse(_portController.text) ?? 5025,
                            );
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Port field
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        enabled: !provider.isConnected,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '5025',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final port = int.tryParse(value);
                          if (port != null) {
                            provider.setConnectionSettings(
                              _ipController.text,
                              port,
                            );
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Connect/Disconnect button
                    ElevatedButton.icon(
                      onPressed: provider.isConnected
                          ? () => provider.disconnect()
                          : () => _connect(provider),
                      icon: Icon(
                        provider.isConnected
                            ? Icons.link_off
                            : Icons.link,
                      ),
                      label: Text(
                        provider.isConnected ? 'Disconnect' : 'Connect',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isConnected
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Test Connection button
                    ElevatedButton.icon(
                      onPressed: !provider.isConnected
                          ? () => _testConnection()
                          : null,
                      icon: const Icon(Icons.network_check),
                      label: const Text('Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Connection status
                Row(
                  children: [
                    Icon(
                      provider.isConnected
                          ? Icons.check_circle
                          : Icons.error,
                      color: provider.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${provider.connectionStatus}',
                      style: TextStyle(
                        color: provider.isConnected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Device info (when connected)
                if (provider.isConnected && provider.deviceInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Device: ${provider.deviceInfo}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _connect(DeviceProvider provider) async {
    final success = await provider.connect();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${provider.connectionStatus}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final provider = context.read<DeviceProvider>();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );
    
    try {
      await NetworkTest.testConnection(provider.ipAddress, provider.port);
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    }
  }
}
