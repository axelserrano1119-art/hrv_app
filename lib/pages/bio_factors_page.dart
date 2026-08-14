import 'package:flutter/material.dart';

import '../models/bio_factor.dart';
import '../models/wellness_data.dart';
import '../instructions_page.dart';

class BioFactorsPage extends StatefulWidget {
  final WellnessData wellness;
  final bool isAdmin;

  const BioFactorsPage({
    super.key,
    required this.wellness,
    this.isAdmin = false,
  });

  @override
  State<BioFactorsPage> createState() =>
      _BioFactorsPageState();
}

class _BioFactorsPageState
    extends State<BioFactorsPage> {

  final List<BioFactor> _factors = [];

  final List<String> _bodyParts = const [
    'Head',
    'Neck',
    'Left Shoulder',
    'Right Shoulder',
    'Chest',
    'Upper Back',
    'Lower Back',
    'Left Elbow',
    'Right Elbow',
    'Left Wrist',
    'Right Wrist',
    'Left Hand',
    'Right Hand',
    'Abdomen',
    'Left Hip',
    'Right Hip',
    'Left Thigh',
    'Right Thigh',
    'Left Knee',
    'Right Knee',
    'Left Calf',
    'Right Calf',
    'Left Ankle',
    'Right Ankle',
    'Left Foot',
    'Right Foot',
  ];

  void _selectBodyPart(String bodyPart) {
    String issue = 'Pain';
    int severity = 1;
    String notes = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(bodyPart),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: issue,
                      decoration:
                          const InputDecoration(
                        labelText: 'Issue',
                      ),
                      items: const [
                        'Pain',
                        'Injury',
                        'Soreness',
                        'Tightness',
                        'Swelling',
                        'Other',
                      ].map(
                        (value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => issue = value,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    const Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Severity',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: severity.toDouble(),
                      label: '$severity',
                      onChanged: (value) {
                        setDialogState(
                          () => severity =
                              value.round(),
                        );
                      },
                    ),

                    TextField(
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Additional notes',
                      ),
                      onChanged: (value) {
                        notes = value;
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                  ),
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _factors.removeWhere(
                        (factor) =>
                            factor.bodyPart ==
                            bodyPart,
                      );

                      _factors.add(
                        BioFactor(
                          bodyPart: bodyPart,
                          issue: issue,
                          severity: severity,
                          notes:
                              notes.trim().isEmpty
                                  ? null
                                  : notes.trim(),
                        ),
                      );
                    });

                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bodyButton(
    String label,
  ) {
    final selected = _factors.any(
      (factor) =>
          factor.bodyPart == label,
    );

    return GestureDetector(
      onTap: () => _selectBodyPart(label),

      child: Container(
        margin: const EdgeInsets.all(4),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.redAccent
              : Colors.grey[800],
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.redAccent
                : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstructionsPage(
          isAdmin: widget.isAdmin,
          wellness: widget.wellness,
          bioFactors: _factors,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio-Factors'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Physical Factors',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select any areas where you have pain, injury, soreness, or another physical concern.',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),

          const SizedBox(height: 24),

          Card(
            color: Colors.grey[900],
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.accessibility_new,
                    size: 110,
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    alignment:
                        WrapAlignment.center,
                    children: [
                      ..._bodyParts.map(
                        _bodyButton,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_factors.isNotEmpty)
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Factors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ..._factors.map(
                      (factor) {
                        return ListTile(
                          leading:
                              const Icon(
                            Icons.warning_amber,
                            color:
                                Colors.orange,
                          ),
                          title: Text(
                            factor.bodyPart,
                          ),
                          subtitle: Text(
                            '${factor.issue} • Severity ${factor.severity}/5',
                          ),
                          trailing:
                              IconButton(
                            icon:
                                const Icon(
                              Icons.delete,
                            ),
                            onPressed: () {
                              setState(() {
                                _factors
                                    .remove(
                                  factor,
                                );
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _continue,
            style:
                ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            child: const Text(
              'Continue to Test Instructions',
              style: TextStyle(
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}