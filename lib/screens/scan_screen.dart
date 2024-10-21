import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import shared_preferences
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
  Stream<List<int>>? characteristicStream;

  @override
  void initState() {
    super.initState();
    startAutoReconnectScan();  // Start auto-reconnect when the app initializes
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
                  title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
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
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    setState(() {
      isScanning = true;
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning) {
        setState(() {
          this.isScanning = false;
        });
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  // Save the connected device ID to SharedPreferences
  Future<void> _saveDeviceId(String deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectedDeviceId', deviceId);
  }

  // Load the saved device ID from SharedPreferences
  Future<String?> _loadSavedDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('connectedDeviceId');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectedDevice = device;
    });

    // Listen for device disconnection events
    device.state.listen((state) {
      if (state == BluetoothDeviceState.disconnected) {
        _handleDisconnection();
      }
    });

    try {
      await device.connect();
      print('Connected to ${device.name}');

      // Save the device ID (MAC address)
      await _saveDeviceId(device.id.id);

      // Discover services and characteristics
      services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _subscribeToCharacteristic(characteristic);
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
      _handleDisconnection();
    }
  }

  Future<void> _subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);

    characteristicStream = characteristic.value;
    characteristicStream!.listen((data) {
      String receivedString = String.fromCharCodes(data);
      print('Received data: $receivedString');

      if (receivedString.isNotEmpty && receivedString.trim() != '') {
        _saveKickData(receivedString);
      } else {
        print('Received null or empty data. Skipping save.');
      }
    });
  }

  Future<void> _saveKickData(String data) async {
    String timestamp = DateTime.now().toIso8601String();
    await DatabaseHelper().insertKick(data, timestamp);
    print('Data saved: $data at $timestamp');
  }

  // Start auto-reconnect scanning for the saved device
  Future<void> startAutoReconnectScan() async {
    String? savedDeviceId = await _loadSavedDeviceId();
    if (savedDeviceId == null) {
      print('No saved device to reconnect to.');
      return;
    }

    print('Starting auto-reconnect scan for saved device: $savedDeviceId');
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.id.id == savedDeviceId) {
          print('Found saved device: ${result.device.name}');
          FlutterBluePlus.stopScan();
          _connectToDevice(result.device);
          break;
        }
      }
    });
  }

  void _handleDisconnection() {
    print('Device disconnected.');
    setState(() {
      connectedDevice = null;
      services.clear();
      characteristicStream = null;
    });

    // Start scanning to reconnect the device after disconnection
    startAutoReconnectScan();
  }
}
