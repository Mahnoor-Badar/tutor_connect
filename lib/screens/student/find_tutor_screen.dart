import 'package:flutter/material.dart';
import 'tutor_profile_screen.dart';

class FindTutorScreen extends StatelessWidget {
  const FindTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Tutor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search subject or tutor',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Available Tutors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView(
                children: [
                  _TutorCard(
                    name: 'Tutor Name',
                    subject: 'Mathematics',
                    rating: '4.8',
                  ),
                  _TutorCard(
                    name: 'Tutor Name',
                    subject: 'Programming',
                    rating: '4.7',
                  ),
                  _TutorCard(
                    name: 'Tutor Name',
                    subject: 'Physics',
                    rating: '4.9',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final String name;
  final String subject;
  final String rating;

  const _TutorCard({
    required this.name,
    required this.subject,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(subject),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18),
                      const SizedBox(width: 4),
                      Text(rating),
                    ],
                  ),
                ],
              ),
            ),

            ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorProfileScreen(
          tutorName: name,
          subject: subject,
          rating: rating,
        ),
      ),
    );
  },
  child: const Text('View'),
),
          ],
        ),
      ),
    );
  }
}