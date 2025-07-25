import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final _voltageController = TextEditingController();
  final _currentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final provider = context.read<DeviceProvider>();
    _voltageController.text = provider.ch1VoltageSet.toStringAsFixed(3);
    _currentController.text = provider.ch1CurrentSet.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _voltageController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Channel 1 Controls',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      // Refresh button
                      ElevatedButton.icon(
                        onPressed: provider.isConnected
                            ? () => _refreshValues(provider)
                            : null,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Output control
                  _buildOutputControl(provider),
                  
                  const SizedBox(height: 16),
                  
                  // Voltage control
                  _buildVoltageControl(provider),
                  
                  const SizedBox(height: 12),
                  
                  // Current control
                  _buildCurrentControl(provider),
                  
                  const SizedBox(height: 16),
                  
                  // Quick preset buttons
                  _buildPresetButtons(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutputControl(DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: provider.ch1OutputEnabled 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: provider.ch1OutputEnabled 
              ? Colors.green
              : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.ch1OutputEnabled ? Icons.power : Icons.power_off,
            color: provider.ch1OutputEnabled ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Output',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  provider.ch1OutputEnabled ? 'ON' : 'OFF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: provider.ch1OutputEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.ch1OutputEnabled,
            onChanged: provider.isConnected
                ? (value) => _setOutput(provider, value)
                : null,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageControl(DeviceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.electrical_services, color: Colors.blue, size: 18),
            const SizedBox(width: 6),
            Text(
              'Voltage Setting',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _voltageController,
                enabled: provider.isConnected,
                decoration: const InputDecoration(
                  labelText: 'Voltage (V)',
                  suffixText: 'V',
                  border: OutlineInputBorder(),
                  hintText: '0.000',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onSubmitted: provider.isConnected
                    ? (value) => _setVoltage(provider)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: provider.isConnected
                  ? () => _setVoltage(provider)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(50, 32),
              ),
              child: const Text('Set', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Current: ${provider.ch1VoltageSet.toStringAsFixed(3)} V',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentControl(DeviceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            Text(
              'Current Setting',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _currentController,
                enabled: provider.isConnected,
                decoration: const InputDecoration(
                  labelText: 'Current (A)',
                  suffixText: 'A',
                  border: OutlineInputBorder(),
                  hintText: '0.000',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onSubmitted: provider.isConnected
                    ? (value) => _setCurrent(provider)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: provider.isConnected
                  ? () => _setCurrent(provider)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(50, 32),
              ),
              child: const Text('Set', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Current: ${provider.ch1CurrentSet.toStringAsFixed(3)} A',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButtons(DeviceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPresetButton(provider, '3.3V/1A', 3.3, 1.0),
            _buildPresetButton(provider, '5V/2A', 5.0, 2.0),
            _buildPresetButton(provider, '12V/1A', 12.0, 1.0),
            _buildPresetButton(provider, '24V/0.5A', 24.0, 0.5),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(DeviceProvider provider, String label, double voltage, double current) {
    return ElevatedButton(
      onPressed: provider.isConnected
          ? () => _setPreset(provider, voltage, current)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(60, 28),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Future<void> _setOutput(DeviceProvider provider, bool enabled) async {
    final success = await provider.setOutput(enabled);
    if (!success && mounted) {
      _showErrorSnackBar('Failed to set output state');
    }
  }

  Future<void> _setVoltage(DeviceProvider provider) async {
    final voltage = double.tryParse(_voltageController.text);
    if (voltage == null) {
      _showErrorSnackBar('Invalid voltage value');
      return;
    }
    
    final success = await provider.setVoltage(voltage);
    if (!success && mounted) {
      _showErrorSnackBar('Failed to set voltage');
    }
  }

  Future<void> _setCurrent(DeviceProvider provider) async {
    final current = double.tryParse(_currentController.text);
    if (current == null) {
      _showErrorSnackBar('Invalid current value');
      return;
    }
    
    final success = await provider.setCurrent(current);
    if (!success && mounted) {
      _showErrorSnackBar('Failed to set current');
    }
  }

  Future<void> _setPreset(DeviceProvider provider, double voltage, double current) async {
    _voltageController.text = voltage.toStringAsFixed(1);
    _currentController.text = current.toStringAsFixed(1);
    
    final voltageSuccess = await provider.setVoltage(voltage);
    final currentSuccess = await provider.setCurrent(current);
    
    if ((!voltageSuccess || !currentSuccess) && mounted) {
      _showErrorSnackBar('Failed to set preset values');
    }
  }

  Future<void> _refreshValues(DeviceProvider provider) async {
    final success = await provider.refreshSettings();
    if (success) {
      // Update the input fields with the refreshed values
      _voltageController.text = provider.ch1VoltageSet.toStringAsFixed(3);
      _currentController.text = provider.ch1CurrentSet.toStringAsFixed(3);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Values refreshed from device'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh values'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
