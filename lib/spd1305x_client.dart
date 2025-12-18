import 'dart:io';
import 'dart:async';
import 'dart:convert';

class SPD1305XClient {
  Socket? _socket;
  final String _host;
  final int _port;
  bool _isConnected = false;
  
  final StreamController<String> _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;
  
  void Function()? onDisconnect;
  
  SPD1305XClient(this._host, this._port);
  
  bool get isConnected => _isConnected;
  
  Future<bool> connect() async {
    try {
      _socket = await Socket.connect(_host, _port);
      _isConnected = true;
      
      _socket!.listen(
        (data) {
          final response = utf8.decode(data).trim();
          _responseController.add(response);
        },
        onError: (error) {
          print('Socket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('Socket closed by remote');
          // Only handle as disconnect if we think we're still connected
          // This prevents false disconnects during normal operation
          if (_isConnected && _socket != null) {
            _handleDisconnect();
          }
        },
        cancelOnError: false,
      );
      
      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }
  
  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      onDisconnect?.call();
    }
  }
  
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
      _isConnected = false;
    }
  }
  
  Future<String?> sendCommand(String command) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to device');
    }
    
    try {
      // Send command with newline terminator
      _socket!.write('$command\n');
      
      // Wait for response with timeout
      final completer = Completer<String>();
      late StreamSubscription subscription;
      
      subscription = responseStream.listen((response) {
        subscription.cancel();
        completer.complete(response);
      });
      
      // Timeout after 5 seconds
      Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError('Command timeout');
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('Send command error: $e');
      // Don't treat command errors as disconnects - socket listener handles real disconnects
      return null;
    }
  }
  
  // Device identification
  Future<String?> getDeviceInfo() async {
    return await sendCommand('*IDN?');
  }
  
  // Measurement commands
  Future<double?> measureCurrent(String channel) async {
    final response = await sendCommand('MEASure:CURRent? $channel');
    return response != null ? double.tryParse(response) : null;
  }
  
  Future<double?> measureVoltage(String channel) async {
    final response = await sendCommand('MEASure:VOLTage? $channel');
    return response != null ? double.tryParse(response) : null;
  }
  
  Future<double?> measurePower(String channel) async {
    final response = await sendCommand('MEASure:POWEr? $channel');
    return response != null ? double.tryParse(response) : null;
  }
  
  // Set commands
  Future<bool> setCurrent(String channel, double value) async {
    final response = await sendCommand('$channel:CURRent $value');
    return response != null;
  }
  
  Future<bool> setVoltage(String channel, double value) async {
    final response = await sendCommand('$channel:VOLTage $value');
    return response != null;
  }
  
  // Query set values
  Future<double?> getCurrentSetting(String channel) async {
    final response = await sendCommand('$channel:CURRent?');
    return response != null ? double.tryParse(response) : null;
  }
  
  Future<double?> getVoltageSetting(String channel) async {
    final response = await sendCommand('$channel:VOLTage?');
    return response != null ? double.tryParse(response) : null;
  }
  
  // Output control
  Future<bool> setOutput(String channel, bool enabled) async {
    final state = enabled ? 'ON' : 'OFF';
    final command = 'OUTP $channel,$state';
    print('Sending output command: $command');
    final response = await sendCommand(command);
    print('Output command response: $response');
    return response != null;
  }
  
  // Mode commands
  Future<bool> setWireMode(String mode) async {
    // Use the correct MODE:SET command format
    final command = 'MODE:SET $mode';
    print('Setting wire mode: $command');
    final response = await sendCommand(command);
    print('Wire mode response: "$response"');
    
    // Check if response indicates success
    if (response != null) {
      final responseUpper = response.trim().toUpperCase();
      if (responseUpper.isEmpty || 
          responseUpper == 'OK' || 
          responseUpper.contains('MODE') ||
          responseUpper.contains(mode)) {
        return true;
      } else if (responseUpper.contains('ERROR') || responseUpper.contains('INVALID')) {
        print('Wire mode command failed with response: $response');
        return false;
      }
      // If we get any other response, assume success
      return true;
    }
    return false;
  }

  Future<String?> getWireMode() async {
    // Query current wire mode - try multiple command formats
    final response = await sendCommand('MODE:SET?');
    print('Wire mode query response: "$response"');
    
    if (response != null) {
      final trimmed = response.trim().toUpperCase();
      if (trimmed.contains('2W') || trimmed == '2W') return '2W';
      if (trimmed.contains('4W') || trimmed == '4W') return '4W';
      
      // If the response doesn't contain clear mode info, try alternative query
      final altResponse = await sendCommand('MODE?');
      print('Alternative wire mode query response: "$altResponse"');
      
      if (altResponse != null) {
        final altTrimmed = altResponse.trim().toUpperCase();
        if (altTrimmed.contains('2W') || altTrimmed == '2W') return '2W';
        if (altTrimmed.contains('4W') || altTrimmed == '4W') return '4W';
      }
    }
    
    // If no valid response, default to 4W (common default for power supplies)
    print('Wire mode query failed, defaulting to 4W');
    return '4W';
  }
  
  // System commands
  Future<String?> getSystemError() async {
    return await sendCommand('SYSTem:ERRor?');
  }
  
  Future<String?> getSystemVersion() async {
    return await sendCommand('SYSTem:VERSion?');
  }
  
  Future<SystemStatus?> getSystemStatus() async {
    final response = await sendCommand('SYSTem:STATus?');
    if (response != null) {
      return SystemStatus.fromHex(response);
    }
    return null;
  }
  
  void dispose() {
    _responseController.close();
    disconnect();
  }
}

class SystemStatus {
  final bool isCCMode;
  final bool isOutputOn;
  final bool is4WMode;
  final bool isTimerOn;
  final bool isWaveformDisplay;
  
  SystemStatus({
    required this.isCCMode,
    required this.isOutputOn,
    required this.is4WMode,
    required this.isTimerOn,
    required this.isWaveformDisplay,
  });
  
  factory SystemStatus.fromHex(String hexString) {
    // Remove 0x prefix if present
    final cleanHex = hexString.replaceFirst('0x', '');
    final value = int.parse(cleanHex, radix: 16);
    
    return SystemStatus(
      isCCMode: (value & (1 << 0)) != 0,
      isOutputOn: (value & (1 << 4)) != 0,
      is4WMode: (value & (1 << 5)) != 0,
      isTimerOn: (value & (1 << 6)) != 0,
      isWaveformDisplay: (value & (1 << 8)) != 0,
    );
  }
  
  String get modeString => isCCMode ? 'CC' : 'CV';
  String get outputString => isOutputOn ? 'ON' : 'OFF';
  String get wireString => is4WMode ? '4W' : '2W';
  String get timerString => isTimerOn ? 'ON' : 'OFF';
  String get displayString => isWaveformDisplay ? 'Waveform' : 'Digital';
}
