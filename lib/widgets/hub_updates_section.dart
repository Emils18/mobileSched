import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
<<<<<<< HEAD

=======
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
import '../services/hub_content_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'glass_card.dart';

class HubUpdatesSection extends StatefulWidget {
  const HubUpdatesSection({super.key});

  @override
  State<HubUpdatesSection> createState() =>
      _HubUpdatesSectionState();
}

class _HubUpdatesSectionState
    extends State<HubUpdatesSection> {
  final HubContentService _service = HubContentService();

  late final Stream<List<HubAnnouncement>> _announcements;
  late final Stream<List<BirthdayCelebrant>> _celebrants;

  StreamSubscription<List<HubAnnouncement>>?
      _announcementSubscription;

  StreamSubscription<List<BirthdayCelebrant>>?
      _celebrantSubscription;

  final Set<String> _knownAnnouncementIds = {};
  final Set<String> _knownCelebrantIds = {};
  final Set<String> _highlightCelebrantIds = {};

  bool _announcementBaselineReady = false;
  bool _celebrantBaselineReady = false;

  String? _highlightAnnouncementId;

  final PageController _birthdayPageController =
      PageController(
    viewportFraction: 0.90,
  );

  int _activeBirthdayIndex = 0;

<<<<<<< HEAD
  static const String _seenAnnouncementKey =
      'hub_seen_announcement_latest';
  static const String _seenBirthdayKey =
      'hub_seen_birthday_signature';

  bool _announcementsExpanded = false;
  bool _birthdaysExpanded = false;

  bool _announcementHasUnread = false;
  bool _birthdayHasUnread = false;
  bool _readStateReady = false;

  String? _lastSeenAnnouncementId;
  String? _lastSeenBirthdaySignature;
  String? _latestAnnouncementId;
  String? _latestBirthdaySignature;
=======
static const String _seenAnnouncementKey =
    'hub_seen_announcement_latest';

static const String _seenBirthdayKey =
    'hub_seen_birthday_signature';

bool _announcementsExpanded = false;
bool _birthdaysExpanded = false;

bool _announcementHasUnread = false;
bool _birthdayHasUnread = false;
bool _readStateReady = false;

String? _lastSeenAnnouncementId;
String? _lastSeenBirthdaySignature;

String? _latestAnnouncementId;
String? _latestBirthdaySignature;

>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)

  @override
  void initState() {
    super.initState();
unawaited(_loadReadState());


    unawaited(_loadReadState());

    _announcements =
        _service.watchAnnouncements();

    _celebrants =
        _service.watchCelebrants();

    _announcementSubscription =
        _announcements.listen(
      _handleAnnouncementUpdates,
      onError: (Object error) {
        debugPrint(
          'Announcement stream error: $error',
        );
      },
    );

    _celebrantSubscription =
        _celebrants.listen(
      _handleCelebrantUpdates,
      onError: (Object error) {
        debugPrint(
          'Celebration stream error: $error',
        );
      },
    );
  }
Future<void> _loadReadState() async {
  final prefs =
      await SharedPreferences.getInstance();

<<<<<<< HEAD
  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _lastSeenAnnouncementId =
          prefs.getString(_seenAnnouncementKey);
      _lastSeenBirthdaySignature =
          prefs.getString(_seenBirthdayKey);
      _readStateReady = true;

      _announcementHasUnread =
          _latestAnnouncementId != null &&
              _latestAnnouncementId !=
                  _lastSeenAnnouncementId;

      _birthdayHasUnread =
          _latestBirthdaySignature != null &&
              _latestBirthdaySignature !=
                  _lastSeenBirthdaySignature;
    });
  }

  void _updateAnnouncementUnread(
    List<HubAnnouncement> announcements,
  ) {
    if (announcements.isEmpty) {
      _latestAnnouncementId = null;

      if (_readStateReady &&
          _announcementHasUnread &&
          mounted) {
        setState(() {
          _announcementHasUnread = false;
        });
      }

      return;
    }

    final byDate =
        List<HubAnnouncement>.from(announcements)
          ..sort(
            (a, b) =>
                b.publishedAt.compareTo(a.publishedAt),
          );

    _latestAnnouncementId = byDate.first.id;

    if (!_readStateReady) {
      return;
    }

    if (_announcementsExpanded) {
      unawaited(_markAnnouncementsSeen());
      return;
    }

    final unread =
        _latestAnnouncementId !=
            _lastSeenAnnouncementId;

    if (mounted &&
        _announcementHasUnread != unread) {
      setState(() {
        _announcementHasUnread = unread;
      });
    }
  }

  void _updateBirthdayUnread(
    List<BirthdayCelebrant> celebrants,
  ) {
    final current =
        _currentMonthCelebrants(celebrants);

    final ids = current
        .map((person) => person.id)
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();

    if (ids.isEmpty) {
      _latestBirthdaySignature = null;

      if (_readStateReady &&
          _birthdayHasUnread &&
          mounted) {
        setState(() {
          _birthdayHasUnread = false;
        });
      }

      return;
    }

    final now = DateTime.now();

    _latestBirthdaySignature =
        '${now.year}-${now.month}:${ids.join(',')}';

    if (!_readStateReady) {
      return;
    }

    if (_birthdaysExpanded) {
      unawaited(_markBirthdaysSeen());
      return;
    }

    final unread =
        _latestBirthdaySignature !=
            _lastSeenBirthdaySignature;

    if (mounted &&
        _birthdayHasUnread != unread) {
      setState(() {
        _birthdayHasUnread = unread;
      });
    }
  }

  Future<void> _markAnnouncementsSeen() async {
    final latestId = _latestAnnouncementId;

    if (latestId == null ||
        latestId.isEmpty) {
      return;
    }

    _lastSeenAnnouncementId = latestId;

    if (mounted &&
        _announcementHasUnread) {
=======
  if (!mounted) return;

  setState(() {
    _lastSeenAnnouncementId =
        prefs.getString(
      _seenAnnouncementKey,
    );

    _lastSeenBirthdaySignature =
        prefs.getString(
      _seenBirthdayKey,
    );

    _readStateReady = true;

    _announcementHasUnread =
        _latestAnnouncementId != null &&
            _latestAnnouncementId !=
                _lastSeenAnnouncementId;

    _birthdayHasUnread =
        _latestBirthdaySignature != null &&
            _latestBirthdaySignature !=
                _lastSeenBirthdaySignature;
  });
}

void _updateAnnouncementUnread(
  List<HubAnnouncement> announcements,
) {
  if (announcements.isEmpty) {
    _latestAnnouncementId = null;

    if (_readStateReady &&
        _announcementHasUnread &&
        mounted) {
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
      setState(() {
        _announcementHasUnread = false;
      });
    }

<<<<<<< HEAD
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _seenAnnouncementKey,
      latestId,
    );
  }

  Future<void> _markBirthdaysSeen() async {
    final signature =
        _latestBirthdaySignature;

    if (signature == null ||
        signature.isEmpty) {
      return;
    }

    _lastSeenBirthdaySignature =
        signature;

    if (mounted &&
        _birthdayHasUnread) {
=======
    return;
  }

  final byDate =
      List<HubAnnouncement>.from(
    announcements,
  )..sort(
          (a, b) =>
              b.publishedAt.compareTo(
            a.publishedAt,
          ),
        );

  _latestAnnouncementId =
      byDate.first.id;

  if (!_readStateReady) {
    return;
  }

  if (_announcementsExpanded) {
    unawaited(
      _markAnnouncementsSeen(),
    );

    return;
  }

  final unread =
      _latestAnnouncementId !=
          _lastSeenAnnouncementId;

  if (mounted &&
      _announcementHasUnread != unread) {
    setState(() {
      _announcementHasUnread = unread;
    });
  }
}

void _updateBirthdayUnread(
  List<BirthdayCelebrant> celebrants,
) {
  final current =
      _currentMonthCelebrants(
    celebrants,
  );

  final ids = current
      .map(
        (person) => person.id,
      )
      .where(
        (id) => id.isNotEmpty,
      )
      .toList()
    ..sort();

  if (ids.isEmpty) {
    _latestBirthdaySignature = null;

    if (_readStateReady &&
        _birthdayHasUnread &&
        mounted) {
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
      setState(() {
        _birthdayHasUnread = false;
      });
    }

<<<<<<< HEAD
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _seenBirthdayKey,
      signature,
    );
  }

  void _toggleAnnouncements() {
    final opening =
        !_announcementsExpanded;

    setState(() {
      _announcementsExpanded = opening;
    });

    if (opening) {
      unawaited(
        _markAnnouncementsSeen(),
      );
    }
  }

  void _toggleBirthdays() {
    final opening =
        !_birthdaysExpanded;

    setState(() {
      _birthdaysExpanded = opening;
    });

    if (opening) {
      unawaited(
        _markBirthdaysSeen(),
      );
    }
  }

=======
    return;
  }

  final now =
      DateTime.now();

  _latestBirthdaySignature =
      '${now.year}-${now.month}:${ids.join(',')}';

  if (!_readStateReady) {
    return;
  }

  if (_birthdaysExpanded) {
    unawaited(
      _markBirthdaysSeen(),
    );

    return;
  }

  final unread =
      _latestBirthdaySignature !=
          _lastSeenBirthdaySignature;

  if (mounted &&
      _birthdayHasUnread != unread) {
    setState(() {
      _birthdayHasUnread = unread;
    });
  }
}

Future<void>
    _markAnnouncementsSeen() async {
  final latestId =
      _latestAnnouncementId;

  if (latestId == null ||
      latestId.isEmpty) {
    return;
  }

  _lastSeenAnnouncementId =
      latestId;

  if (mounted &&
      _announcementHasUnread) {
    setState(() {
      _announcementHasUnread = false;
    });
  }

  final prefs =
      await SharedPreferences
          .getInstance();

  await prefs.setString(
    _seenAnnouncementKey,
    latestId,
  );
}

Future<void>
    _markBirthdaysSeen() async {
  final signature =
      _latestBirthdaySignature;

  if (signature == null ||
      signature.isEmpty) {
    return;
  }

  _lastSeenBirthdaySignature =
      signature;

  if (mounted &&
      _birthdayHasUnread) {
    setState(() {
      _birthdayHasUnread = false;
    });
  }

  final prefs =
      await SharedPreferences
          .getInstance();

  await prefs.setString(
    _seenBirthdayKey,
    signature,
  );
}

void _toggleAnnouncements() {
  final opening =
      !_announcementsExpanded;

  setState(() {
    _announcementsExpanded =
        opening;
  });

  if (opening) {
    unawaited(
      _markAnnouncementsSeen(),
    );
  }
}

void _toggleBirthdays() {
  final opening =
      !_birthdaysExpanded;

  setState(() {
    _birthdaysExpanded =
        opening;
  });

  if (opening) {
    unawaited(
      _markBirthdaysSeen(),
    );
  }
}
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
  @override
  void dispose() {
    _announcementSubscription?.cancel();
    _celebrantSubscription?.cancel();
    _birthdayPageController.dispose();

    super.dispose();
  }

  void _handleAnnouncementUpdates(
    List<HubAnnouncement> announcements,
  ) {
    _updateAnnouncementUnread(
<<<<<<< HEAD
      announcements,
    );
=======
  announcements,
);
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
    final currentIds =
        announcements
            .map((item) => item.id)
            .toSet();

    if (!_announcementBaselineReady) {
      _knownAnnouncementIds
        ..clear()
        ..addAll(currentIds);

      _announcementBaselineReady = true;
      return;
    }

    final newAnnouncements =
        announcements.where(
      (item) =>
          !_knownAnnouncementIds.contains(
        item.id,
      ),
    ).toList();

    _knownAnnouncementIds
      ..clear()
      ..addAll(currentIds);

    if (newAnnouncements.isEmpty) {
      return;
    }

    final newest =
        newAnnouncements.first;

    if (mounted) {
      setState(() {
        _highlightAnnouncementId =
            newest.id;
      });

      Future<void>.delayed(
        const Duration(
          seconds: 6,
        ),
        () {
          if (!mounted ||
              _highlightAnnouncementId !=
                  newest.id) {
            return;
          }

          setState(() {
            _highlightAnnouncementId =
                null;
          });
        },
      );
    }

    if (kIsWeb) {
      _showWebNotice(
        title: 'New Announcement',
        message: newest.title,
        icon:
            Icons.campaign_rounded,
      );
    } else {
      unawaited(
        NotificationService()
            .showHubNotification(
          id: newest.id,
          title: newest.title,
          body:
              _previewText(newest),
          type: 'announcement',
        ),
      );
    }
  }

  void _handleCelebrantUpdates(
    List<BirthdayCelebrant> celebrants,
  ) {
    _updateBirthdayUnread(
<<<<<<< HEAD
      celebrants,
    );
=======
    celebrants,
  );
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
    final currentMonthCelebrants = _currentMonthCelebrants(celebrants);
    final currentIds = currentMonthCelebrants.map((item) => item.id).toSet();

    // Keep every celebrant for the CURRENT month highlighted for the whole month.
    if (mounted) {
      setState(() {
        _highlightCelebrantIds
          ..clear()
          ..addAll(currentIds);
      });
    }

    if (!_celebrantBaselineReady) {
      _knownCelebrantIds
        ..clear()
        ..addAll(currentIds);

      _celebrantBaselineReady = true;

      // Show the monthly notice once when the app first loads this month's list.
      if (currentMonthCelebrants.isNotEmpty) {
        _triggerBirthdayEffects(
          currentMonthCelebrants,
          showWebBanner: true,
        );
      }
      return;
    }

    final newlyAddedThisMonth = currentMonthCelebrants.where(
      (person) => !_knownCelebrantIds.contains(person.id),
    ).toList();

    _knownCelebrantIds
      ..clear()
      ..addAll(currentIds);

    if (newlyAddedThisMonth.isNotEmpty) {
      _triggerBirthdayEffects(
        currentMonthCelebrants,
        showWebBanner: true,
      );
    }
  }

  List<BirthdayCelebrant> _currentMonthCelebrants(
    List<BirthdayCelebrant> celebrants,
  ) {
    final currentMonth = DateTime.now().month;

    final result = celebrants.where(
      (person) => person.monthNumber == currentMonth,
    ).toList();

    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return result;
  }

  void _triggerBirthdayEffects(
    List<BirthdayCelebrant> people, {
    required bool showWebBanner,
  }) {
    if (people.isEmpty) return;

    final monthName = _fullMonthName(DateTime.now().month);

    if (mounted) {
      setState(() {
        _highlightCelebrantIds.addAll(
          people.map((person) => person.id),
        );
      });
    }

    final names = people
        .map((person) => person.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (kIsWeb) {
      if (showWebBanner) {
        final message = names.length == 1
            ? '${names.first} is celebrating this $monthName! 🎉'
            : '${names.length} working scholars are celebrating this $monthName! 🎉';

        _showWebNotice(
          title: '$monthName Birthday Celebrants',
          message: message,
          icon: Icons.celebration_rounded,
        );
      }
      return;
    }

    unawaited(
      NotificationService().showBirthdayCelebrantsNotificationOncePerMonth(
        monthName: monthName,
        names: names,
      ),
    );
  }

  void _showWebNotice({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        )
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior:
                  SnackBarBehavior
                      .floating,
              duration:
                  const Duration(
                seconds: 4,
              ),
              content: Row(
                children: [
                  Icon(
                    icon,
                    color:
                        Colors.white,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          title,
                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          message,
                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white70,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildAnnouncements(),
        const SizedBox(
          height: 24,
        ),
        _buildBirthdays(),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildDisclosureHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required bool hasUnread,
    required VoidCallback onTap,
    required Color accent,
    int? count,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      borderRadius:
          BorderRadius.circular(20),
      borderColor: hasUnread
          ? accent.withValues(alpha: 0.48)
          : colors.primary.withValues(alpha: 0.16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.72),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 9,
                        height: 9,
                        decoration:
                            BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent
                                  .withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontSize: 10,
                    fontWeight: hasUnread
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: hasUnread
                        ? accent
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (count != null &&
              count > 0) ...[
            const SizedBox(width: 8),
            Container(
              constraints:
                  const BoxConstraints(
                minWidth: 28,
              ),
              height: 28,
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration:
                const Duration(
              milliseconds: 180,
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements() {
    return StreamBuilder<
        List<HubAnnouncement>>(
      stream: _announcements,
      builder:
          (context, snapshot) {
        final items =
            List<HubAnnouncement>.from(
          snapshot.data ??
              const <HubAnnouncement>[],
        )..sort(
                (a, b) =>
                    b.publishedAt
                        .compareTo(
                  a.publishedAt,
                ),
              );

        final visibleItems =
            items.take(3).toList();

        final subtitle = _announcementHasUnread
            ? 'New announcement — tap to open'
            : items.isEmpty
                ? 'Scholar updates and notices'
                : '${items.length} ${items.length == 1 ? 'announcement' : 'announcements'} available';

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildDisclosureHeader(
              icon:
                  Icons.campaign_rounded,
              title: 'Announcements',
              subtitle: subtitle,
              expanded:
                  _announcementsExpanded,
              hasUnread:
                  _announcementHasUnread,
              onTap:
                  _toggleAnnouncements,
              accent:
                  Theme.of(context)
                      .colorScheme
                      .primary,
              count:
                  items.isEmpty
                      ? null
                      : items.length,
            ),

            if (_announcementsExpanded) ...[
              const SizedBox(height: 14),

              if (snapshot
                          .connectionState ==
                      ConnectionState.waiting &&
                  items.isEmpty)
                _messageCard(
                  Icons.cloud_download_outlined,
                  'Loading announcements...',
                )
              else if (snapshot.hasError)
                _messageCard(
                  Icons.cloud_off_rounded,
                  'Unable to load announcements.',
                )
              else if (items.isEmpty)
                _messageCard(
                  Icons.campaign_outlined,
                  'No announcements yet.',
                )
              else ...[
                _announcementCard(
                  visibleItems.first,
                  isLatest: true,
                ),

                if (visibleItems.length > 1) ...[
                  const SizedBox(height: 10),

                  for (final announcement
                      in visibleItems.skip(1)) ...[
                    _compactAnnouncementCard(
                      announcement,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                if (items.length > 1)
                  Align(
                    alignment:
                        Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _showAllAnnouncements(
                          items,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .arrow_forward_rounded,
                        size: 15,
                      ),
                      label:
                          const Text(
                        'View All',
                      ),
                    ),
                  ),
=======
Widget _buildDisclosureHeader({
  required IconData icon,
  required String title,
  required String subtitle,
  required bool expanded,
  required bool hasUnread,
  required VoidCallback onTap,
  required Color accent,
  int? count,
}) {
  final theme =
      Theme.of(context);

  final colors =
      theme.colorScheme;

  return GlassCard(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
    borderRadius:
        BorderRadius.circular(20),
    borderColor: hasUnread
        ? accent.withValues(
            alpha: 0.48,
          )
        : colors.primary.withValues(
            alpha: 0.16,
          ),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                accent,
                accent.withValues(
                  alpha: 0.72,
                ),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: theme
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                  ),

                  if (hasUnread) ...[
                    const SizedBox(
                      width: 8,
                    ),

                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .redAccent,
                        shape:
                            BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .redAccent
                                .withValues(
                              alpha:
                                  0.35,
                            ),
                            blurRadius:
                                8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style: theme
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  fontSize: 10,
                  fontWeight:
                      hasUnread
                          ? FontWeight
                              .w700
                          : FontWeight
                              .w500,
                  color:
                      hasUnread
                          ? accent
                          : null,
                ),
              ),
            ],
          ),
        ),

        if (count != null &&
            count > 0) ...[
          const SizedBox(
            width: 8,
          ),

          Container(
            constraints:
                const BoxConstraints(
              minWidth: 28,
            ),
            height: 28,
            alignment:
                Alignment.center,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 8,
            ),
            decoration:
                BoxDecoration(
              color:
                  accent.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                18,
              ),
              border: Border.all(
                color:
                    accent.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],

        const SizedBox(
          width: 8,
        ),

        AnimatedRotation(
          turns:
              expanded ? 0.5 : 0,
          duration:
              const Duration(
            milliseconds: 180,
          ),
          child: Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color: colors.primary,
            size: 24,
          ),
        ),
      ],
    ),
  );
}


Widget _buildAnnouncements() {
  return StreamBuilder<
      List<HubAnnouncement>>(
    stream: _announcements,
    builder: (context, snapshot) {
      final items =
          List<HubAnnouncement>.from(
        snapshot.data ??
            const <
                HubAnnouncement>[],
      )..sort(
              (a, b) =>
                  b.publishedAt
                      .compareTo(
                a.publishedAt,
              ),
            );

      final visibleItems =
          items.take(3).toList();

      final subtitle =
          _announcementHasUnread
              ? 'New announcement — tap to open'
              : items.isEmpty
                  ? 'Scholar updates and notices'
                  : '${items.length} ${items.length == 1 ? 'announcement' : 'announcements'} available';

      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildDisclosureHeader(
            icon:
                Icons.campaign_rounded,
            title:
                'Announcements',
            subtitle: subtitle,
            expanded:
                _announcementsExpanded,
            hasUnread:
                _announcementHasUnread,
            onTap:
                _toggleAnnouncements,
            accent:
                Theme.of(context)
                    .colorScheme
                    .primary,
            count: items.isEmpty
                ? null
                : items.length,
          ),

          if (_announcementsExpanded) ...[
            const SizedBox(
              height: 14,
            ),

            if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting &&
                items.isEmpty)
              _messageCard(
                Icons
                    .cloud_download_outlined,
                'Loading announcements...',
              )
            else if (snapshot.hasError)
              _messageCard(
                Icons.cloud_off_rounded,
                'Unable to load announcements.',
              )
            else if (items.isEmpty)
              _messageCard(
                Icons
                    .campaign_outlined,
                'No announcements yet.',
              )
            else ...[
              _announcementCard(
                visibleItems.first,
                isLatest: true,
              ),

              if (visibleItems.length >
                  1) ...[
                const SizedBox(
                  height: 10,
                ),

                for (final announcement
                    in visibleItems
                        .skip(1)) ...[
                  _compactAnnouncementCard(
                    announcement,
                  ),

                  const SizedBox(
                    height: 8,
                  ),
                ],
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
              ],

              if (items.length > 1)
                Align(
                  alignment:
                      Alignment
                          .centerRight,
                  child:
                      TextButton.icon(
                    onPressed: () {
                      _showAllAnnouncements(
                        items,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .arrow_forward_rounded,
                      size: 15,
                    ),
                    label:
                        const Text(
                      'View All',
                    ),
                  ),
                ),
            ],
          ],
<<<<<<< HEAD
        );
      },
    );
  }
=======
        ],
      );
    },
  );
}


>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)

Widget _announcementCard(
  HubAnnouncement announcement, {
  required bool isLatest,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final bool isNew =
      _highlightAnnouncementId == announcement.id;

  final String tag = announcement.tag.trim().isEmpty
      ? 'ANNOUNCEMENT'
      : announcement.tag.trim().toUpperCase();

  final Color accent = isNew || isLatest
      ? AppColors.brandOrange
      : colors.primary;

  final Widget card = GlassCard(
    padding: EdgeInsets.zero,
    hasGlow:
        announcement.pinned || isLatest || isNew,
    borderColor: isNew
        ? AppColors.brandOrange.withValues(
            alpha: 0.85,
          )
        : isLatest
            ? colors.primary.withValues(
                alpha: 0.55,
              )
            : announcement.pinned
                ? AppColors.brandOrange.withValues(
                    alpha: 0.50,
                  )
                : colors.primary.withValues(
                    alpha: 0.25,
                  ),
    onTap: () {
      _showAnnouncement(
        announcement,
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================
          // ANNOUNCEMENT HERO
          // =====================================
          if (announcement.imageUrl != null)
            Stack(
              children: [
                Image.network(
                  announcement.imageUrl!,
                  width: double.infinity,
                  height: 195,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            colors.secondary,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    );
                  },
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(
                            alpha: 0.15,
                          ),
                          Colors.black.withValues(
                            alpha: 0.72,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 14,
                  left: 14,
                  child: Wrap(
                    spacing: 7,
                    children: [
                      if (isLatest)
                        _announcementBadge(
                          label: 'LATEST',
                          icon: Icons.bolt_rounded,
                          color:
                              AppColors.brandOrange,
                        ),

                      if (isNew)
                        _announcementBadge(
                          label: 'NEW',
                          icon:
                              Icons.fiber_new_rounded,
                          color: colors.secondary,
                        ),
                    ],
                  ),
                ),

                if (announcement.pinned)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _announcementBadge(
                      label: 'PINNED',
                      icon:
                          Icons.push_pin_rounded,
                      color:
                          AppColors.brandOrange,
                    ),
                  ),

                Positioned(
                  left: 16,
                  bottom: 15,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color:
                              AppColors.brandOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      )
                          .animate(
                            onPlay: (controller) {
                              controller.repeat(
                                reverse: true,
                              );
                            },
                          )
                          .scale(
                            begin: const Offset(
                              0.94,
                              0.94,
                            ),
                            end: const Offset(
                              1.07,
                              1.07,
                            ),
                            duration: 1000.ms,
                          ),

                      const SizedBox(
                        width: 9,
                      ),

                      const Text(
                        'AWS HUB UPDATE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            // =====================================
            // NO IMAGE HERO
            // =====================================
            Container(
              width: double.infinity,
              height: 120,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.secondary,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -35,
                    child: Icon(
                      Icons.campaign_rounded,
                      size: 150,
                      color:
                          Colors.white.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.16,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            17,
                          ),
                          border: Border.all(
                            color: Colors.white
                                .withValues(
                              alpha: 0.20,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      )
                          .animate(
                            onPlay: (controller) {
                              controller.repeat(
                                reverse: true,
                              );
                            },
                          )
                          .scale(
                            begin:
                                const Offset(
                              0.94,
                              0.94,
                            ),
                            end:
                                const Offset(
                              1.06,
                              1.06,
                            ),
                            duration: 1000.ms,
                          ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              isLatest
                                  ? 'LATEST AWS HUB UPDATE'
                                  : 'AWS HUB ANNOUNCEMENT',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                letterSpacing:
                                    0.8,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              'Tap to read the full announcement',
                              style: TextStyle(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: 10,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isLatest)
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .brandOrange,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              const Text(
                            'NEW',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 8,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // =====================================
          // ANNOUNCEMENT DETAILS
          // =====================================
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    8,
                  ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _announcementBadge(
                      label: tag,
                      icon: Icons
                          .campaign_outlined,
                      color: colors.primary,
                    ),

                    if (isNew) ...[
                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            const BoxDecoration(
                          color: AppColors
                              .brandOrange,
                          shape:
                              BoxShape.circle,
                        ),
                      )
                          .animate(
                            onPlay:
                                (controller) {
                              controller.repeat(
                                reverse: true,
                              );
                            },
                          )
                          .fade(
                            begin: 0.20,
                            end: 1,
                            duration: 650.ms,
                          ),
                    ],

                    const Spacer(),

                    if (isLatest)
                      const Text(
                        'NEWEST UPDATE',
                        style: TextStyle(
                          color: AppColors
                              .brandOrange,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  announcement.title,
                  style: theme
                      .textTheme.titleLarge
                      ?.copyWith(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  _previewText(
                    announcement,
                  ),
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme.bodyMedium
                      ?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),

                const SizedBox(
                  height: 17,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_month_rounded,
                        color: accent,
                        size: 15,
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Expanded(
                        child: Text(
                          _announcementDateLabel(
                            announcement
                                .publishedAt,
                          ),
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            colors: [
                              colors.primary,
                              colors.secondary,
                            ],
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors
                                  .primary
                                  .withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 12,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              'OPEN',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                letterSpacing:
                                    0.5,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                              color:
                                  Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget result = card
      .animate()
      .fadeIn(
        duration: 400.ms,
      )
      .slideY(
        begin: 0.05,
        end: 0,
        duration: 450.ms,
        curve:
            Curves.easeOutCubic,
      );

  if (isNew) {
    result = result
        .animate(
          onPlay: (controller) {
            controller.repeat(
              reverse: true,
            );
          },
        )
        .shimmer(
          duration: 1900.ms,
          color: AppColors.brandOrange
              .withValues(
            alpha: 0.10,
          ),
        );
  }

  return result;
}


  Widget _announcementBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              color.withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 11,
            ),
            const SizedBox(
              width: 4,
            ),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight:
                  FontWeight.w900,
              letterSpacing:
                  0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactAnnouncementCard(
    HubAnnouncement announcement,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return GlassCard(
      padding:
          const EdgeInsets.all(
        14,
      ),
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      borderColor:
          announcement.pinned
              ? AppColors
                  .brandOrange
                  .withValues(
                  alpha:
                      0.34,
                )
              : null,
      onTap: () {
        _showAnnouncement(
          announcement,
        );
      },
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  announcement
                          .pinned
                      ? AppColors
                          .brandOrange
                          .withValues(
                          alpha:
                              0.12,
                        )
                      : colors
                          .primary
                          .withValues(
                          alpha:
                              0.11,
                        ),
              borderRadius:
                  BorderRadius
                      .circular(
                14,
              ),
            ),
            child: Icon(
              announcement
                      .pinned
                  ? Icons
                      .push_pin_rounded
                  : Icons
                      .campaign_outlined,
              color:
                  announcement
                          .pinned
                      ? AppColors
                          .brandOrange
                      : colors
                          .primary,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    if (announcement
                        .pinned) ...[
                      const Text(
                        'PINNED',
                        style:
                            TextStyle(
                          color:
                              AppColors
                                  .brandOrange,
                          fontSize:
                              8,
                          fontWeight:
                              FontWeight
                                  .w900,
                          letterSpacing:
                              0.7,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                    ],
                    Expanded(
                      child: Text(
                        _announcementDateLabel(
                          announcement
                              .publishedAt,
                        ),
                        textAlign:
                            TextAlign
                                .end,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontSize:
                              9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  announcement
                      .title,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontSize: 13,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _previewText(
                    announcement,
                  ),
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Icon(
            Icons
                .chevron_right_rounded,
            color: theme
                .textTheme
                .bodySmall
                ?.color,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showAllAnnouncements(
    List<HubAnnouncement>
        announcements,
  ) {
    if (announcements.isEmpty) {
      return;
    }

    final byDate =
        List<HubAnnouncement>.from(
      announcements,
    )..sort(
            (a, b) =>
                b.publishedAt
                    .compareTo(
              a.publishedAt,
            ),
          );

    final String latestId =
        byDate.first.id;

    final displayItems =
        List<HubAnnouncement>.from(
      byDate,
    )..sort(
            (a, b) {
              if (a.pinned !=
                  b.pinned) {
                return a.pinned
                    ? -1
                    : 1;
              }

              return b
                  .publishedAt
                  .compareTo(
                a.publishedAt,
              );
            },
          );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) {
        final theme =
            Theme.of(
          sheetContext,
        );

        final colors =
            theme.colorScheme;

        return DraggableScrollableSheet(
          initialChildSize:
              0.88,
          minChildSize:
              0.58,
          maxChildSize:
              0.96,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration:
                  BoxDecoration(
                color: theme
                    .scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    30,
                  ),
                ),
                border:
                    Border.all(
                  color: theme
                      .dividerColor,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    width: 44,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color: theme
                          .dividerColor,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      18,
                      12,
                      15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration:
                              BoxDecoration(
                            gradient:
                                LinearGradient(
                              colors: [
                                colors
                                    .primary,
                                colors
                                    .secondary,
                              ],
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .campaign_rounded,
                            color: Colors
                                .white,
                            size: 23,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'All Announcements',
                                style: theme
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                              const SizedBox(
                                height:
                                    3,
                              ),
                              Text(
                                '${displayItems.length} ${displayItems.length == 1 ? 'announcement' : 'announcements'}',
                                style: theme
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  fontSize:
                                      10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          icon: Icon(
                            Icons
                                .close_rounded,
                            color: theme
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: theme
                        .dividerColor,
                  ),

                  Expanded(
                    child:
                        ListView
                            .separated(
                      controller:
                          scrollController,
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      physics:
                          const BouncingScrollPhysics(),
                      itemCount:
                          displayItems
                              .length,
                      separatorBuilder:
                          (
                        _,
                        __,
                      ) =>
                              const SizedBox(
                        height:
                            10,
                      ),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final announcement =
                            displayItems[
                                index];

                        final bool latest =
                            announcement.id ==
                                latestId;

                        return GlassCard(
                          padding:
                              const EdgeInsets
                                  .all(
                            15,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            19,
                          ),
                          borderColor:
                              announcement
                                      .pinned
                                  ? AppColors
                                      .brandOrange
                                      .withValues(
                                      alpha:
                                          0.42,
                                    )
                                  : latest
                                      ? colors
                                          .primary
                                          .withValues(
                                          alpha:
                                              0.35,
                                        )
                                      : null,
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                            );

                            Future<void>
                                .delayed(
                              const Duration(
                                milliseconds:
                                    180,
                              ),
                              () {
                                if (mounted) {
                                  _showAnnouncement(
                                    announcement,
                                  );
                                }
                              },
                            );
                          },
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      announcement
                                              .pinned
                                          ? AppColors
                                              .brandOrange
                                              .withValues(
                                              alpha:
                                                  0.12,
                                            )
                                          : colors
                                              .primary
                                              .withValues(
                                              alpha:
                                                  0.10,
                                            ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),
                                child: Icon(
                                  announcement
                                          .pinned
                                      ? Icons
                                          .push_pin_rounded
                                      : Icons
                                          .campaign_outlined,
                                  color:
                                      announcement
                                              .pinned
                                          ? AppColors
                                              .brandOrange
                                          : colors
                                              .primary,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Wrap(
                                      spacing:
                                          6,
                                      runSpacing:
                                          5,
                                      children: [
                                        if (latest)
                                          _announcementBadge(
                                            label:
                                                'LATEST',
                                            icon: Icons
                                                .bolt_rounded,
                                            color:
                                                AppColors
                                                    .brandOrange,
                                          ),

                                        if (announcement
                                            .pinned)
                                          _announcementBadge(
                                            label:
                                                'PINNED',
                                            icon: Icons
                                                .push_pin_rounded,
                                            color:
                                                AppColors
                                                    .brandOrange,
                                          ),

                                        _announcementBadge(
                                          label: announcement
                                                  .tag
                                                  .trim()
                                                  .isEmpty
                                              ? 'ANNOUNCEMENT'
                                              : announcement
                                                  .tag
                                                  .trim()
                                                  .toUpperCase(),
                                          color:
                                              colors
                                                  .primary,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height:
                                          9,
                                    ),

                                    Text(
                                      announcement
                                          .title,
                                      style: theme
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontSize:
                                            14,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          5,
                                    ),

                                    Text(
                                      _previewText(
                                        announcement,
                                      ),
                                      maxLines:
                                          2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style: theme
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        fontSize:
                                            10,
                                        height:
                                            1.35,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          8,
                                    ),

                                    Text(
                                      _announcementDateLabel(
                                        announcement
                                            .publishedAt,
                                      ),
                                      style: theme
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        fontSize:
                                            9,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(
                              delay:
                                  (index *
                                          45)
                                      .ms,
                            )
                            .fadeIn(
                              duration:
                                  300.ms,
                            )
                            .slideY(
                              begin:
                                  0.04,
                              end: 0,
                              duration:
                                  300.ms,
                            );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _announcementDateLabel(
    DateTime date,
  ) {
    final now =
        DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today
            .difference(
              target,
            )
            .inDays;

    final actualDate =
        AppFormatters.formatDate(
      date.toIso8601String(),
    );

    if (difference == 0) {
      return 'Today - $actualDate';
    }

    if (difference == 1) {
      return 'Yesterday - $actualDate';
    }

    return actualDate;
  }

<<<<<<< HEAD
  Widget _buildBirthdays() {
    return StreamBuilder<
        List<BirthdayCelebrant>>(
      stream: _celebrants,
      builder:
          (context, snapshot) {
        final theme =
            Theme.of(context);

        final all =
            snapshot.data ??
                const <BirthdayCelebrant>[];

        final thisMonth =
            _currentMonthCelebrants(
          all,
        );

        final monthName =
            _fullMonthName(
          DateTime.now().month,
        );

        final activeIndex =
            thisMonth.isEmpty
                ? 0
                : _activeBirthdayIndex
                    .clamp(
                      0,
                      thisMonth.length - 1,
                    )
                    .toInt();

        final subtitle = _birthdayHasUnread
            ? 'New birthday update — tap to open'
            : thisMonth.isEmpty
                ? 'No celebrants listed for $monthName yet'
                : '${thisMonth.length} ${thisMonth.length == 1 ? 'celebrant' : 'celebrants'} this month';

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildDisclosureHeader(
              icon:
                  Icons.celebration_rounded,
              title:
                  '$monthName Celebrants',
              subtitle: subtitle,
              expanded:
                  _birthdaysExpanded,
              hasUnread:
                  _birthdayHasUnread,
              onTap:
                  _toggleBirthdays,
              accent:
                  AppColors.brandOrange,
              count:
                  thisMonth.isEmpty
                      ? null
                      : thisMonth.length,
            ),

            if (_birthdaysExpanded) ...[
              const SizedBox(height: 14),

              if (snapshot
                          .connectionState ==
                      ConnectionState.waiting &&
                  all.isEmpty)
                _messageCard(
                  Icons.cake_outlined,
                  'Loading birthday celebrants...',
                )
              else if (snapshot.hasError)
                _messageCard(
                  Icons.cloud_off_rounded,
                  'Unable to load birthday celebrants.',
                )
              else if (thisMonth.isEmpty)
                _messageCard(
                  Icons.celebration_outlined,
                  'No birthday celebrants for $monthName yet.',
                )
              else ...[
                SizedBox(
                  height: 330,
                  child: PageView.builder(
                    controller:
                        _birthdayPageController,
                    itemCount:
                        thisMonth.length,
                    physics:
                        const BouncingScrollPhysics(),
                    onPageChanged:
                        (index) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _activeBirthdayIndex =
                            index;
                      });
                    },
                    itemBuilder:
                        (context, index) {
                      final person =
                          thisMonth[index];

                      final isActive =
                          index ==
                              activeIndex;

                      return Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        child:
                            _birthdayGreetingCard(
                          person,
                          isActive,
                        ),
                      );
                    },
                  ),
                ),

                if (thisMonth.length > 1) ...[
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activeIndex + 1} / ${thisMonth.length}  •  Swipe to view',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _showAllCelebrants(
                        thisMonth,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .arrow_forward_rounded,
                      size: 15,
                    ),
                    label:
                        const Text(
                      'View All',
                    ),
                  ),
=======

Widget _buildBirthdays() {
  return StreamBuilder<
      List<BirthdayCelebrant>>(
    stream: _celebrants,
    builder: (context, snapshot) {
      final theme =
          Theme.of(context);

      final all =
          snapshot.data ??
              const <
                  BirthdayCelebrant>[];

      final thisMonth =
          _currentMonthCelebrants(
        all,
      );

      final monthName =
          _fullMonthName(
        DateTime.now().month,
      );

      final activeIndex =
          thisMonth.isEmpty
              ? 0
              : _activeBirthdayIndex
                  .clamp(
                    0,
                    thisMonth.length -
                        1,
                  )
                  .toInt();

      final subtitle =
          _birthdayHasUnread
              ? 'New birthday update — tap to open'
              : thisMonth.isEmpty
                  ? 'No celebrants listed for $monthName yet'
                  : '${thisMonth.length} ${thisMonth.length == 1 ? 'celebrant' : 'celebrants'} this month';

      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildDisclosureHeader(
            icon:
                Icons
                    .celebration_rounded,
            title:
                '$monthName Celebrants',
            subtitle: subtitle,
            expanded:
                _birthdaysExpanded,
            hasUnread:
                _birthdayHasUnread,
            onTap:
                _toggleBirthdays,
            accent:
                AppColors.brandOrange,
            count:
                thisMonth.isEmpty
                    ? null
                    : thisMonth.length,
          ),

          if (_birthdaysExpanded) ...[
            const SizedBox(
              height: 14,
            ),

            if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting &&
                all.isEmpty)
              _messageCard(
                Icons.cake_outlined,
                'Loading birthday celebrants...',
              )
            else if (snapshot.hasError)
              _messageCard(
                Icons.cloud_off_rounded,
                'Unable to load birthday celebrants.',
              )
            else if (thisMonth.isEmpty)
              _messageCard(
                Icons
                    .celebration_outlined,
                'No birthday celebrants for $monthName yet.',
              )
            else ...[
              SizedBox(
                height: 330,
                child:
                    PageView.builder(
                  controller:
                      _birthdayPageController,
                  itemCount:
                      thisMonth.length,
                  physics:
                      const BouncingScrollPhysics(),
                  onPageChanged:
                      (index) {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _activeBirthdayIndex =
                          index;
                    });
                  },
                  itemBuilder:
                      (context, index) {
                    final person =
                        thisMonth[
                            index];

                    final isActive =
                        index ==
                            activeIndex;

                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      child:
                          _birthdayGreetingCard(
                        person,
                        isActive,
                      ),
                    );
                  },
                ),
              ),

              if (thisMonth.length >
                  1) ...[
                const SizedBox(
                  height: 7,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .swipe_rounded,
                      color: theme
                          .textTheme
                          .bodySmall
                          ?.color,
                      size: 14,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      '${activeIndex + 1} / ${thisMonth.length}  •  Swipe to view',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        fontSize: 9,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
>>>>>>> 35f4d88 (Update AWS HUB announcements, birthdays, iPhone PWA and Android APK)
                ),
              ],

              Align(
                alignment:
                    Alignment
                        .centerRight,
                child:
                    TextButton.icon(
                  onPressed: () {
                    _showAllCelebrants(
                      thisMonth,
                    );
                  },
                  icon:
                      const Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 15,
                  ),
                  label:
                      const Text(
                    'View All',
                  ),
                ),
              ),
            ],
          ],
        ],
      );
    },
  );
}


  void _showAllCelebrants(
    List<BirthdayCelebrant>
        celebrants,
  ) {
    if (celebrants.isEmpty) {
      return;
    }

    final sortedCelebrants = List<BirthdayCelebrant>.from(celebrants)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final now =
        DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize:
              0.86,
          minChildSize:
              0.55,
          maxChildSize:
              0.96,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration:
                  BoxDecoration(
                color:
                    AppColors.bgDeep,
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    30,
                  ),
                ),
                border:
                    Border.all(
                  color: AppColors
                      .cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha:
                          0.35,
                    ),
                    blurRadius:
                        30,
                    offset:
                        const Offset(
                      0,
                      -6,
                    ),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    width: 45,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color: AppColors
                          .cardBorder,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      18,
                      12,
                      14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .orange
                                .withValues(
                              alpha:
                                  0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .cake_rounded,
                            color: AppColors
                                .orange,
                            size: 22,
                          ),
                        )
                            .animate(
                              onPlay:
                                  (controller) =>
                                      controller
                                          .repeat(),
                            )
                            .shimmer(
                              duration:
                                  1700.ms,
                              color: AppColors
                                  .warning
                                  .withValues(
                                alpha:
                                    0.35,
                              ),
                            ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                '${_fullMonthName(now.month)} Celebrants',
                                style:
                                    const TextStyle(
                                  color:
                                      AppColors
                                          .textTitle,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                              const SizedBox(
                                height:
                                    3,
                              ),
                              Text(
                                '${sortedCelebrants.length} ${sortedCelebrants.length == 1 ? 'birthday' : 'birthdays'} this month',
                                style:
                                    const TextStyle(
                                  color:
                                      AppColors
                                          .textMuted,
                                  fontSize:
                                      10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip:
                              'Close',
                          onPressed:
                              () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                            color:
                                AppColors
                                    .textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: AppColors
                        .cardBorder
                        .withValues(
                      alpha: 0.8,
                    ),
                  ),

                  Expanded(
                    child:
                        LayoutBuilder(
                      builder: (
                        context,
                        constraints,
                      ) {
                        int columns =
                            2;

                        if (constraints
                                .maxWidth >=
                            720) {
                          columns =
                              4;
                        } else if (constraints
                                .maxWidth >=
                            520) {
                          columns =
                              3;
                        }

                        return GridView
                            .builder(
                          controller:
                              scrollController,
                          padding:
                              const EdgeInsets
                                  .all(
                            16,
                          ),
                          physics:
                              const BouncingScrollPhysics(),
                          itemCount:
                              sortedCelebrants
                                  .length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                columns,
                            crossAxisSpacing:
                                12,
                            mainAxisSpacing:
                                12,
                            childAspectRatio:
                                0.78,
                          ),
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            final person =
                                sortedCelebrants[
                                    index];

                            return _celebrantGridCard(
                              person,
                            )
                                .animate(
                                  delay:
                                      (index *
                                              55)
                                          .ms,
                                )
                                .fadeIn(
                                  duration:
                                      380.ms,
                                )
                                .scale(
                                  begin:
                                      const Offset(
                                    0.94,
                                    0.94,
                                  ),
                                  end:
                                      const Offset(
                                    1,
                                    1,
                                  ),
                                  duration:
                                      380.ms,
                                  curve: Curves
                                      .easeOutBack,
                                );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                  duration:
                      250.ms,
                )
                .slideY(
                  begin:
                      0.06,
                  end: 0,
                  duration:
                      350.ms,
                  curve: Curves
                      .easeOutCubic,
                );
          },
        );
      },
    );
  }

  Widget _celebrantGridCard(
    BirthdayCelebrant person,
  ) {
    final monthName = _fullMonthName(DateTime.now().month);
    final highlighted = person.monthNumber == DateTime.now().month;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      hasGlow: highlighted,
      borderColor: highlighted
          ? AppColors.orange.withValues(alpha: 0.66)
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: highlighted
                      ? const LinearGradient(
                          colors: [
                            AppColors.brandOrange,
                            Color(0xFFF3A34D),
                          ],
                        )
                      : null,
                  border: highlighted
                      ? null
                      : Border.all(color: AppColors.cardBorder),
                  boxShadow: highlighted
                      ? [
                          BoxShadow(
                            color: AppColors.brandOrange.withValues(alpha: 0.24),
                            blurRadius: 18,
                            spreadRadius: -4,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: person.imageUrl == null
                        ? _avatarFallback(person.name)
                        : Image.network(
                            person.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _avatarFallback(person.name);
                            },
                          ),
                  ),
                ),
              ),
              if (highlighted)
                Positioned(
                  right: -5,
                  bottom: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgDeep, width: 2),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.94, 0.94),
                        end: const Offset(1.06, 1.06),
                        duration: 900.ms,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            person.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            person.department,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.20),
              ),
            ),
            child: Text(
              monthName.toUpperCase(),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }


Widget _birthdayGreetingCard(
  BirthdayCelebrant person,
  bool isActive,
) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final monthName =
      _fullMonthName(DateTime.now().month);

  const accent = AppColors.brandOrange;

  final firstName =
      person.name.trim().isEmpty
          ? 'Scholar'
          : person.name.trim().split(' ').first;

  final Widget card = GlassCard(
    padding: EdgeInsets.zero,
    borderRadius: BorderRadius.circular(28),
    hasGlow: true,
    borderColor: accent.withValues(
      alpha: isActive ? 0.75 : 0.38,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          // =====================================
          // SOFT BACKGROUND EFFECTS
          // =====================================
          Positioned(
            top: -55,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            left: -45,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(
                  alpha: 0.07,
                ),
              ),
            ),
          ),

          Column(
            children: [
              // =====================================
              // BIRTHDAY HEADER
              // =====================================
              Container(
                height: 62,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.brandOrange,
                      Color(0xFFF49A3A),
                      Color(0xFFEF7F1A),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    )
                        .animate(
                          onPlay: (controller) {
                            controller.repeat(
                              reverse: true,
                            );
                          },
                        )
                        .scale(
                          begin: const Offset(
                            0.92,
                            0.92,
                          ),
                          end: const Offset(
                            1.07,
                            1.07,
                          ),
                          duration: 1000.ms,
                        ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIRTHDAY CELEBRANT',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Celebrating our scholar',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Text(
                        monthName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================
              // MAIN CONTENT
              // =====================================
              Expanded(
                child: Stack(
                  children: [
                    // Animated sparkle left
                    Positioned(
                      top: 12,
                      left: 22,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accent.withValues(
                          alpha: 0.55,
                        ),
                        size: 17,
                      )
                          .animate(
                            onPlay: (controller) {
                              controller.repeat(
                                reverse: true,
                              );
                            },
                          )
                          .fade(
                            begin: 0.25,
                            end: 1,
                            duration: 1000.ms,
                          ),
                    ),

                    // Animated star right
                    Positioned(
                      top: 22,
                      right: 25,
                      child: Icon(
                        Icons.star_rounded,
                        color: colors.primary.withValues(
                          alpha: 0.40,
                        ),
                        size: 15,
                      )
                          .animate(
                            onPlay: (controller) {
                              controller.repeat(
                                reverse: true,
                              );
                            },
                          )
                          .scale(
                            begin: const Offset(
                              0.80,
                              0.80,
                            ),
                            end: const Offset(
                              1.12,
                              1.12,
                            ),
                            duration: 1200.ms,
                          ),
                    ),

                    Positioned.fill(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          18,
                          6,
                          18,
                          6,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            // =====================================
                            // PROFILE PHOTO
                            // =====================================
                            Stack(
                              clipBehavior: Clip.none,
                              alignment:
                                  Alignment.center,
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration:
                                      BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient:
                                        LinearGradient(
                                      begin:
                                          Alignment.topLeft,
                                      end: Alignment
                                          .bottomRight,
                                      colors: [
                                        accent,
                                        colors.primary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent
                                            .withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                )
                                    .animate(
                                      onPlay:
                                          (controller) {
                                        controller.repeat(
                                          reverse: true,
                                        );
                                      },
                                    )
                                    .scale(
                                      begin:
                                          const Offset(
                                        0.97,
                                        0.97,
                                      ),
                                      end:
                                          const Offset(
                                        1.03,
                                        1.03,
                                      ),
                                      duration: 1500.ms,
                                    ),

                                Container(
                                  width: 74,
                                  height: 74,
                                  padding:
                                      const EdgeInsets.all(
                                    3,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: theme
                                        .scaffoldBackgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child:
                                        person.imageUrl ==
                                                null
                                            ? _avatarFallback(
                                                person
                                                    .name,
                                              )
                                            : Image.network(
                                                person
                                                    .imageUrl!,
                                                fit:
                                                    BoxFit
                                                        .cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return _avatarFallback(
                                                    person
                                                        .name,
                                                  );
                                                },
                                              ),
                                  ),
                                ),

                                Positioned(
                                  right: -2,
                                  bottom: 0,
                                  child: Container(
                                    width: 27,
                                    height: 27,
                                    decoration:
                                        BoxDecoration(
                                      color: accent,
                                      shape:
                                          BoxShape.circle,
                                      border: Border.all(
                                        color: theme
                                            .scaffoldBackgroundColor,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent
                                              .withValues(
                                            alpha:
                                                0.30,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child:
                                        const Icon(
                                      Icons.cake_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  )
                                      .animate(
                                        onPlay:
                                            (controller) {
                                          controller
                                              .repeat(
                                            reverse: true,
                                          );
                                        },
                                      )
                                      .scale(
                                        begin:
                                            const Offset(
                                          0.90,
                                          0.90,
                                        ),
                                        end:
                                            const Offset(
                                          1.08,
                                          1.08,
                                        ),
                                        duration: 900.ms,
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // =====================================
                            // NAME
                            // =====================================
                            Text(
                              person.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              textAlign:
                                  TextAlign.center,
                              style: theme
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w900,
                                height: 1.05,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // =====================================
                            // DEPARTMENT
                            // =====================================
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 11,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: colors.primary
                                    .withValues(
                                  alpha: 0.09,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                                border: Border.all(
                                  color: colors.primary
                                      .withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Text(
                                person.department,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: theme
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color:
                                      colors.primary,
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // =====================================
                            // CURRENT MONTH BADGE
                            // =====================================
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration:
                                  BoxDecoration(
                                gradient:
                                    LinearGradient(
                                  colors: [
                                    accent.withValues(
                                      alpha: 0.14,
                                    ),
                                    colors.primary
                                        .withValues(
                                      alpha: 0.07,
                                    ),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                border: Border.all(
                                  color:
                                      accent.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .auto_awesome_rounded,
                                    color: accent,
                                    size: 12,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Flexible(
                                    child: Text(
                                      'Celebrating this $monthName',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color: accent,
                                        fontSize: 9,
                                        height: 1,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 5),

                            // =====================================
                            // SHORT MESSAGE
                            // =====================================
                            Text(
                              'Happy birthday month, $firstName!',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              textAlign:
                                  TextAlign.center,
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                fontSize: 9,
                                height: 1,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (!isActive) {
    return card;
  }

  return card
      .animate()
      .fadeIn(
        duration: 350.ms,
      )
      .slideY(
        begin: 0.03,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      )
      .shimmer(
        delay: 600.ms,
        duration: 1800.ms,
        color: accent.withValues(
          alpha: 0.08,
        ),
      );
}

  Widget _avatarFallback(
    String name,
  ) {
    final cleanName =
        name.trim();

    final initial =
        cleanName.isEmpty
            ? '?'
            : cleanName
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      alignment:
          Alignment.center,
      color: AppColors.primary
          .withValues(
        alpha: 0.14,
      ),
      child: Text(
        initial,
        style:
            const TextStyle(
          color:
              AppColors.primary,
          fontSize: 28,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  Widget _messageCard(
    IconData icon,
    String message,
  ) {
    return GlassCard(
      padding:
          const EdgeInsets.all(
        18,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors
                .textMuted,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color: AppColors
                    .textBody,
                fontSize:
                    12,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration:
              350.ms,
        );
  }

  void _showAnnouncement(
    HubAnnouncement announcement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder:
          (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets
                    .only(
              top: 50,
            ),
            child: GlassCard(
              borderRadius:
                  const BorderRadius
                      .vertical(
                top:
                    Radius.circular(
                  28,
                ),
              ),
              padding:
                  const EdgeInsets
                      .all(
                24,
              ),
              child:
                  SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Center(
                      child:
                          Container(
                        width: 45,
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .cardBorder,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    if (announcement
                            .imageUrl !=
                        null) ...[
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                        child:
                            Image.network(
                          announcement
                              .imageUrl!,
                          width: double
                              .infinity,
                          fit:
                              BoxFit
                                  .cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const SizedBox
                                .shrink();
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],

                    Text(
                      announcement
                          .tag
                          .toUpperCase(),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .primary,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight
                                .w900,
                        letterSpacing:
                            1,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      announcement
                          .title,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textTitle,
                        fontSize:
                            24,
                        fontWeight:
                            FontWeight
                                .w900,
                        height:
                            1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      AppFormatters
                          .formatDate(
                        announcement
                            .publishedAt
                            .toIso8601String(),
                      ),
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textMuted,
                        fontSize:
                            11,
                      ),
                    ),

                    if (announcement
                        .summary
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height:
                            18,
                      ),
                      Text(
                        announcement
                            .summary
                            .trim(),
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textBody,
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight
                                  .w700,
                          height:
                              1.5,
                        ),
                      ),
                    ],

                    if (announcement
                        .body
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height:
                            18,
                      ),
                      Text(
                        announcement
                            .body
                            .trim(),
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textBody,
                          fontSize:
                              14,
                          height:
                              1.6,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 28,
                    ),

                    SizedBox(
                      width: double
                          .infinity,
                      child:
                          FilledButton(
                        onPressed:
                            () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        child:
                            const Text(
                          'Close',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration:
                  300.ms,
            )
            .slideY(
              begin: 0.08,
              end: 0,
              duration:
                  350.ms,
            );
      },
    );
  }

  String _previewText(
    HubAnnouncement announcement,
  ) {
    if (announcement
        .summary
        .trim()
        .isNotEmpty) {
      return announcement
          .summary
          .trim();
    }

    if (announcement
        .body
        .trim()
        .isNotEmpty) {
      return announcement
          .body
          .trim();
    }

    return 'Tap to read this announcement.';
  }

  String _fullMonthName(
    int month,
  ) {
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

    return months[
        month - 1];
  }


}