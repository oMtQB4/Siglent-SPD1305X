import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'device_provider.dart';
import 'widgets/connection_panel.dart';
import 'widgets/measurement_panel.dart';
import 'widgets/control_panel.dart';
import 'widgets/status_panel.dart';
import 'widgets/mode_panel.dart';

void main() {
  runApp(const SPD1305XApp());
}

class SPD1305XApp extends StatelessWidget {
  const SPD1305XApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DeviceProvider(),
      child: MaterialApp(
        title: 'SPD1305X Power Supply Controller',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SPD1305X Power Supply Controller'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Licenses',
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'SPD1305X Power Supply Controller',
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Connection panel
              const ConnectionPanel(),
              const SizedBox(height: 8),
              
              // Main content area
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use column layout for narrow screens, row for wide screens
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        const MeasurementPanel(),
                        const SizedBox(height: 8),
                        const ControlPanel(),
                        const SizedBox(height: 8),
                        const StatusPanel(),
                        const SizedBox(height: 8),
                        const ModePanel(),
                      ],
                    );
                  } else {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Measurements and Status
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                const MeasurementPanel(),
                                const SizedBox(height: 8),
                                const Expanded(child: StatusPanel()),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Right column - Controls and Mode
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                const ControlPanel(),
                                const SizedBox(height: 8),
                                const ModePanel(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
