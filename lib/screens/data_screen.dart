import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // For date formatting
import '../helper/database_helper.dart';

class DataPage extends StatefulWidget {
  const DataPage({Key? key}) : super(key: key);

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Kick Data'),
      ),
      body: kickData.isEmpty
          ? const Center(child: Text('No data available'))
          : ListView.builder(
              itemCount: kickData.length,
              itemBuilder: (context, index) {
                // Parsing and formatting the timestamp
                DateTime timestamp = DateTime.parse(kickData[index]['timestamp']);
                String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

                return ListTile(
                  title: Text('Data: ${kickData[index]['data']}'),
                  subtitle: Text('Timestamp: $formattedTimestamp'),
                );
              },
            ),
    );
  }
}
