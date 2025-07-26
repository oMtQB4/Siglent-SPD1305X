import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../device_provider.dart';
import '../services/preset_service.dart';

class PresetPanel extends StatefulWidget {
  const PresetPanel({super.key});

  @override
  State<PresetPanel> createState() => _PresetPanelState();
}

class _PresetPanelState extends State<PresetPanel> {
  final PresetService _presetService = PresetService();
  bool _isLoading = true;
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _initializePresets();
  }

  Future<void> _initializePresets() async {
    await _presetService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
                    const Icon(Icons.bookmark, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Voltage/Current Presets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddPresetDialog(context),
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Custom Preset',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Preset categories
                _buildPresetCategory('Built-in Presets', _presetService.builtInPresets, provider),
                
                if (_presetService.customPresets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPresetCategory('Custom Presets', _presetService.customPresets, provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetCategory(String title, List<Preset> presets, DeviceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) => _buildPresetChip(preset, provider)).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetChip(Preset preset, DeviceProvider provider) {
    final isSelected = _selectedPresetId == preset.id;
    
    return GestureDetector(
      onLongPress: preset.isBuiltIn ? null : () => _showPresetOptions(preset),
      child: FilterChip(
        selected: isSelected,
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preset.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '${preset.voltage}V / ${preset.current}A',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            _applyPreset(preset, provider);
          }
        },
        tooltip: preset.description,
        avatar: preset.isBuiltIn 
            ? const Icon(Icons.star, size: 16)
            : const Icon(Icons.person, size: 16),
      ),
    );
  }

  Future<void> _applyPreset(Preset preset, DeviceProvider provider) async {
    if (!provider.isConnected) {
      _showSnackBar('Connect to device first', Colors.orange);
      return;
    }

    setState(() {
      _selectedPresetId = preset.id;
    });

    try {
      final voltageSuccess = await provider.setVoltage(preset.voltage);
      final currentSuccess = await provider.setCurrent(preset.current);
      
      if (voltageSuccess && currentSuccess) {
        _showSnackBar('Applied preset: ${preset.name}', Colors.green);
      } else {
        _showSnackBar('Failed to apply preset completely', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error applying preset: $e', Colors.red);
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

  void _showPresetOptions(Preset preset) {
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
                _showEditPresetDialog(preset);
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

  void _showAddPresetDialog(BuildContext context) {
    _showPresetDialog(context, 'Add Custom Preset');
  }

  void _showEditPresetDialog(Preset preset) {
    _showPresetDialog(context, 'Edit Preset', existingPreset: preset);
  }

  void _showPresetDialog(BuildContext context, String title, {Preset? existingPreset}) {
    final nameController = TextEditingController(text: existingPreset?.name ?? '');
    final voltageController = TextEditingController(
      text: existingPreset?.voltage.toString() ?? '',
    );
    final currentController = TextEditingController(
      text: existingPreset?.current.toString() ?? '',
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
      _showSnackBar('Please enter a preset name', Colors.red);
      return;
    }

    final voltage = double.tryParse(voltageText);
    final current = double.tryParse(currentText);

    if (voltage == null || voltage < 0 || voltage > 30) {
      _showSnackBar('Please enter a valid voltage (0-30V)', Colors.red);
      return;
    }

    if (current == null || current < 0 || current > 5) {
      _showSnackBar('Please enter a valid current (0-5A)', Colors.red);
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
        _showSnackBar(
          existingPreset == null ? 'Preset added successfully' : 'Preset updated successfully',
          Colors.green,
        );
      } else {
        _showSnackBar('Failed to save preset', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error saving preset: $e', Colors.red);
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
          _showSnackBar('Preset deleted successfully', Colors.green);
        } else {
          _showSnackBar('Failed to delete preset', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error deleting preset: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
