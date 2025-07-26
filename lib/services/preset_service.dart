import 'dart:convert';

class Preset {
  final String id;
  final String name;
  final double voltage;
  final double current;
  final String description;
  final bool isBuiltIn;

  const Preset({
    required this.id,
    required this.name,
    required this.voltage,
    required this.current,
    required this.description,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'voltage': voltage,
      'current': current,
      'description': description,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'] as String,
      name: json['name'] as String,
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      description: json['description'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Preset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PresetService {
  List<Preset> _presets = [];
  List<Preset> _customPresets = [];
  
  // Default presets (removable)
  static const List<Preset> _defaultPresets = [
    Preset(
      id: 'default_3v3',
      name: '3.3V/1.0A',
      voltage: 3.3,
      current: 1.0,
      description: '3.3V logic supply',
      isBuiltIn: false, // Make removable
    ),
    Preset(
      id: 'default_5v',
      name: '5.0V/1.0A',
      voltage: 5.0,
      current: 1.0,
      description: '5V logic supply',
      isBuiltIn: false, // Make removable
    ),
    Preset(
      id: 'default_7v4',
      name: '7.4V/1.0A',
      voltage: 7.4,
      current: 1.0,
      description: '7.4V supply (2S LiPo)',
      isBuiltIn: false, // Make removable
    ),
    Preset(
      id: 'default_12v',
      name: '12V/1.0A',
      voltage: 12.0,
      current: 1.0,
      description: '12V system supply',
      isBuiltIn: false, // Make removable
    ),
  ];

  List<Preset> get presets => List.unmodifiable(_presets);
  List<Preset> get builtInPresets => []; // No built-in presets anymore
  List<Preset> get customPresets => List.unmodifiable(_customPresets);
  List<Preset> get defaultPresets => _defaultPresets.where((p) => _presets.contains(p)).toList();

  Future<void> initialize() async {
    // Initialize with default presets
    _presets = List.from(_defaultPresets);
    _customPresets = [];
    
    // Note: All presets are stored in memory only for this session
    // This avoids any platform-specific storage dependencies
    print('PresetService initialized with ${_defaultPresets.length} default presets');
  }

  Future<bool> addCustomPreset(Preset preset) async {
    if (_presets.any((p) => p.id == preset.id)) {
      return false; // Preset with this ID already exists
    }
    
    final customPreset = Preset(
      id: preset.id,
      name: preset.name,
      voltage: preset.voltage,
      current: preset.current,
      description: preset.description,
      isBuiltIn: false,
    );
    
    _customPresets.add(customPreset);
    _presets.add(customPreset);
    return true;
  }

  Future<bool> removeCustomPreset(String id) async {
    // All presets are now removable (no built-in protection)
    _customPresets.removeWhere((p) => p.id == id);
    _presets.removeWhere((p) => p.id == id);
    return true;
  }

  Future<bool> updateCustomPreset(Preset updatedPreset) async {
    final index = _presets.indexWhere((p) => p.id == updatedPreset.id);
    if (index == -1) return false;
    
    final existingPreset = _presets[index];
    if (existingPreset.isBuiltIn) {
      return false; // Cannot update built-in presets
    }
    
    final newPreset = Preset(
      id: updatedPreset.id,
      name: updatedPreset.name,
      voltage: updatedPreset.voltage,
      current: updatedPreset.current,
      description: updatedPreset.description,
      isBuiltIn: false,
    );
    
    // Update in both lists
    _presets[index] = newPreset;
    final customIndex = _customPresets.indexWhere((p) => p.id == updatedPreset.id);
    if (customIndex != -1) {
      _customPresets[customIndex] = newPreset;
    }
    
    return true;
  }

  Preset? getPresetById(String id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  String generateUniqueId() {
    int counter = 1;
    String baseId = 'custom_preset_';
    
    while (_presets.any((p) => p.id == '$baseId$counter')) {
      counter++;
    }
    
    return '$baseId$counter';
  }

  // Additional methods for control panel integration
  Preset? getPreset(String id) {
    return getPresetById(id);
  }

  Future<String?> addPreset(double voltage, double current) async {
    final id = generateUniqueId();
    final name = 'Custom ${voltage}V/${current}A';
    final description = 'Custom preset: ${voltage}V, ${current}A';
    
    final preset = Preset(
      id: id,
      name: name,
      voltage: voltage,
      current: current,
      description: description,
      isBuiltIn: false,
    );
    
    final success = await addCustomPreset(preset);
    return success ? id : null;
  }

  Future<bool> removePreset(String id) async {
    return await removeCustomPreset(id);
  }

  // Export/Import functionality for manual backup/restore
  String exportCustomPresets() {
    final jsonList = _customPresets.map((preset) => preset.toJson()).toList();
    return json.encode(jsonList);
  }

  Future<bool> importCustomPresets(String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final importedPresets = jsonList
          .map((json) => Preset.fromJson(json))
          .where((preset) => !preset.isBuiltIn)
          .toList();
      
      // Clear existing custom presets
      _customPresets.clear();
      _presets.removeWhere((p) => !p.isBuiltIn);
      
      // Add imported presets
      for (final preset in importedPresets) {
        await addCustomPreset(preset);
      }
      
      return true;
    } catch (e) {
      print('Error importing presets: $e');
      return false;
    }
  }
}
