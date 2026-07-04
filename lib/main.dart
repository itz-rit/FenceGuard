import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth/auth_wrapper.dart';
import 'screens/alerts_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable Realtime Database persistence
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  runApp(const FenceGuard());
}

class FenceGuard extends StatelessWidget {
  const FenceGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FenceGuard',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}