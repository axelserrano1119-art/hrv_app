import 'package:flutter/material.dart';

import '../models/wellness_data.dart';
import 'bio_factors_page.dart';

class WellnessInputPage extends StatefulWidget {
  final bool isAdmin;

  const WellnessInputPage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<WellnessInputPage> createState() =>
      _WellnessInputPageState();
}

class _WellnessInputPageState
    extends State<WellnessInputPage> {

  int _sleep = 3;
  int _energy = 3;
  int _stress = 3;
  int _soreness = 3;
  int _fatigue = 3;
  int _overall = 3;

  final TextEditingController _notesController =
      TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _rating(
    String title,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: List.generate(
                5,
                (index) {
                  final rating = index + 1;

                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      child: ChoiceChip(
                        label: Text(
                          '$rating',
                        ),
                        selected:
                            value == rating,
                        onSelected: (_) =>
                            onChanged(rating),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    final wellness = WellnessData(
      sleep: _sleep,
      energy: _energy,
      stress: _stress,
      soreness: _soreness,
      fatigue: _fatigue,
      overall: _overall,
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BioFactorsPage(
          wellness: wellness,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin
              ? 'Admin Wellness'
              : 'Wellness Check',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Please rate each category from 1 to 5.',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),

          const SizedBox(height: 20),

          _rating(
            'Sleep Quality',
            _sleep,
            (v) => setState(() => _sleep = v),
          ),

          _rating(
            'Energy',
            _energy,
            (v) => setState(() => _energy = v),
          ),

          _rating(
            'Stress',
            _stress,
            (v) => setState(() => _stress = v),
          ),

          _rating(
            'Muscle Soreness',
            _soreness,
            (v) => setState(() => _soreness = v),
          ),

          _rating(
            'Fatigue',
            _fatigue,
            (v) => setState(() => _fatigue = v),
          ),

          _rating(
            'Overall Wellness',
            _overall,
            (v) => setState(() => _overall = v),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Additional Notes',
              hintText:
                  'Anything else you would like to report?',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            child: const Text(
              'Continue to Bio-Factors',
              style: TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}