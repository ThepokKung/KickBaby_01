import 'dart:async'; // Import Timer package
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../helper/database_helper.dart';
import 'package:intl/intl.dart';
import 'scan_screen.dart'; // Import to access bleConnectionStatus and kickCountNotifier
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Import Flutter Blue Plus for Bluetooth handling

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> kickData = [];
  int dailyKickCount = 0;
  Timer? _bleTimer; // Declare a Timer variable
  BluetoothDevice? _connectedDevice; // Keep track of the connected device

  @override
  void initState() {
    super.initState();
    _loadKickData();
    _checkDailyReset();

    // Set up a periodic check for the BLE connection status
    _bleTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkBleConnectionStatus();
    });

    // Listen to changes in the kick count and reload data when updated
    kickCountNotifier.addListener(() {
      _loadKickData(); // Reload data when a new kick is saved
      _incrementDailyCount(); // Increment the daily count
    });

    // Subscribe to BLE connection status
    bleConnectionStatus.addListener(() {
      if (!bleConnectionStatus.value) {
        print("BLE device disconnected");
        _handleDisconnection();
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _bleTimer?.cancel();
    bleConnectionStatus.removeListener(() {});
    super.dispose();
  }

  // Manually check BLE connection status every 10 seconds
  Future<void> _checkBleConnectionStatus() async {
    if (_connectedDevice != null) {
      final connectionState = await _connectedDevice!.state.first;
      if (connectionState != BluetoothConnectionState.connected) {
        print('BLE device is not connected.');
        bleConnectionStatus.value = false; // Update connection status
      } else {
        print('BLE device is connected.');
      }
    }
  }

  // Set the connected device when a connection is made in the BLE scan screen
  void setConnectedDevice(BluetoothDevice device) {
    _connectedDevice = device;
    bleConnectionStatus.value = true; // Update the connection status
    print('Device set as connected: ${device.name}');
  }

  // Handle disconnection logic
  void _handleDisconnection() {
    // Show a dialog or perform any necessary action when disconnected
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Connection Lost"),
          content: Text("The BLE device has been disconnected."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
    // Reset the connected device reference
    _connectedDevice = null;
  }

  Future<void> _loadKickData() async {
    List<Map<String, dynamic>> data = await DatabaseHelper().getKicks();
    setState(() {
      kickData = data;
    });
  }

  Future<void> _checkDailyReset() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDate = prefs.getString('last_date'); // Get the last stored date
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get today's date

    // Check if the app was last opened on a different day
    if (lastDate == null || lastDate != today) {
      // If it's a new day, reset the daily count
      setState(() {
        dailyKickCount = 0;
      });
      // Save today's date
      await prefs.setString('last_date', today);
    } else {
      // If it's the same day, load the daily count
      int? storedDailyCount = prefs.getInt('daily_count');
      setState(() {
        dailyKickCount = storedDailyCount ?? 0;
      });
    }
  }

  Future<void> _incrementDailyCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyKickCount += 1;
    });
    // Save the updated daily count
    await prefs.setInt('daily_count', dailyKickCount);
  }

  @override
  Widget build(BuildContext context) {
    int count = kickData.length;
    String lastTimestamp = 'No data';
    if (count > 0) {
      DateTime parsedTimestamp = DateTime.parse(kickData.first['timestamp']);
      lastTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedTimestamp); // Custom format
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info Page'),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.lightBlue[100],
          ),
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("lib/Image/icon_1.png"),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mommy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Timestamp:', style: TextStyle(fontSize: 16)),
                        Text(lastTimestamp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Count:', style: TextStyle(fontSize: 16)),
                        Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Count:', style: TextStyle(fontSize: 16)),
                        Text(dailyKickCount.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<bool>(
                      valueListenable: bleConnectionStatus, // Listen to connection status
                      builder: (context, isConnected, child) {
                        return Text(
                          isConnected ? 'BLE Device Connected' : 'BLE Device Disconnected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/ble_scan').then((_) {
                          _loadKickData(); // Reload kickData after returning from BLE scan
                        });
                      },
                      child: const Text('Scan BLE for update'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/data'); // Navigate to DataPage
                      },
                      child: const Text('View All Data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
