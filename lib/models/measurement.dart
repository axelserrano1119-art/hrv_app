import 'dart:convert';

import 'wellness_data.dart';
import 'bio_factor.dart';

class Measurement {
  final String userId;
  final String userName;

  final String id;
  final DateTime timestamp;
  final double heartRate;

  final double hrvRmssd;

  final double? hrvSdnn;
  final double? hrvPnn50;
  final double? hrvSd1;
  final double? hrvSd2;
  final double? lfPower;
  final double? hfPower;
  final double? lfhfRatio;

  final List<double> rrIntervals;
  final List<double> bpmHistory;

  final double qualityScore;
  final bool valid;
  final int durationSeconds;
  final String? notes;

  // NEW
  final WellnessData? wellness;
  final List<BioFactor> bioFactors;

  Measurement({
    String? id,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.heartRate,

    this.hrvRmssd = 0.0,

    this.hrvSdnn,
    this.hrvPnn50,
    this.hrvSd1,
    this.hrvSd2,
    this.lfPower,
    this.hfPower,
    this.lfhfRatio,

    this.rrIntervals = const [],
    this.bpmHistory = const [],

    this.qualityScore = 0.0,
    this.valid = true,
    this.durationSeconds = 45,
    this.notes,

    this.wellness,
    this.bioFactors = const [],
  }) : id =
          id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
      'heart_rate': heartRate,
      'hrv_rmssd': hrvRmssd,
      'hrv_sdnn': hrvSdnn,
      'hrv_pnn50': hrvPnn50,
      'hrv_sd1': hrvSd1,
      'hrv_sd2': hrvSd2,
      'lf_power': lfPower,
      'hf_power': hfPower,
      'lf_hf_ratio': lfhfRatio,
      'rr_intervals': rrIntervals,
      'bpm_history': bpmHistory,
      'quality_score': qualityScore,
      'valid': valid,
      'duration_seconds': durationSeconds,
      'notes': notes,

      // NEW
      'wellness': wellness?.toJson(),
      'bio_factors':
          bioFactors.map((factor) => factor.toJson()).toList(),
    };
  }

  factory Measurement.fromJson(
    Map<String, dynamic> json,
  ) {
    return Measurement(
      id: json['id']?.toString(),

      userId:
          json['user_id']?.toString() ?? '',

      userName:
          json['user_name']?.toString() ?? '',

      timestamp:
          DateTime.parse(
        json['timestamp'].toString(),
      ),

      heartRate:
          (json['heart_rate'] ?? 0).toDouble(),

      hrvRmssd:
          (json['hrv_rmssd'] ?? 0).toDouble(),

      hrvSdnn:
          json['hrv_sdnn']?.toDouble(),

      hrvPnn50:
          json['hrv_pnn50']?.toDouble(),

      hrvSd1:
          json['hrv_sd1']?.toDouble(),

      hrvSd2:
          json['hrv_sd2']?.toDouble(),

      lfPower:
          json['lf_power']?.toDouble(),

      hfPower:
          json['hf_power']?.toDouble(),

      lfhfRatio:
          json['lf_hf_ratio']?.toDouble(),

      rrIntervals:
          List<double>.from(
        json['rr_intervals'] ?? const [],
      ),

      bpmHistory:
          List<double>.from(
        json['bpm_history'] ?? const [],
      ),

      qualityScore:
          (json['quality_score'] ?? 0).toDouble(),

      valid:
          json['valid'] ?? true,

      durationSeconds:
          json['duration_seconds'] ?? 45,

      notes:
          json['notes']?.toString(),

      wellness:
          json['wellness'] != null
              ? WellnessData.fromJson(
                  Map<String, dynamic>.from(
                    json['wellness'],
                  ),
                )
              : null,

      bioFactors:
          (json['bio_factors'] as List?)
                  ?.map(
                    (item) => BioFactor.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList() ??
              const [],
    );
  }

  String encode() {
    return jsonEncode(toJson());
  }

  static Measurement decode(
    String source,
  ) {
    return Measurement.fromJson(
      jsonDecode(source),
    );
  }
}