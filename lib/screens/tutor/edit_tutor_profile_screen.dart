import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tutor_profile.dart';
import '../../services/tutor_service.dart';

class EditTutorProfileScreen extends StatefulWidget {
  final TutorProfile? existing;
  const EditTutorProfileScreen({super.key, this.existing});

  @override
  State<EditTutorProfileScreen> createState() => _EditTutorProfileScreenState();
}

class _EditTutorProfileScreenState extends State<EditTutorProfileScreen> {
  final _service = TutorService();
  late final _nameCtrl =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _bioCtrl =
      TextEditingController(text: widget.existing?.bio ?? '');
  late final _cityCtrl =
      TextEditingController(text: widget.existing?.city ?? '');
  late final _subjectsCtrl = TextEditingController(
      text: widget.existing?.subjects.join(', ') ?? '');
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.existing?.photoUrl ?? '';
  }

  Future<void> _pickPhoto() async {
    // Plug in image_picker + Firebase Storage upload here.
    // Left as a TODO since your team hasn't confirmed the storage
    // provider yet — the field below just needs a final download URL.
  }

  Future<void> _save() async {
    final profile = TutorProfile(
      uid: FirebaseAuth.instance.currentUser!.uid,
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      subjects: _subjectsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      city: _cityCtrl.text.trim(),
      photoUrl: _photoUrl,
    );
    await _service.createOrUpdateProfile(profile);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundImage:
                    _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                child: _photoUrl.isEmpty ? const Icon(Icons.camera_alt) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          TextField(
            controller: _subjectsCtrl,
            decoration: const InputDecoration(
                labelText: 'Subjects (comma separated)'),
          ),
          TextField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Save Profile')),
        ],
      ),
    );
  }
}