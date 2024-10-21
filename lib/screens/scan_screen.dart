import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../helper/database_helper.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  StreamSubscription<List<ScanResult>>?
      scanSubscription; // Subscription for scanResults
  StreamSubscription<bool>?
      isScanningSubscription; // Subscription for isScanning
  Stream<List<int>>? characteristicStream;

  @override
  void dispose() {
    // Cleanup any existing subscriptions when the widget is disposed
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();
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
    // If there's an existing subscription, cancel it before starting a new scan
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    setState(() {
      isScanning = true;
      scanResults.clear(); // Clear previous results on a new scan
    });

    // Subscribe to scanResults and update the state
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    // Subscribe to isScanning to detect when scanning stops
    isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        setState(() {
          isScanning = false;
        });
      }
    });
  }

  Future<void> stopScan() async {
    // Stop scanning and cancel subscriptions
    await FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });

    // Cancel any active subscriptions
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectedDevice = device;
    });

    try {
      // Connect to the device
      await device.connect();
      print('Connected to ${device.name}');

      // Discover services and characteristics
      services = await device.discoverServices();

      // Find a characteristic to subscribe to
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _subscribeToCharacteristic(characteristic);
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> _subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    // Subscribe to characteristic notifications
    await characteristic.setNotifyValue(true);

    // Listen for incoming data from the characteristic
    characteristicStream = characteristic.value;

    characteristicStream!.listen((data) {
      String receivedString = String.fromCharCodes(data);
      print('Received data: $receivedString');

      // Check if data is not null or empty before saving
      if (receivedString.isNotEmpty && receivedString.trim() != '') {
        _saveKickData(receivedString);
      } else {
        print('Received null or empty data. Skipping save.');
      }
    });
  }

  Future<void> _saveKickData(String data) async {
    String timestamp = DateTime.now().toIso8601String();

    // Save to SQLite database only if data is valid
    await DatabaseHelper().insertKick(data, timestamp);
    print('Data saved: $data at $timestamp');
  }
}
