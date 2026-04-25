import 'package:intl/intl.dart';

class AttendanceModel {
  final String id;
  final DateTime timeIn;
  final DateTime? timeOut;

  AttendanceModel({
    required this.id,
    required this.timeIn,
    this.timeOut,
  });

  // For display
  String get formattedDate => DateFormat('MMM dd, yyyy').format(timeIn);
  String get formattedTimeIn => DateFormat('hh:mm a').format(timeIn);
  String get formattedTimeOut => timeOut != null ? DateFormat('hh:mm a').format(timeOut!) : '--:-- --';
  String get duration {
    if (timeOut == null) return 'Active';
    final difference = timeOut!.difference(timeIn);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    return '$hours hr ${minutes} min';
  }

  bool get isCompleted => timeOut != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timeIn': timeIn.toIso8601String(),
    'timeOut': timeOut?.toIso8601String(),
  };

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      timeIn: DateTime.parse(json['timeIn']),
      timeOut: json['timeOut'] != null ? DateTime.parse(json['timeOut']) : null,
    );
  }
}