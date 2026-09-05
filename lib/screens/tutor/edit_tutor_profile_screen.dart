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
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F7FC);

  final _formKey = GlobalKey<FormState>();
  final TutorService _service = TutorService();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _subjectController;

  List<String> _subjects = [];
  String _photoUrl = '';

  final List<String> _days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<String> _availableDays = [];

  TimeOfDay? _availableFrom;
  TimeOfDay? _availableTo;

  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoadingProfile = true;

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

  void _fillFields(TutorProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _cityController.text = profile.city;

    _subjects = List<String>.from(profile.subjects);
    _photoUrl = profile.photoUrl;

    _availableDays = List<String>.from(profile.availableDays);

    _availableFrom = _parseTime(profile.availableFrom);
    _availableTo = _parseTime(profile.availableTo);
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  TimeOfDay? _parseTime(String value) {
    if (value.isEmpty) {
      return null;
    }

    try {
      final parts = value.split(':');

      if (parts.length != 2) {
        return null;
      }

      int hour = int.parse(parts[0]);

      final minutePart = parts[1].split(' ');
      int minute = int.parse(minutePart[0]);

      final isPm = value.toUpperCase().contains('PM');
      final isAm = value.toUpperCase().contains('AM');

      if (isPm && hour != 12) {
        hour += 12;
      }

      if (isAm && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return '';
    }

    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _subjectController.dispose();

    super.dispose();
  }

  // ============================================================
  // IMAGE PICKER
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
  // DAY SELECTION
  // ============================================================

  void _toggleDay(String day) {
    setState(() {
      if (_availableDays.contains(day)) {
        _availableDays.remove(day);
      } else {
        _availableDays.add(day);
      }
    });
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _selectFromTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _availableFrom ??
          const TimeOfDay(
            hour: 16,
            minute: 0,
          ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _availableFrom = picked;
    });
  }

  Future<void> _selectToTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _availableTo ??
          const TimeOfDay(
            hour: 20,
            minute: 0,
          ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _availableTo = picked;
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

    if (_availableDays.isEmpty) {
      _showMessage(
        'Please select at least one available day.',
      );
      return;
    }

    if (_availableFrom == null ||
        _availableTo == null) {
      _showMessage(
        'Please select your available time.',
      );
      return;
    }

    final fromMinutes =
        _availableFrom!.hour * 60 +
            _availableFrom!.minute;

    final toMinutes =
        _availableTo!.hour * 60 +
            _availableTo!.minute;

    if (fromMinutes >= toMinutes) {
      _showMessage(
        'The "From" time must be earlier than the "To" time.',
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
        uid: user.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        subjects: List<String>.from(_subjects),
        photoUrl: _photoUrl,
        avgRating: _existingProfile?.avgRating ?? 0.0,
        reviewCount: _existingProfile?.reviewCount ?? 0,
        availableDays:
            List<String>.from(_availableDays),
        availableFrom:
            _formatTime(_availableFrom),
        availableTo:
            _formatTime(_availableTo),
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
        'Could not save profile: '
        '${e.message ?? e.code}',
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: primaryColor,
            ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.red.shade300,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          _existingProfile == null
              ? 'Create Tutor Profile'
              : 'Edit Tutor Profile',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                children: [
                  // ==================================================
                  // PROFILE PHOTO
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap:
                              isBusy ? null : _pickPhoto,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 58,
                                backgroundColor:
                                    primaryColor
                                        .withValues(alpha: 0.10),
                                backgroundImage:
                                    _photoUrl.isNotEmpty
                                        ? NetworkImage(
                                            _photoUrl,
                                          )
                                        : null,
                                child:
                                    _photoUrl.isEmpty
                                        ? const Icon(
                                            Icons
                                                .person_rounded,
                                            size: 55,
                                            color:
                                                primaryColor,
                                          )
                                        : null,
                              ),

                              if (_isUploading)
                                const CircleAvatar(
                                  radius: 58,
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
                                      const EdgeInsets.all(8),
                                  decoration:
                                      const BoxDecoration(
                                    color: primaryColor,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _isUploading
                              ? 'Uploading photo...'
                              : 'Add a profile photo',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'A clear photo helps students recognize you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        TextButton(
                          onPressed:
                              isBusy ? null : _pickPhoto,
                          child: Text(
                            _isUploading
                                ? 'Uploading...'
                                : 'Change Photo',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // BASIC INFORMATION
                  // ==================================================

                  _sectionTitle(
                    'Basic Information',
                    'Tell students who you are.',
                    Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    enabled: !isBusy,
                    textInputAction:
                        TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _cityController,
                    enabled: !isBusy,
                    textInputAction:
                        TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your city.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bioController,
                    enabled: !isBusy,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      label: 'Bio / Experience',
                      hint:
                          'Tell students about your teaching experience...',
                      icon:
                          Icons.description_outlined,
                    ).copyWith(
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

                  const SizedBox(height: 28),

                  // ==================================================
                  // SUBJECTS
                  // ==================================================

                  _sectionTitle(
                    'Subjects',
                    'Add the subjects you can teach.',
                    Icons.menu_book_outlined,
                  ),

                  const SizedBox(height: 16),

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
                          decoration: _inputDecoration(
                            label: 'Add Subject',
                            hint: 'e.g. Mathematics',
                            icon:
                                Icons.subject_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed:
                              isBusy ? null : _addSubject,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Add subject',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_subjects.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color:
                                Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No subjects added yet.',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _subjects.map((subject) {
                        return Chip(
                          label: Text(
                            subject,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                          deleteIcon:
                              const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),
                          onDeleted: isBusy
                              ? null
                              : () =>
                                  _removeSubject(
                                    subject,
                                  ),
                          backgroundColor:
                              primaryColor
                                  .withValues(alpha: 0.10),
                          side: BorderSide.none,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // AVAILABILITY
                  // ==================================================

                  _sectionTitle(
                    'Teaching Availability',
                    'Choose when students can request sessions.',
                    Icons.calendar_month_outlined,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Available Days',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.map((day) {
                      final selected =
                          _availableDays.contains(day);

                      return FilterChip(
                        label: Text(day),
                        selected: selected,
                        onSelected: isBusy
                            ? null
                            : (_) =>
                                _toggleDay(day),
                        selectedColor:
                            primaryColor
                                .withValues(alpha: 0.15),
                        checkmarkColor:
                            primaryColor,
                        labelStyle: TextStyle(
                          color: selected
                              ? primaryColor
                              : Colors.grey.shade700,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        backgroundColor:
                            Colors.white,
                        side: BorderSide(
                          color: selected
                              ? primaryColor
                                  .withValues(alpha: 0.30)
                              : Colors.grey.shade300,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Available Time',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : _selectFromTime,
                          icon: const Icon(
                            Icons.access_time_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _availableFrom == null
                                ? 'From'
                                : _formatTime(
                                    _availableFrom,
                                  ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                primaryColor,
                            backgroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            side: BorderSide(
                              color: primaryColor
                                  .withValues(alpha: 0.25),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      13),
                            ),
                          ),
                        ),
                      ),

                      const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          'to',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : _selectToTime,
                          icon: const Icon(
                            Icons.access_time_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _availableTo == null
                                ? 'To'
                                : _formatTime(
                                    _availableTo,
                                  ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                primaryColor,
                            backgroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            side: BorderSide(
                              color: primaryColor
                                  .withValues(alpha: 0.25),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_availableFrom != null &&
                      _availableTo != null &&
                      (_availableFrom!.hour * 60 +
                              _availableFrom!.minute) >=
                          (_availableTo!.hour * 60 +
                              _availableTo!.minute))
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 10,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color:
                                Colors.red.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'The "From" time must be earlier than the "To" time.',
                              style: TextStyle(
                                color:
                                    Colors.red.shade700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // SAVE BUTTON
                  // ==================================================

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isBusy ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_outlined,
                                  size: 21,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}