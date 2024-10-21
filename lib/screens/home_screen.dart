import 'package:flutter/material.dart';
import '../helper/database_helper.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> kickData = [];

  @override
  void initState() {
    super.initState();
    _loadKickData();
  }

  Future<void> _loadKickData() async {
    List<Map<String, dynamic>> data = await DatabaseHelper().getKicks();
    setState(() {
      kickData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Count of timestamps in kickData
    int count = kickData.length;
    // If there is data, parse the last timestamp and format it
    String lastTimestamp = 'No data';
    if (count > 0) {
      DateTime parsedTimestamp = DateTime.parse(kickData.first['timestamp']);
      lastTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(parsedTimestamp); // Custom format
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('User Info Page')),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.lightBlue[100],
          ),
          // Floating card
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
                    // Picture (User Avatar)
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("lib/Image/icon_1.png"),
                    ),
                    const SizedBox(height: 10),
                    // Name of User
                    const Text(
                      'Mommy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Last timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Timestamp:',
                            style: TextStyle(fontSize: 16)),
                        Text(lastTimestamp,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Count of timestamps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Count:', style: TextStyle(fontSize: 16)),
                        Text(count.toString(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Button to navigate to scan BLE page
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
