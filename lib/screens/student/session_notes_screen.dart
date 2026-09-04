import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../services/session_note_service.dart';
import '../../services/openrouter_service.dart';

class SessionNotesScreen extends StatefulWidget {
  final Booking session;

  const SessionNotesScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionNotesScreen> createState() => _SessionNotesScreenState();
}

class _SessionNotesScreenState extends State<SessionNotesScreen> {
  final _notesController = TextEditingController();
  final _service = SessionNoteService();
  final _aiService = OpenRouterService();

  bool _isSaving = false;
  bool _isGenerating = false;
  String _aiSummary = '';

  Future<void> _saveNote() async {
    final notes = _notesController.text.trim();

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some notes first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveNote(
        bookingId: widget.session.id,
        tutorId: widget.session.tutorId,
        notes: notes,
      );

      _notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateAiSummary() async {
    final notes = _notesController.text.trim();

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your session notes first.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _aiSummary = '';
    });

    try {
      final summary = await _aiService.summarizeNotes(notes);

      if (mounted) {
        setState(() {
          _aiSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Notes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.subject,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${widget.session.date.day}/'
              '${widget.session.date.month}/'
              '${widget.session.date.year} • '
              '${widget.session.time}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'What did you learn?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Write your session notes here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save Notes button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(),
                      )
                    : const Text(
                        'Save Notes',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // AI Summary button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isGenerating ? null : _generateAiSummary,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating
                      ? 'Generating...'
                      : 'Generate AI Summary',
                ),
              ),
            ),

            // AI Summary
            if (_aiSummary.isNotEmpty) ...[
              const SizedBox(height: 24),

              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_aiSummary),
                ),
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'Previous Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder(
                stream: _service.watchNotes(widget.session.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load notes.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final notes = snapshot.data ?? [];

                  if (notes.isEmpty) {
                    return const Center(
                      child: Text('No previous notes.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(note.notes),
                        ),
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