import 'package:flutter/material.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/splash_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/login_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/accepted_trips_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/active_trip_screen.dart';
import 'package:metty_driver_novo/features/driver/presentation/screens/driver_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'METY Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.purple,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DriverHomeScreen(),
        '/accepted-trips': (context) => const AcceptedTripsScreen(),
        '/history': (context) => const DriverHistoryScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/active-trip') {
          final trip = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ActiveTripScreen(trip: trip),
          );
        }
        return null;
      },
    );
  }
}
