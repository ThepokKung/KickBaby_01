import 'package:flutter/material.dart';

/* Import Screen here */
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/data_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KickBaby Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home' : (context) => const HomePage(),
        '/ble_scan' : (context) => const ScanPage(),
        '/data':(context) => const DataPage(),
      },
    );
  }
}
