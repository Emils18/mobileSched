import 'dart:convert';

class AttendanceModel {
  final String id;
  final DateTime timestamp;
  final String type; // 'in' or 'out'
  final String status;
  final String? accomplishment;
  final String? formStatus; // null, 'pending', 'submitted', 'not_submitted'

  AttendanceModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.status,
    this.accomplishment,
    this.formStatus,
  });

  String get date =>
      "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'status': status,
        'accomplishment': accomplishment,
        'formStatus': formStatus,
      };

  factory AttendanceModel.fromMap(Map<String, dynamic> map) =>
      AttendanceModel(
        id: map['id'],
        timestamp: DateTime.parse(map['timestamp']),
        type: map['type'],
        status: map['status'],
        accomplishment: map['accomplishment'],
        formStatus: map['formStatus'],
      );

  String toJson() => json.encode(toMap());
  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source));
}