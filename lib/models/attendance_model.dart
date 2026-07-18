import 'dart:convert';

class AttendanceModel {
  final String id;
  final DateTime timestamp;
  final String type;
  final String status;
  final String? accomplishment;
  final String? formStatus;

  const AttendanceModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.status,
    this.accomplishment,
    this.formStatus,
  });

  String get date {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');

    return '${timestamp.year}-$month-$day';
  }

  bool get isClockIn => type == 'in';

  bool get isClockOut => type == 'out';

  AttendanceModel copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    String? status,
    String? accomplishment,
    String? formStatus,
    bool clearAccomplishment = false,
    bool clearFormStatus = false,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      accomplishment: clearAccomplishment
          ? null
          : accomplishment ?? this.accomplishment,
      formStatus: clearFormStatus ? null : formStatus ?? this.formStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'status': status,
      'accomplishment': accomplishment,
      'formStatus': formStatus,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    final timestampValue = map['timestamp']?.toString();
    final parsedTimestamp = DateTime.tryParse(timestampValue ?? '');

    if (parsedTimestamp == null) {
      throw const FormatException('Invalid attendance timestamp.');
    }

    final rawType = map['type']?.toString().toLowerCase();
    final validType = rawType == 'out' ? 'out' : 'in';

    return AttendanceModel(
      id: map['id']?.toString() ?? '',
      timestamp: parsedTimestamp,
      type: validType,
      status: map['status']?.toString() ?? 'UNKNOWN',
      accomplishment: _nullableString(map['accomplishment']),
      formStatus: _nullableString(map['formStatus']),
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory AttendanceModel.fromJson(String source) {
    final decoded = jsonDecode(source);

    if (decoded is! Map) {
      throw const FormatException('Invalid attendance data.');
    }

    return AttendanceModel.fromMap(
      Map<String, dynamic>.from(decoded),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }
}