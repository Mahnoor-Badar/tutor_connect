import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../student/student_dashboard_screen.dart';
import '../tutor/tutor_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('User is not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save user's role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Navigate according to selected role
      if (role == 'tutor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TutorDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to save role');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'How will you use Tutor Connect?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _selectRole('student'),
                child: const Text('I am a Student'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _selectRole('tutor'),
                child: const Text('I am a Tutor'),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 25),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}