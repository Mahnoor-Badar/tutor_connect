import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/tutor/tutor_dashboard_screen.dart';
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
    return const MaterialApp(
      title: 'TutorConnect',
      home: AuthGate(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snap.data;
        if (user == null) {
          // Replace with your actual LoginScreen widget/import when ready
          return const Scaffold(body: Center(child: Text('Login screen goes here')));
        }
        
        // Pass the user ID safely down to RoleGate
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
        // Handle connection waiting state
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Handle errors or non-existent user documents safely
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Choose role screen goes here')));
        }

        final data = snap.data!.data() as Map<String, dynamic>?;
        final role = data?['role'];

        if (role == 'tutor') {
          return const TutorDashboardScreen();
        } else if (role == 'student') {
          return const Scaffold(body: Center(child: Text('Student home (Member A)')));
        } else {
          return const Scaffold(body: Center(child: Text('Choose role screen goes here')));
        }
      },
    );
  }
}