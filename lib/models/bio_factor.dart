class BioFactor {
  final String bodyPart;
  final String issue;
  final int severity;
  final String? notes;

  const BioFactor({
    required this.bodyPart,
    required this.issue,
    required this.severity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'bodyPart': bodyPart,
      'issue': issue,
      'severity': severity,
      'notes': notes,
    };
  }

  factory BioFactor.fromJson(Map<String, dynamic> json) {
    return BioFactor(
      bodyPart: json['bodyPart']?.toString() ?? '',
      issue: json['issue']?.toString() ?? '',
      severity: (json['severity'] ?? 0).toInt(),
      notes: json['notes']?.toString(),
    );
  }
}