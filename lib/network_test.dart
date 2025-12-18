import 'dart:io';
import 'dart:async';

class NetworkTestResult {
  final bool success;
  final String message;
  final String? deviceInfo;
  final String? diagnostics;
  
  NetworkTestResult({
    required this.success,
    required this.message,
    this.deviceInfo,
    this.diagnostics,
  });
}

class NetworkTest {
  static Future<NetworkTestResult> testConnection(String host, int port) async {
    print('Testing connection to $host:$port...');
    
    try {
      // Test basic socket connection
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      print('✅ Socket connection successful!');
      
      // Test sending a simple command
      socket.write('*IDN?\n');
      print('✅ Command sent successfully');
      
      // Listen for response
      final completer = Completer<String>();
      socket.listen(
        (data) {
          final response = String.fromCharCodes(data).trim();
          print('✅ Received response: $response');
          completer.complete(response);
        },
        onError: (error) {
          print('❌ Socket error: $error');
          completer.completeError(error);
        },
        onDone: () {
          print('🔌 Socket closed');
        },
      );
      
      // Wait for response with timeout
      String? deviceInfo;
      try {
        deviceInfo = await completer.future.timeout(Duration(seconds: 10));
      } catch (e) {
        print('⏰ Response timeout: $e');
      }
      
      await socket.close();
      print('✅ Connection test completed successfully');
      
      return NetworkTestResult(
        success: true,
        message: 'Successfully connected to $host:$port',
        deviceInfo: deviceInfo,
      );
      
    } catch (e) {
      print('❌ Connection failed: $e');
      
      // Additional diagnostics
      final diagnostics = await _runDiagnostics(host, port);
      
      return NetworkTestResult(
        success: false,
        message: 'Connection failed: $e',
        diagnostics: diagnostics,
      );
    }
  }
  
  static Future<String> _runDiagnostics(String host, int port) async {
    print('\n🔍 Running diagnostics...');
    final buffer = StringBuffer();
    
    // Test if host is reachable
    try {
      final addresses = await InternetAddress.lookup(host);
      final addressStr = addresses.map((a) => a.address).join(', ');
      print('✅ Host lookup successful: $addressStr');
      buffer.writeln('✓ Host lookup: $addressStr');
    } catch (e) {
      print('❌ Host lookup failed: $e');
      buffer.writeln('✗ Host lookup failed: $e');
      buffer.writeln('\nCheck that the hostname/IP is correct.');
      return buffer.toString();
    }
    
    // Test ping (if available)
    try {
      final result = await Process.run('ping', ['-c', '1', '-t', '2', host]);
      if (result.exitCode == 0) {
        print('✅ Ping successful');
        buffer.writeln('✓ Ping successful');
      } else {
        print('❌ Ping failed: ${result.stderr}');
        buffer.writeln('✗ Ping failed');
      }
    } catch (e) {
      print('⚠️ Ping test unavailable: $e');
    }
    
    // Test if port is open using netcat (if available)
    try {
      final result = await Process.run('nc', ['-z', '-v', '-w', '2', host, port.toString()]);
      if (result.exitCode == 0) {
        print('✅ Port $port is open');
        buffer.writeln('✓ Port $port is open');
      } else {
        print('❌ Port $port appears closed: ${result.stderr}');
        buffer.writeln('✗ Port $port appears closed');
      }
    } catch (e) {
      print('⚠️ Port test unavailable: $e');
    }
    
    buffer.writeln('\nTroubleshooting:');
    buffer.writeln('• Verify the device is powered on');
    buffer.writeln('• Check network connectivity');
    buffer.writeln('• Confirm port $port is correct');
    
    return buffer.toString();
  }
}
