class WellnessData {
  final int sleep;
  final int energy;
  final int stress;
  final int soreness;
  final int fatigue;
  final int overall;
  final String? notes;

  const WellnessData({
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.soreness,
    required this.fatigue,
    required this.overall,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'sleep': sleep,
      'energy': energy,
      'stress': stress,
      'soreness': soreness,
      'fatigue': fatigue,
      'overall': overall,
      'notes': notes,
    };
  }

  factory WellnessData.fromJson(Map<String, dynamic> json) {
    return WellnessData(
      sleep: (json['sleep'] ?? 0).toInt(),
      energy: (json['energy'] ?? 0).toInt(),
      stress: (json['stress'] ?? 0).toInt(),
      soreness: (json['soreness'] ?? 0).toInt(),
      fatigue: (json['fatigue'] ?? 0).toInt(),
      overall: (json['overall'] ?? 0).toInt(),
      notes: json['notes']?.toString(),
    );
  }
}