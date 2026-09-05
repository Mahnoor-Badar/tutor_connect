import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/tutor_profile.dart';
import '../../services/tutor_service.dart';

class EditTutorProfileScreen extends StatefulWidget {
  final TutorProfile? profile;

  const EditTutorProfileScreen({
    super.key,
    this.profile,
  });

  @override
  State<EditTutorProfileScreen> createState() =>
      _EditTutorProfileScreenState();
}

class _EditTutorProfileScreenState
    extends State<EditTutorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TutorService _service = TutorService();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _subjectController;

  List<String> _subjects = [];

  String _photoUrl = '';

  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoadingProfile = true;

  // Stores the profile loaded from Firestore.
  // This is important because widget.profile can be null.
  TutorProfile? _existingProfile;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _subjectController = TextEditingController();

    _loadProfile();
  }

  // ============================================================
  // LOAD EXISTING PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      // If a profile was passed to this screen, use it.
      if (widget.profile != null) {
        _existingProfile = widget.profile;

        _fillFields(widget.profile!);

        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }

        return;
      }

      // Otherwise get the currently logged-in tutor's profile
      // directly from Firestore through TutorService.
      final profile = await _service.watchOwnProfile().first;

      if (!mounted) return;

      if (profile != null) {
        _existingProfile = profile;

        _fillFields(profile);
      }

      setState(() {
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        'Could not load your profile. Please try again.',
      );
    }
  }

  // Put the saved profile information into the form fields.
  void _fillFields(TutorProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _cityController.text = profile.city;

    _subjects = List<String>.from(profile.subjects);

    _photoUrl = profile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _subjectController.dispose();

    super.dispose();
  }

  // ============================================================
  // IMAGE PICKER + FIREBASE STORAGE
  // ============================================================

  Future<void> _pickPhoto() async {
    if (_isUploading ||
        _isSaving ||
        _isLoadingProfile) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to upload a profile photo.',
      );
      return;
    }

    try {
      final picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final Uint8List imageBytes =
          await pickedFile.readAsBytes();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('tutor_profiles')
          .child('${user.uid}.jpg');

      await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl =
          await storageRef.getDownloadURL();

      if (!mounted) return;

      setState(() {
        _photoUrl = downloadUrl;
      });

      _showMessage(
        'Profile photo uploaded successfully.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Image upload failed: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Image upload failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // SUBJECT MANAGEMENT
  // ============================================================

  void _addSubject() {
    final subject = _subjectController.text.trim();

    if (subject.isEmpty) {
      return;
    }

    final alreadyExists = _subjects.any(
      (existingSubject) =>
          existingSubject.toLowerCase() ==
          subject.toLowerCase(),
    );

    if (alreadyExists) {
      _showMessage(
        'This subject has already been added.',
      );
      return;
    }

    setState(() {
      _subjects.add(subject);
      _subjectController.clear();
    });
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving ||
        _isUploading ||
        _isLoadingProfile) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_subjects.isEmpty) {
      _showMessage(
        'Please add at least one subject.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'You must be logged in to save your profile.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = TutorProfile(
        // Always use the logged-in tutor's UID.
        uid: user.uid,

        name: _nameController.text.trim(),

        bio: _bioController.text.trim(),

        city: _cityController.text.trim(),

        subjects: List<String>.from(_subjects),

        photoUrl: _photoUrl,

        // IMPORTANT:
        // Keep the existing rating information when editing.
        avgRating: _existingProfile?.avgRating ?? 0.0,

        reviewCount:
            _existingProfile?.reviewCount ?? 0,
      );

      await _service.createOrUpdateProfile(
        updatedProfile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tutor profile saved successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        updatedProfile,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not save profile: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not save profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isUploading ||
        _isSaving ||
        _isLoadingProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingProfile == null
              ? 'Create Tutor Profile'
              : 'Edit Tutor Profile',
        ),
      ),

      // --------------------------------------------------------
      // SHOW LOADING WHILE PROFILE IS BEING FETCHED
      // --------------------------------------------------------

      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================================================
                  // PROFILE PHOTO
                  // ==================================================

                  Center(
                    child: GestureDetector(
                      onTap:
                          isBusy ? null : _pickPhoto,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                _photoUrl.isNotEmpty
                                    ? NetworkImage(
                                        _photoUrl,
                                      )
                                    : null,
                            child:
                                _photoUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 55,
                                      )
                                    : null,
                          ),

                          if (_isUploading)
                            const CircleAvatar(
                              radius: 55,
                              backgroundColor:
                                  Colors.black38,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(7),
                              decoration:
                                  const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed:
                          isBusy ? null : _pickPhoto,
                      child: Text(
                        _isUploading
                            ? 'Uploading...'
                            : 'Change Profile Photo',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // NAME
                  // ==================================================

                  TextFormField(
                    controller: _nameController,
                    enabled: !isBusy,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // CITY
                  // ==================================================

                  TextFormField(
                    controller: _cityController,
                    enabled: !isBusy,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your city.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // BIO
                  // ==================================================

                  TextFormField(
                    controller: _bioController,
                    enabled: !isBusy,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(
                      labelText: 'Bio / Experience',
                      hintText:
                          'Tell students about your teaching experience...',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter a short bio.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SUBJECTS
                  // ==================================================

                  const Text(
                    'Subjects',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _subjectController,
                          enabled: !isBusy,
                          textInputAction:
                              TextInputAction.done,
                          onSubmitted: (_) =>
                              _addSubject(),
                          decoration:
                              const InputDecoration(
                            labelText: 'Add Subject',
                            hintText:
                                'e.g. Mathematics',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        height: 56,
                        child: IconButton(
                          onPressed: isBusy
                              ? null
                              : _addSubject,
                          icon: const Icon(
                            Icons.add_circle,
                            size: 36,
                          ),
                          tooltip:
                              'Add subject',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_subjects.isEmpty)
                    const Text(
                      'No subjects added yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _subjects.map(
                        (subject) {
                          return Chip(
                            label: Text(subject),
                            deleteIcon:
                                const Icon(
                              Icons.close,
                            ),
                            onDeleted: isBusy
                                ? null
                                : () =>
                                    _removeSubject(
                                      subject,
                                    ),
                          );
                        },
                      ).toList(),
                    ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // SAVE BUTTON
                  // ==================================================

                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isBusy ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}