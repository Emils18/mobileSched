import 'package:supabase_flutter/supabase_flutter.dart';

class HubAnnouncement {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String tag;
  final String? imageUrl;
  final bool pinned;
  final DateTime publishedAt;
  final DateTime createdAt;

  const HubAnnouncement({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.tag,
    required this.imageUrl,
    required this.pinned,
    required this.publishedAt,
    required this.createdAt,
  });

  factory HubAnnouncement.fromMap(Map<String, dynamic> map) {
    final rawImage = map['image_url']?.toString().trim();

    return HubAnnouncement(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      tag: map['tag']?.toString() ?? 'Announcement',
      imageUrl: rawImage == null || rawImage.isEmpty ? null : rawImage,
      pinned: map['pinned'] == true,
      publishedAt:
          DateTime.tryParse(map['published_at']?.toString() ?? '') ??
              DateTime.now(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class BirthdayCelebrant {
  final String id;
  final String name;
  final String month;
  final String department;
  final String? imageUrl;

  const BirthdayCelebrant({
    required this.id,
    required this.name,
    required this.month,
    required this.department,
    required this.imageUrl,
  });

  factory BirthdayCelebrant.fromMap(Map<String, dynamic> map) {
    final rawImage = map['img_url']?.toString().trim();
    final rawMonth = map['month']?.toString().trim() ?? '';

    return BirthdayCelebrant(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString().trim() ?? '',
      month: _normalizeMonth(rawMonth),
      department: map['department']?.toString().trim().isNotEmpty == true
          ? map['department'].toString().trim()
          : '—',
      imageUrl: rawImage == null || rawImage.isEmpty ? null : rawImage,
    );
  }

  int get monthNumber => _monthNumber(month);

  bool get isCurrentMonth => monthNumber == DateTime.now().month;

  static String _normalizeMonth(String value) {
    final monthNumber = _monthNumber(value);
    if (monthNumber == 0) return value.trim();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[monthNumber - 1];
  }

  static int _monthNumber(String value) {
    final clean = value.trim().toLowerCase();

    const monthMap = <String, int>{
      '1': 1,
      '01': 1,
      'jan': 1,
      'january': 1,
      '2': 2,
      '02': 2,
      'feb': 2,
      'february': 2,
      '3': 3,
      '03': 3,
      'mar': 3,
      'march': 3,
      '4': 4,
      '04': 4,
      'apr': 4,
      'april': 4,
      '5': 5,
      '05': 5,
      'may': 5,
      '6': 6,
      '06': 6,
      'jun': 6,
      'june': 6,
      '7': 7,
      '07': 7,
      'jul': 7,
      'july': 7,
      '8': 8,
      '08': 8,
      'aug': 8,
      'august': 8,
      '9': 9,
      '09': 9,
      'sep': 9,
      'sept': 9,
      'september': 9,
      '10': 10,
      'oct': 10,
      'october': 10,
      '11': 11,
      'nov': 11,
      'november': 11,
      '12': 12,
      'dec': 12,
      'december': 12,
    };

    return monthMap[clean] ?? 0;
  }
}

class HubContentService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<HubAnnouncement>> watchAnnouncements() {
    return _client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final announcements =
          rows.map((row) => HubAnnouncement.fromMap(row)).toList();

      announcements.sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }

        final publishedCompare = b.publishedAt.compareTo(a.publishedAt);

        if (publishedCompare != 0) {
          return publishedCompare;
        }

        return b.createdAt.compareTo(a.createdAt);
      });

      return announcements;
    });
  }

  Stream<List<BirthdayCelebrant>> watchCelebrants() {
    return _client
        .from('celebrations')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final celebrants = rows
          .map((row) => BirthdayCelebrant.fromMap(row))
          .where((person) => person.monthNumber != 0)
          .toList();

      celebrants.sort((a, b) {
        final monthCompare = a.monthNumber.compareTo(b.monthNumber);
        if (monthCompare != 0) return monthCompare;

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return celebrants;
    });
  }
}
