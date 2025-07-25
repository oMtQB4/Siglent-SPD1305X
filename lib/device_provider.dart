import 'package:flutter/foundation.dart';
import 'dart:async';
import 'spd1305x_client.dart';

class DeviceProvider extends ChangeNotifier {
  SPD1305XClient? _client;
  Timer? _measurementTimer;
  
  // Connection state
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  
  // Device info
  String _deviceInfo = '';
  String _systemVersion = '';
  String _lastError = '';
  SystemStatus? _systemStatus;
  
  // Channel 1 measurements
  double _ch1Voltage = 0.0;
  double _ch1Current = 0.0;
  double _ch1Power = 0.0;
  
  // Channel 1 settings
  double _ch1VoltageSet = 0.0;
  double _ch1CurrentSet = 0.0;
  bool _ch1OutputEnabled = false;
  
  // Connection settings
  String _ipAddress = 'spd1305x';
  int _port = 5025;
  
  // Getters
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  String get deviceInfo => _deviceInfo;
  String get systemVersion => _systemVersion;
  String get lastError => _lastError;
  SystemStatus? get systemStatus => _systemStatus;
  
  double get ch1Voltage => _ch1Voltage;
  double get ch1Current => _ch1Current;
  double get ch1Power => _ch1Power;
  
  double get ch1VoltageSet => _ch1VoltageSet;
  double get ch1CurrentSet => _ch1CurrentSet;
  bool get ch1OutputEnabled => _ch1OutputEnabled;
  
  String get ipAddress => _ipAddress;
  int get port => _port;
  
  void setConnectionSettings(String ip, int port) {
    _ipAddress = ip;
    _port = port;
    notifyListeners();
  }
  
  Future<bool> connect() async {
    try {
      _connectionStatus = 'Connecting...';
      notifyListeners();
      
      _client = SPD1305XClient(_ipAddress, _port);
      final success = await _client!.connect();
      
      if (success) {
        _isConnected = true;
        _connectionStatus = 'Connected';
        
        // Get device info
        await _updateDeviceInfo();
        
        // Start periodic measurements
        _startMeasurements();
        
        // Get initial settings
        await _updateSettings();
        
        notifyListeners();
        return true;
      } else {
        _connectionStatus = 'Connection failed';
        _isConnected = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _connectionStatus = 'Connection error: $e';
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> disconnect() async {
    _measurementTimer?.cancel();
    _measurementTimer = null;
    
    if (_client != null) {
      await _client!.disconnect();
      _client = null;
    }
    
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    notifyListeners();
  }
  
  void _startMeasurements() {
    _measurementTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_isConnected && _client != null) {
        await _updateMeasurements();
        await _updateSystemStatus();
      }
    });
  }
  
  Future<void> _updateDeviceInfo() async {
    if (_client == null) return;
    
    try {
      final info = await _client!.getDeviceInfo();
      if (info != null) {
        _deviceInfo = info;
      }
      
      final version = await _client!.getSystemVersion();
      if (version != null) {
        _systemVersion = version;
      }
    } catch (e) {
      print('Error updating device info: $e');
    }
  }
  
  Future<void> _updateMeasurements() async {
    if (_client == null) return;
    
    try {
      final voltage = await _client!.measureVoltage('CH1');
      if (voltage != null) {
        _ch1Voltage = voltage;
      }
      
      final current = await _client!.measureCurrent('CH1');
      if (current != null) {
        _ch1Current = current;
      }
      
      final power = await _client!.measurePower('CH1');
      if (power != null) {
        _ch1Power = power;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating measurements: $e');
    }
  }
  
  Future<void> _updateSettings() async {
    if (_client == null) return;
    
    try {
      final voltageSet = await _client!.getVoltageSetting('CH1');
      if (voltageSet != null) {
        _ch1VoltageSet = voltageSet;
      }
      
      final currentSet = await _client!.getCurrentSetting('CH1');
      if (currentSet != null) {
        _ch1CurrentSet = currentSet;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating settings: $e');
    }
  }
  
  Future<void> _updateSystemStatus() async {
    if (_client == null) return;
    
    try {
      final status = await _client!.getSystemStatus();
      if (status != null) {
        _systemStatus = status;
        _ch1OutputEnabled = status.isOutputOn;
      }
      
      final error = await _client!.getSystemError();
      if (error != null && error.isNotEmpty) {
        _lastError = error;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating system status: $e');
    }
  }
  
  Future<bool> setVoltage(double voltage) async {
    if (_client == null || !_isConnected) return false;
    
    try {
      final success = await _client!.setVoltage('CH1', voltage);
      if (success) {
        _ch1VoltageSet = voltage;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error setting voltage: $e');
      return false;
    }
  }
  
  Future<bool> setCurrent(double current) async {
    if (_client == null || !_isConnected) return false;
    
    try {
      final success = await _client!.setCurrent('CH1', current);
      if (success) {
        _ch1CurrentSet = current;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error setting current: $e');
      return false;
    }
  }
  
  Future<bool> setOutput(bool enabled) async {
    if (_client == null || !_isConnected) return false;
    
    try {
      final success = await _client!.setOutput('CH1', enabled);
      if (success) {
        _ch1OutputEnabled = enabled;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error setting output: $e');
      return false;
    }
  }
  
  Future<bool> refreshSettings() async {
    if (_client == null || !_isConnected) return false;
    
    try {
      await _updateSettings();
      return true;
    } catch (e) {
      print('Error refreshing settings: $e');
      return false;
    }
  }
  
  @override
  void dispose() {
    _measurementTimer?.cancel();
    _client?.dispose();
    super.dispose();
  }
}
