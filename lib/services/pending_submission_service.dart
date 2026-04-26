import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingSubmission {
  final String logId;
  final String type; // 'in' or 'out'
  final String url;

  PendingSubmission({
    required this.logId,
    required this.type,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
        'logId': logId,
        'type': type,
        'url': url,
      };

  factory PendingSubmission.fromMap(Map<String, dynamic> map) =>
      PendingSubmission(
        logId: map['logId'],
        type: map['type'],
        url: map['url'],
      );

  String toJson() => json.encode(toMap());
  factory PendingSubmission.fromJson(String source) =>
      PendingSubmission.fromMap(json.decode(source));
}

class PendingSubmissionService {
  static final PendingSubmissionService _instance =
      PendingSubmissionService._internal();
  factory PendingSubmissionService() => _instance;
  PendingSubmissionService._internal();

  static const String _key = 'pending_form_submission';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  PendingSubmission? get pending {
    final data = _prefs.getString(_key);
    if (data == null) return null;
    return PendingSubmission.fromJson(data);
  }

  Future<void> setPending(PendingSubmission submission) async {
    await _prefs.setString(_key, submission.toJson());
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}