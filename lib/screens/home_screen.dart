import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/* Models Here */
import '../models/kick.dart';

/* Image Here */
// import '../Image/icon_1.png';

// Fake data to be displayed in the second page
final List<Kick> demoData = [
  Kick("10:15:30", 1),
  Kick("12:45:20", 1),
  Kick("11:15:30", 1),
  Kick("13:45:20", 1),
  Kick("15:45:20", 1),
  Kick("19:45:20", 1),
  Kick("18:45:20", 1),
  Kick("16:45:20", 1),
  Kick("17:45:20", 1),
];

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Getting the last timestamp from the demoData
    String lastTimestamp = demoData.last.timestamps;
    // Getting the current count of timestamps
    int count = demoData.length;
    // Getting the current time
    DateTime currentTime = DateTime.now();
    String formattedDate = DateFormat('yy-MM-dd HH:mm:ss').format(currentTime);

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text('User Info Page'),
        ),
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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("lib/Image/icon_1.png"),
                    ),
                    const SizedBox(height: 10),
                    // Name of User (Static or dynamic)
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
                        const Text(
                          'Last Timestamp:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          lastTimestamp,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Count of timestamps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Count:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Current time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Time:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          // currentTime.toString(),
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Button to navigate to third page
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home'); //FIX
                      },
                      child: const Text('Update with BLE'),
                    ),
                    const SizedBox(height: 20),
                    // Button to navigate to third page
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/second');
                      },
                      child: const Text('Go to Third Page'),
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
