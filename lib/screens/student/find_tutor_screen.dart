import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/tutor_profile.dart';
import 'tutor_profile_screen.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase().trim();
      });
    });
  }

  List<TutorProfile> _filterTutors(List<TutorProfile> tutors) {
    if (_searchText.isEmpty) {
      return tutors;
    }

    return tutors.where((tutor) {
      final name = tutor.name.toLowerCase();
      final subjects = tutor.subjects.join(' ').toLowerCase();
      final city = tutor.city.toLowerCase();

      return name.contains(_searchText) ||
          subjects.contains(_searchText) ||
          city.contains(_searchText);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tutor, subject or city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tutors')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Unable to load tutors.\n\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final tutors = snapshot.data?.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return TutorProfile.fromMap(
                          doc.id,
                          data,
                        );
                      }).toList() ??
                      [];

                  final filteredTutors = _filterTutors(tutors);

                  if (filteredTutors.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tutors found.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTutors.length,
                    itemBuilder: (context, index) {
                      return _TutorCard(
                        tutor: filteredTutors[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  final TutorProfile tutor;

  const _TutorCard({
    required this.tutor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: tutor.photoUrl.isNotEmpty
                  ? NetworkImage(tutor.photoUrl)
                  : null,
              child: tutor.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutor.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    tutor.subjects.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 18),
                      const SizedBox(width: 4),
                      Text(tutor.avgRating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tutor.city,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorProfileScreen(
                      tutor: tutor,
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