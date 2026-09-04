import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screen Imports
import 'screens/auth/login_screen.dart';
import 'screens/tutor/tutor_dashboard_screen.dart';
import 'screens/student/student_dashboard_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          // If unauthenticated, show the LoginScreen
          return const LoginScreen();
        }

        // Pass authenticated user ID to check role
        return RoleGate(uid: user.uid);
      },
    );
  }
}

class RoleGate extends StatelessWidget {
  final String uid;
  const RoleGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fallback if user doc doesn't exist or hasn't loaded yet
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Role selection pending...')),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>?;
        final role = data?['role'];

        if (role == 'tutor') {
          return const TutorDashboardScreen();
        } else if (role == 'student') {
          return const StudentDashboardScreen();
        } else {
          return const Scaffold(
            body: Center(child: Text('Please select a valid role')),
          );
        }
      },
    );
  }
}