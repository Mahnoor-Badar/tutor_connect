import 'package:flutter/material.dart';
import '../../theme.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Explore Tutors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: AppTheme.yellow),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color.fromARGB(255, 226, 194, 10)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.yellow,
                    child: Icon(Icons.person_rounded, color: AppTheme.black, size: 35),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Welcome back, Student!',
                        style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Book your next session today',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryCard(Icons.code_rounded, 'Coding'),
                _buildCategoryCard(Icons.calculate_rounded, 'Math'),
                _buildCategoryCard(Icons.science_rounded, 'Science'),
                _buildCategoryCard(Icons.translate_rounded, 'Languages'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label) {
    return Material(
      color: AppTheme.darkGrey,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.yellow,
        highlightColor: const Color.fromARGB(255, 235, 210, 71),
        onTap: () {},
        child: Container(
          width: 75,
          height: 85,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.yellow, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}