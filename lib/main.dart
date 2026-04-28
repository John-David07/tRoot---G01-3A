import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sensor_detail_screen.dart';
import 'utils/theme_manager.dart';
import 'firebase_options.dart';
import 'screens/sensors_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Only initialize Firebase if not already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore duplicate-app error during hot restart
    if (!e.toString().contains('duplicate-app')) {
      print('Firebase error: $e');
    }
  }
  
  // 🔍 TEST: Try to read data directly from Firebase
  try {
    final database = FirebaseDatabase.instance;
    final ref = database.ref('Current_Data');
    final snapshot = await ref.get();
    print('📦 Data exists: ${snapshot.exists}');
    print('📦 Data value: ${snapshot.value}');
    
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      print('📦 Humidity: ${data['Humidity']}');
      print('📦 Temperature: ${data['Temperature']}');
      print('📦 Soil Moisture: ${data['Soil_Moisture']}');
    }
  } catch (e) {
    print('❌ Firebase read error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Monitor',
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/sensor_detail': (context) => const SensorDetailScreen(),
      },
    );
  }
}