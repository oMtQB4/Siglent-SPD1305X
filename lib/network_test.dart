import 'dart:io';
import 'dart:async';

class NetworkTest {
  static Future<void> testConnection(String host, int port) async {
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
      try {
        await completer.future.timeout(Duration(seconds: 10));
      } catch (e) {
        print('⏰ Response timeout: $e');
      }
      
      await socket.close();
      print('✅ Connection test completed successfully');
      
    } catch (e) {
      print('❌ Connection failed: $e');
      
      // Additional diagnostics
      await _runDiagnostics(host, port);
    }
  }
  
  static Future<void> _runDiagnostics(String host, int port) async {
    print('\n🔍 Running diagnostics...');
    
    // Test if host is reachable
    try {
      final addresses = await InternetAddress.lookup(host);
      print('✅ Host lookup successful: ${addresses.map((a) => a.address).join(', ')}');
    } catch (e) {
      print('❌ Host lookup failed: $e');
      return;
    }
    
    // Test ping (if available)
    try {
      final result = await Process.run('ping', ['-c', '1', host]);
      if (result.exitCode == 0) {
        print('✅ Ping successful');
      } else {
        print('❌ Ping failed: ${result.stderr}');
      }
    } catch (e) {
      print('⚠️ Ping test unavailable: $e');
    }
    
    // Test if port is open using netcat (if available)
    try {
      final result = await Process.run('nc', ['-z', '-v', host, port.toString()]);
      if (result.exitCode == 0) {
        print('✅ Port $port is open');
      } else {
        print('❌ Port $port appears closed: ${result.stderr}');
      }
    } catch (e) {
      print('⚠️ Port test unavailable: $e');
    }
    
    print('\n💡 Troubleshooting suggestions:');
    print('1. Verify the SPD1305X IP address is correct');
    print('2. Check if the device is powered on and connected to network');
    print('3. Ensure the device is configured for TCP communication');
    print('4. Check firewall settings on both devices');
    print('5. Try connecting from the same network segment');
    print('6. Verify the port number (usually 5025 for SCPI devices)');
  }
}
