import 'dart:convert'; // For utf8.encode
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../helper/database_helper.dart';
import 'package:intl/intl.dart';

// Global ValueNotifier to track BLE connection status
ValueNotifier<bool> bleConnectionStatus = ValueNotifier<bool>(false);
// Global ValueNotifier to track Kick Count
ValueNotifier<int> kickCountNotifier = ValueNotifier<int>(0);

class ScanPage extends StatefulWidget {
  final VoidCallback onConnect; // Callback to notify when BLE connects

  const ScanPage({super.key, required this.onConnect});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<bool>? isScanningSubscription;
  Stream<List<int>>? characteristicStream;
  StreamSubscription<BluetoothConnectionState>? deviceStateSubscription;

  BluetoothCharacteristic?
      writeCharacteristic; // Store the writeable characteristic

  @override
  void dispose() {
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();
    deviceStateSubscription?.cancel(); // Clean up device state listener
    characteristicStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Devices'),
      ),
      body: isScanning
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                return ListTile(
                  title: Text(
                      device.name.isNotEmpty ? device.name : 'Unknown Device'),
                  subtitle: Text(device.id.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isScanning) {
            stopScan();
          } else {
            startScan();
          }
        },
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }

  Future<void> startScan() async {
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    setState(() {
      isScanning = true;
      scanResults.clear(); // Clear previous results on a new scan
    });

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        setState(() {
          isScanning = false;
        });
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });

    scanSubscription?.cancel();
    isScanningSubscription?.cancel();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectedDevice = device;
    });

    try {
      await device.connect();
      print('Connected to ${device.name}');

      // Notify that BLE is connected
      bleConnectionStatus.value = true;
      widget.onConnect(); // Notify home screen that the device is connected

      // Listen for device disconnection events
      _listenForDisconnection(device);

      services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _subscribeToCharacteristic(
                characteristic); // Subscribe to notifications
          }

          if (characteristic.properties.write) {
            writeCharacteristic =
                characteristic; // Store the writeable characteristic
            print('Found writeable characteristic: ${characteristic.uuid}');

            String today = DateFormat('yyyyMMddHHmmss').format(DateTime.now());

            // Send a message immediately after connecting
            _sendStringToDevice(today);
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  // Listen for disconnection events
  void _listenForDisconnection(BluetoothDevice device) {
    deviceStateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        // Corrected condition
        print('Device disconnected.');
        bleConnectionStatus.value = false; // Update status to disconnected
        _disconnectDevice(); // Clean up state
      }
    });
  }

  // Handle device disconnection and clean up state
  Future<void> _disconnectDevice() async {
    setState(() {
      connectedDevice = null;
      services.clear();
      characteristicStream = null;
    });
    deviceStateSubscription?.cancel(); // Clean up device state listener
  }

  Future<void> _subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);

    characteristicStream = characteristic.value;

    characteristicStream!.listen((data) {
      String receivedString = String.fromCharCodes(data);
      print('Received data: $receivedString');

      if (receivedString.isNotEmpty && receivedString.trim() != '') {
        _saveKickData(receivedString);

        // Optionally send data back after receiving data
        _sendStringToDevice('Response from App!');
      } else {
        print('Received null or empty data. Skipping save.');
      }
    });
  }

  Future<void> _saveKickData(String data) async {
    String timestamp = DateTime.now().toIso8601String();
    await DatabaseHelper().insertKick(data, timestamp);
    print('Data saved: $data at $timestamp');

    // After saving, update the kick count in the notifier
    int currentCount = kickCountNotifier.value;
    kickCountNotifier.value = currentCount + 1; // Increment kick count
  }

  // Method to send the current time to the BLE device
  Future<void> _sendStringToDevice(String message) async {
    if (writeCharacteristic == null) {
      print('No writeable characteristic found!');
      return;
    }

    // Convert the String to a byte array using utf8 encoding
    List<int> messageBytes = utf8.encode(message);

    try {
      // Write the byte array to the BLE characteristic
      await writeCharacteristic!.write(messageBytes);
      print('Sent message to BLE device: $message');
    } catch (e) {
      print('Failed to send message to device: $e');
    }
  }
}
