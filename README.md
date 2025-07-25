# SPD1305X Power Supply Controller

A Flutter application for controlling the Siglent SPD1305X power supply via TCP communication.

## Features

- **TCP Connection**: Connect to the SPD1305X power supply over network
- **Real-time Monitoring**: Live display of voltage, current, and power measurements
- **Output Control**: Turn the power supply output ON/OFF
- **Voltage/Current Setting**: Set precise voltage and current values
- **System Status**: View device status, mode (CV/CC), wire mode (2W/4W), timer status, and error information
- **Quick Presets**: Common voltage/current combinations (3.3V/1A, 5V/2A, 12V/1A, 24V/0.5A)

## Supported Commands

The application implements the following SPD1305X AT commands:

- `*IDN?` - Device identification
- `MEASure:CURRent? CH1` - Measure current
- `MEASure:VOLTage? CH1` - Measure voltage  
- `MEASure:POWEr? CH1` - Measure power
- `CH1:CURRent <value>` - Set current
- `CH1:VOLTage <value>` - Set voltage
- `CH1:CURRent?` - Query current setting
- `CH1:VOLTage?` - Query voltage setting
- `OUTPut CH1, ON/OFF` - Control output
- `SYSTem:ERRor?` - Query errors
- `SYSTem:VERSion?` - Query version
- `SYSTem:STATus?` - Query system status

## Usage

1. **Connection**: Enter the IP address and port (default 5025) of your SPD1305X
2. **Connect**: Click the Connect button to establish TCP connection
3. **Monitor**: View real-time measurements in the left panel
4. **Control**: Use the right panel to set voltage/current and control output
5. **Status**: Check device status and system information in the bottom left

## System Status Indicators

- **Output**: Shows if the output is ON or OFF
- **Mode**: Displays CV (Constant Voltage) or CC (Constant Current) mode
- **Wire Mode**: Shows 2W or 4W measurement mode
- **Timer**: Indicates if timer function is active
- **Display**: Shows current display mode (Digital/Waveform)

## Requirements

- Flutter SDK
- Network connection to SPD1305X power supply
- SPD1305X configured for TCP communication on specified port

## Running the Application

```bash
flutter pub get
flutter run
```

## Architecture

- **SPD1305XClient**: TCP communication layer
- **DeviceProvider**: State management using Provider pattern
- **UI Widgets**: Modular components for connection, measurement, control, and status panels
