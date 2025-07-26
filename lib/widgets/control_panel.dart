import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import '../services/preset_service.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final _voltageController = TextEditingController();
  final _currentController = TextEditingController();
  final PresetService _presetService = PresetService();
  bool _presetsLoaded = false;
  String? _selectedPresetId;
  
  @override
  void initState() {
    super.initState();
    final provider = context.read<DeviceProvider>();
    _voltageController.text = provider.ch1VoltageSet.toStringAsFixed(3);
    _currentController.text = provider.ch1CurrentSet.toStringAsFixed(3);
    _initializePresets();
  }

  Future<void> _initializePresets() async {
    await _presetService.initialize();
    setState(() {
      _presetsLoaded = true;
    });
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
                  
                  // Preset system
                  _buildPresetSystem(provider),
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

  Widget _buildPresetSystem(DeviceProvider provider) {
    if (!_presetsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Presets',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddPresetDialog(provider),
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Add Custom Preset',
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // All presets (no categories)
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _presetService.presets.map((preset) => _buildPresetChip(preset, provider)).toList(),
        ),
        
        // Instructions for removing presets
        if (_presetService.presets.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Long-press any preset to edit or remove',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetChip(Preset preset, DeviceProvider provider) {
    final isSelected = _selectedPresetId == preset.id;
    
    return GestureDetector(
      onLongPress: () => _showPresetOptions(preset, provider),
      child: FilterChip(
        selected: isSelected,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text(
          preset.name,
          style: const TextStyle(fontSize: 10),
        ),
        onSelected: (selected) {
          if (selected) {
            _applyPreset(preset, provider);
          }
        },
        tooltip: preset.description,
      ),
    );
  }

  Future<void> _applyPreset(Preset preset, DeviceProvider provider) async {
    if (!provider.isConnected) {
      _showErrorSnackBar('Connect to device first');
      return;
    }

    setState(() {
      _selectedPresetId = preset.id;
    });

    _voltageController.text = preset.voltage.toStringAsFixed(3);
    _currentController.text = preset.current.toStringAsFixed(3);

    try {
      final voltageSuccess = await provider.setVoltage(preset.voltage);
      final currentSuccess = await provider.setCurrent(preset.current);
      
      if (voltageSuccess && currentSuccess) {
        _showSuccessSnackBar('Applied preset: ${preset.name}');
      } else {
        _showErrorSnackBar('Failed to apply preset completely');
      }
    } catch (e) {
      _showErrorSnackBar('Error applying preset: $e');
    }

    // Clear selection after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _selectedPresetId = null;
        });
      }
    });
  }

  void _showPresetOptions(Preset preset, DeviceProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Preset'),
              onTap: () {
                Navigator.pop(context);
                _showEditPresetDialog(preset, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Preset'),
              onTap: () {
                Navigator.pop(context);
                _deletePreset(preset);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPresetDialog(DeviceProvider provider) {
    _showPresetDialog(provider, 'Add Custom Preset');
  }

  void _showEditPresetDialog(Preset preset, DeviceProvider provider) {
    _showPresetDialog(provider, 'Edit Preset', existingPreset: preset);
  }

  void _showPresetDialog(DeviceProvider provider, String title, {Preset? existingPreset}) {
    final nameController = TextEditingController(text: existingPreset?.name ?? '');
    final voltageController = TextEditingController(
      text: existingPreset?.voltage.toString() ?? _voltageController.text,
    );
    final currentController = TextEditingController(
      text: existingPreset?.current.toString() ?? _currentController.text,
    );
    final descriptionController = TextEditingController(
      text: existingPreset?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Preset Name',
                  hintText: 'e.g., My Custom Preset',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: voltageController,
                decoration: const InputDecoration(
                  labelText: 'Voltage (V)',
                  hintText: '0.0 - 30.0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentController,
                decoration: const InputDecoration(
                  labelText: 'Current (A)',
                  hintText: '0.0 - 5.0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _savePreset(
              context,
              nameController.text,
              voltageController.text,
              currentController.text,
              descriptionController.text,
              existingPreset,
            ),
            child: Text(existingPreset == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreset(
    BuildContext context,
    String name,
    String voltageText,
    String currentText,
    String description,
    Preset? existingPreset,
  ) async {
    if (name.trim().isEmpty) {
      _showErrorSnackBar('Please enter a preset name');
      return;
    }

    final voltage = double.tryParse(voltageText);
    final current = double.tryParse(currentText);

    if (voltage == null || voltage < 0 || voltage > 30) {
      _showErrorSnackBar('Please enter a valid voltage (0-30V)');
      return;
    }

    if (current == null || current < 0 || current > 5) {
      _showErrorSnackBar('Please enter a valid current (0-5A)');
      return;
    }

    try {
      final preset = Preset(
        id: existingPreset?.id ?? _presetService.generateUniqueId(),
        name: name.trim(),
        voltage: voltage,
        current: current,
        description: description.trim().isEmpty ? 'Custom preset' : description.trim(),
        isBuiltIn: false,
      );

      bool success;
      if (existingPreset == null) {
        success = await _presetService.addCustomPreset(preset);
      } else {
        success = await _presetService.updateCustomPreset(preset);
      }

      if (success) {
        Navigator.pop(context);
        setState(() {}); // Refresh the UI
        _showSuccessSnackBar(
          existingPreset == null ? 'Preset added successfully' : 'Preset updated successfully',
        );
      } else {
        _showErrorSnackBar('Failed to save preset');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving preset: $e');
    }
  }

  Future<void> _deletePreset(Preset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _presetService.removeCustomPreset(preset.id);
        if (success) {
          setState(() {}); // Refresh the UI
          _showSuccessSnackBar('Preset deleted successfully');
        } else {
          _showErrorSnackBar('Failed to delete preset');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting preset: $e');
      }
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
