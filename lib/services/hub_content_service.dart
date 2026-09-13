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
  final DateTime birthdate;
  final String department;
  final String? imageUrl;

  const BirthdayCelebrant({
    required this.id,
    required this.name,
    required this.birthdate,
    required this.department,
    required this.imageUrl,
  });

  factory BirthdayCelebrant.fromMap(Map<String, dynamic> map) {
    final rawImage = map['img_url']?.toString().trim();

    return BirthdayCelebrant(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      birthdate:
          DateTime.tryParse(map['birthdate']?.toString() ?? '') ??
              DateTime.now(),
      department: map['department']?.toString() ?? '—',
      imageUrl: rawImage == null || rawImage.isEmpty ? null : rawImage,
    );
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

        final publishedCompare =
            b.publishedAt.compareTo(a.publishedAt);

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
      final celebrants =
          rows.map((row) => BirthdayCelebrant.fromMap(row)).toList();

      celebrants.sort((a, b) {
        final monthCompare =
            a.birthdate.month.compareTo(b.birthdate.month);

        if (monthCompare != 0) {
          return monthCompare;
        }

        return a.birthdate.day.compareTo(b.birthdate.day);
      });

      return celebrants;
    });
  }
}