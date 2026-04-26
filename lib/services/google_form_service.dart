import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class GoogleFormService {
  static final GoogleFormService _instance = GoogleFormService._internal();
  factory GoogleFormService() => _instance;
  GoogleFormService._internal();

  late SharedPreferences _prefs;
  static const String _enabledKey = 'google_form_enabled';
  bool _enabled = false; // default OFF for safe testing

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _enabled = _prefs.getBool(_enabledKey) ?? false;
  }

  bool get isEnabled => _enabled;

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs.setBool(_enabledKey, value);
  }

  // The fixed Google Form submission URL
  static const String _formUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLSfFwpdtAEM14JG6l6FlI-sxnwBRlC8A-71HqIgYF8gGyL58gw/formResponse';

  /// Submit Clock In data.
  /// Returns true if success (status 200), false otherwise.
  Future<bool> submitClockIn(TimeOfDay time) async {
    final Map<String, String> body = {
  'entry.311364925': 'Clock In',
  'entry.1072714220_hour': time.hour.toString().padLeft(2, '0'),
  'entry.1072714220_minute': time.minute.toString().padLeft(2, '0'),
  'emailReceipt': 'true',
  'fvv': '1',
  'pageHistory': '0,1,2',
};

    try {
      final response = await http.post(
        
        Uri.parse(_formUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      debugPrint('Google Form Status: ${response.statusCode}');
debugPrint('Google Form Body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
      return response.statusCode == 200;
    } catch (e) {
      
      debugPrint('Google Form Clock In error: $e');
      return false;
    }
  }

  /// Submit Clock Out data with accomplishment.
  /// Returns true if success (status 200), false otherwise.
  Future<bool> submitClockOut(TimeOfDay time, String accomplishment) async {
    final String hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  final Map<String, String> body = {
  'entry.311364925': 'Clock Out',
  'entry.1943230368': hhmm,
  'entry.1843883804': accomplishment,
  'emailReceipt': 'true',
  'fvv': '1',
  'pageHistory': '0,1,3,4',
};

    try {
      final response = await http.post(
        Uri.parse(_formUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      debugPrint('Google Form Status: ${response.statusCode}');
debugPrint('Google Form Body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Google Form Clock Out error: $e');
      return false;
    }
  }
  
}
