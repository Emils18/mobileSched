import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final HubContentService _service =
      HubContentService();

  late final Stream<List<HubAnnouncement>>
      _announcements;

  late final Stream<List<BirthdayCelebrant>>
      _celebrants;

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
    PageController(viewportFraction: 0.78);

int _activeBirthdayIndex = 0;

  @override
  void initState() {
    super.initState();

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
    final currentIds =
        announcements.map((item) => item.id).toSet();

    if (!_announcementBaselineReady) {
      _knownAnnouncementIds
        ..clear()
        ..addAll(currentIds);

      _announcementBaselineReady = true;
      return;
    }

    final newAnnouncements = announcements
        .where(
          (item) =>
              !_knownAnnouncementIds.contains(item.id),
        )
        .toList();

    _knownAnnouncementIds
      ..clear()
      ..addAll(currentIds);

    if (newAnnouncements.isEmpty) {
      return;
    }

    final newest = newAnnouncements.first;

    if (mounted) {
      setState(() {
        _highlightAnnouncementId = newest.id;
      });

      Future<void>.delayed(
        const Duration(seconds: 6),
        () {
          if (!mounted ||
              _highlightAnnouncementId != newest.id) {
            return;
          }

          setState(() {
            _highlightAnnouncementId = null;
          });
        },
      );
    }

    if (kIsWeb) {
      _showWebNotice(
        title: 'New Announcement',
        message: newest.title,
        icon: Icons.campaign_rounded,
      );
    } else {
      unawaited(
        NotificationService().showHubNotification(
          id: newest.id,
          title: '📢 ${newest.title}',
          body: _previewText(newest),
          type: 'announcement',
        ),
      );
    }
  }

  void _handleCelebrantUpdates(
    List<BirthdayCelebrant> celebrants,
  ) {
    final currentIds =
        celebrants.map((item) => item.id).toSet();

    final todayCelebrants =
        _todayCelebrants(celebrants);

    if (!_celebrantBaselineReady) {
      _knownCelebrantIds
        ..clear()
        ..addAll(currentIds);

      _celebrantBaselineReady = true;

      if (todayCelebrants.isNotEmpty) {
        _triggerBirthdayEffects(
          todayCelebrants,
          showWebBanner: true,
        );
      }

      return;
    }

    final newTodayCelebrants =
        todayCelebrants.where(
      (person) =>
          !_knownCelebrantIds.contains(person.id),
    ).toList();

    _knownCelebrantIds
      ..clear()
      ..addAll(currentIds);

    if (newTodayCelebrants.isNotEmpty) {
      _triggerBirthdayEffects(
        newTodayCelebrants,
        showWebBanner: true,
      );
    }
  }

  List<BirthdayCelebrant> _todayCelebrants(
    List<BirthdayCelebrant> celebrants,
  ) {
    final now = DateTime.now();

    return celebrants.where((person) {
      return person.birthdate.month == now.month &&
          person.birthdate.day == now.day;
    }).toList();
  }

  void _triggerBirthdayEffects(
    List<BirthdayCelebrant> people, {
    required bool showWebBanner,
  }) {
    if (people.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _highlightCelebrantIds.addAll(
          people.map((person) => person.id),
        );
      });

      Future<void>.delayed(
        const Duration(seconds: 8),
        () {
          if (!mounted) {
            return;
          }

          setState(() {
            for (final person in people) {
              _highlightCelebrantIds.remove(
                person.id,
              );
            }
          });
        },
      );
    }

    if (kIsWeb) {
      if (showWebBanner) {
        final names = people
            .map((person) => person.name)
            .join(', ');

        _showWebNotice(
          title: '🎂 Birthday Celebration',
          message:
              'Happy Birthday, $names!',
          icon: Icons.cake_rounded,
        );
      }

      return;
    }

    for (final person in people) {
      unawaited(
        NotificationService()
            .showBirthdayNotificationOncePerDay(
          id: person.id,
          name: person.name,
          department: person.department,
        ),
      );
    }
  }

  void _showWebNotice({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildAnnouncements(),
        const SizedBox(height: 24),
        _buildBirthdays(),
      ],
    );
  }

  Widget _buildAnnouncements() {
    return StreamBuilder<List<HubAnnouncement>>(
      stream: _announcements,
      builder: (context, snapshot) {
        final items =
            snapshot.data ??
                const <HubAnnouncement>[];

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Announcements',
                  style: TextStyle(
                    color:
                        AppColors.textTitle,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(
                  duration: 350.ms,
                )
                .slideY(
                  begin: 0.10,
                  end: 0,
                  duration: 350.ms,
                ),

            const SizedBox(height: 12),

            if (snapshot.connectionState ==
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
            else
              AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds: 450,
                ),
                transitionBuilder:
                    (child, animation) {
                  final curved =
                      CurvedAnimation(
                    parent: animation,
                    curve:
                        Curves.easeOutCubic,
                  );

                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.97,
                        end: 1,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(
                    items.first.id,
                  ),
                  child:
                      _announcementCard(
                    items.first,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _announcementCard(
    HubAnnouncement announcement,
  ) {
    final isNew =
        _highlightAnnouncementId ==
            announcement.id;

    final card = GlassCard(
      padding: EdgeInsets.zero,
      hasGlow:
          announcement.pinned || isNew,
      borderColor: isNew
          ? AppColors.primary
              .withValues(alpha: 0.75)
          : announcement.pinned
              ? AppColors.primary
                  .withValues(alpha: 0.45)
              : null,
      onTap: () =>
          _showAnnouncement(announcement),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (announcement.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                announcement.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
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

          Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .primary
                            .withValues(
                              alpha: 0.12,
                            ),
                        borderRadius:
                            BorderRadius
                                .circular(20),
                      ),
                      child: Text(
                        announcement.tag
                            .toUpperCase(),
                        style:
                            const TextStyle(
                          color:
                              AppColors.primary,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    if (announcement
                        .pinned) ...[
                      const SizedBox(
                        width: 8,
                      ),
                      const Icon(
                        Icons.push_pin_rounded,
                        color:
                            AppColors.orange,
                        size: 17,
                      ),
                    ],

                    if (isNew) ...[
                      const SizedBox(
                        width: 8,
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .secondary
                              .withValues(
                                alpha: 0.15,
                              ),
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
                            color: AppColors
                                .secondary,
                            fontSize: 8,
                            fontWeight:
                                FontWeight
                                    .w900,
                            letterSpacing:
                                0.8,
                          ),
                        ),
                      )
                          .animate(
                            onPlay:
                                (controller) =>
                                    controller
                                        .repeat(
                              reverse: true,
                            ),
                          )
                          .shimmer(
                            duration:
                                1200.ms,
                            color: AppColors
                                .secondary
                                .withValues(
                              alpha: 0.30,
                            ),
                          ),
                    ],

                    const Spacer(),

                    Text(
                      AppFormatters
                          .formatDate(
                        announcement
                            .publishedAt
                            .toIso8601String(),
                      ),
                      style:
                          const TextStyle(
                        color: AppColors
                            .textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  announcement.title,
                  style: const TextStyle(
                    color:
                        AppColors.textTitle,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w900,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _previewText(
                    announcement,
                  ),
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        AppColors.textBody,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 14),

                const Row(
                  children: [
                    Text(
                      'Read announcement',
                      style: TextStyle(
                        color:
                            AppColors.primary,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons
                          .arrow_forward_rounded,
                      color:
                          AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isNew) {
      return card;
    }

    return card
        .animate(
          onPlay: (controller) =>
              controller.repeat(
            reverse: true,
          ),
        )
        .shimmer(
          duration: 1400.ms,
          color: AppColors.primary
              .withValues(alpha: 0.18),
        );
  }


Widget _buildBirthdays() {
  return StreamBuilder<List<BirthdayCelebrant>>(
    stream: _celebrants,
    builder: (context, snapshot) {
      final all =
          snapshot.data ?? const <BirthdayCelebrant>[];

      final now = DateTime.now();

      final thisMonth = all.where((person) {
        return person.birthdate.month == now.month;
      }).toList()
        ..sort(
          (a, b) =>
              a.birthdate.day.compareTo(b.birthdate.day),
        );

      final today = thisMonth.where((person) {
        return person.birthdate.day == now.day;
      }).toList();

      final shown =
          today.isNotEmpty ? today : thisMonth;

      final activeIndex = shown.isEmpty
          ? 0
          : _activeBirthdayIndex
              .clamp(0, shown.length - 1)
              .toInt();

      final subtitle = today.isNotEmpty
          ? today.length == 1
              ? "Today's birthday celebrant"
              : "${today.length} birthdays today! 🎉"
          : "This month's celebrants";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cake_rounded,
                color: AppColors.orange,
                size: 22,
              )
                  .animate(
                    onPlay: (controller) =>
                        controller.repeat(),
                  )
                  .shimmer(
                    duration: 1600.ms,
                    color: AppColors.warning.withValues(
                      alpha: 0.45,
                    ),
                  ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Birthday Celebrants',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (thisMonth.length > 1) ...[
                TextButton(
                  onPressed: () {
                    _showAllCelebrants(thisMonth);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.orange,
                        size: 10,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),
              ],

              if (thisMonth.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                  child: Text(
                    '${thisMonth.length}',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.10,
                end: 0,
                duration: 400.ms,
              ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: TextStyle(
              color: today.length > 1
                  ? AppColors.orange
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: today.length > 1
                  ? FontWeight.w700
                  : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 12),

          if (snapshot.connectionState ==
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
          else if (shown.isEmpty)
            _messageCard(
              Icons.cake_outlined,
              'No birthday celebrants this month.',
            )
          else ...[
            if (today.length > 1) ...[
              _multipleBirthdayGreeting(today),
              const SizedBox(height: 16),
            ],

            SizedBox(
              height: 285,
              child: PageView.builder(
                controller: _birthdayPageController,
                itemCount: shown.length,
                physics:
                    const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _activeBirthdayIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final person = shown[index];

                  final isActive =
                      index == activeIndex;

                  return AnimatedScale(
                    scale: isActive ? 1.0 : 0.91,
                    duration: const Duration(
                      milliseconds: 280,
                    ),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity:
                          isActive ? 1.0 : 0.58,
                      duration: const Duration(
                        milliseconds: 280,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child:
                            _birthdayGreetingCard(
                          person,
                          isActive,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (shown.length > 1) ...[
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.swipe_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${activeIndex + 1} / ${shown.length}  •  Swipe to see everyone',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  for (int index = 0;
                      index < shown.length &&
                          index < 7;
                      index++)
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 250,
                      ),
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      width:
                          index == activeIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == activeIndex
                            ? AppColors.orange
                            : AppColors.textMuted
                                .withValues(
                                  alpha: 0.28,
                                ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      );
    },
  );
}



void _showAllCelebrants(
  List<BirthdayCelebrant> celebrants,
) {
  if (celebrants.isEmpty) {
    return;
  }

  final sortedCelebrants =
      List<BirthdayCelebrant>.from(celebrants)
        ..sort(
          (a, b) =>
              a.birthdate.day.compareTo(b.birthdate.day),
        );

  final now = DateTime.now();

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        expand: false,
        builder: (
          context,
          scrollController,
        ) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(
                color: AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.35,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
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
                        decoration: BoxDecoration(
                          color: AppColors.orange
                              .withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cake_rounded,
                          color: AppColors.orange,
                          size: 22,
                        ),
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(),
                          )
                          .shimmer(
                            duration: 1700.ms,
                            color: AppColors.warning
                                .withValues(
                              alpha: 0.35,
                            ),
                          ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_fullMonthName(now.month)} Celebrants',
                              style: const TextStyle(
                                color:
                                    AppColors.textTitle,
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${sortedCelebrants.length} ${sortedCelebrants.length == 1 ? 'birthday' : 'birthdays'} this month',
                              style: const TextStyle(
                                color:
                                    AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: AppColors.cardBorder
                      .withValues(alpha: 0.8),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      int columns = 2;

                      if (constraints.maxWidth >= 720) {
                        columns = 4;
                      } else if (
                          constraints.maxWidth >= 520) {
                        columns = 3;
                      }

                      return GridView.builder(
                        controller:
                            scrollController,
                        padding:
                            const EdgeInsets.all(16),
                        physics:
                            const BouncingScrollPhysics(),
                        itemCount:
                            sortedCelebrants.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final person =
                              sortedCelebrants[index];

                          return _celebrantGridCard(
                            person,
                          )
                              .animate(
                                delay:
                                    (index * 55).ms,
                              )
                              .fadeIn(
                                duration: 380.ms,
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
                                duration: 380.ms,
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
                duration: 250.ms,
              )
              .slideY(
                begin: 0.06,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutCubic,
              );
        },
      );
    },
  );
}

Widget _celebrantGridCard(
  BirthdayCelebrant person,
) {
  final now = DateTime.now();

  final isToday =
      person.birthdate.month == now.month &&
          person.birthdate.day == now.day;

  final highlighted =
      isToday ||
      _highlightCelebrantIds.contains(person.id);

  return GlassCard(
    padding: const EdgeInsets.all(12),
    hasGlow: highlighted,
    borderColor: highlighted
        ? AppColors.orange.withValues(
            alpha: 0.65,
          )
        : null,
    child: Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: highlighted
                      ? AppColors.orange
                      : AppColors.cardBorder,
                  width: highlighted ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: person.imageUrl == null
                      ? _avatarFallback(
                          person.name,
                        )
                      : Image.network(
                          person.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _avatarFallback(
                              person.name,
                            );
                          },
                        ),
                ),
              ),
            ),

            if (isToday)
              Positioned(
                right: -5,
                bottom: -2,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bgDeep,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                )
                    .animate(
                      onPlay: (controller) =>
                          controller.repeat(
                        reverse: true,
                      ),
                    )
                    .scale(
                      begin:
                          const Offset(
                        0.92,
                        0.92,
                      ),
                      end:
                          const Offset(
                        1.08,
                        1.08,
                      ),
                      duration: 800.ms,
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
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.orange.withValues(
                    alpha: 0.14,
                  )
                : AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            isToday
                ? '🎉 TODAY'
                : _birthdayDate(
                    person.birthdate,
                  ),
            style: TextStyle(
              color: isToday
                  ? AppColors.orange
                  : AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _multipleBirthdayGreeting(
  List<BirthdayCelebrant> celebrants,
) {
  final names = celebrants
      .map((person) => person.name.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  String greetingNames;

  if (names.length == 2) {
    greetingNames =
        '${names[0]} & ${names[1]}';
  } else if (names.length == 3) {
    greetingNames =
        '${names[0]}, ${names[1]} & ${names[2]}';
  } else if (names.length > 3) {
    greetingNames =
        '${names[0]}, ${names[1]}, ${names[2]} + ${names.length - 3} more';
  } else {
    greetingNames =
        names.isEmpty ? 'Everyone' : names.first;
  }

  return GlassCard(
    hasGlow: true,
    borderColor:
        AppColors.orange.withValues(
      alpha: 0.55,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 18,
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.warning,
              size: 16,
            )
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(
                    reverse: true,
                  ),
                )
                .scale(
                  begin:
                      const Offset(0.85, 0.85),
                  end:
                      const Offset(1.10, 1.10),
                  duration: 900.ms,
                ),

            const SizedBox(width: 7),

            const Text(
              "TODAY'S CELEBRATION",
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(width: 7),

            const Icon(
              Icons.celebration_rounded,
              color: AppColors.warning,
              size: 16,
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Text(
          '🎉 Happy Birthday! 🎂',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        )
            .animate(
              onPlay: (controller) =>
                  controller.repeat(
                reverse: true,
              ),
            )
            .shimmer(
              duration: 1700.ms,
              color: AppColors.warning.withValues(
                alpha: 0.45,
              ),
            ),

        const SizedBox(height: 9),

        Text(
          greetingNames,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '${celebrants.length} amazing people are celebrating today!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textBody,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Wishing you all a wonderful day filled with happiness and celebration. 🥳',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    ),
  )
      .animate()
      .fadeIn(duration: 450.ms)
      .scale(
        begin: const Offset(
          0.96,
          0.96,
        ),
        end: const Offset(
          1,
          1,
        ),
        duration: 450.ms,
        curve: Curves.easeOutBack,
      );
}

Widget _birthdayGreetingCard(
  BirthdayCelebrant person,
  bool isActive,
) {
  final now = DateTime.now();

  final isToday =
      person.birthdate.month == now.month &&
          person.birthdate.day == now.day;

  final highlighted =
      isToday ||
      _highlightCelebrantIds.contains(
        person.id,
      );

  final card = GlassCard(
    padding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 15,
    ),
    hasGlow: highlighted || isActive,
    borderColor: isToday
        ? AppColors.orange.withValues(
            alpha: 0.75,
          )
        : isActive
            ? AppColors.orange.withValues(
                alpha: 0.28,
              )
            : null,
    child: Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              isToday
                  ? Icons.celebration_rounded
                  : Icons.cake_rounded,
              color: AppColors.orange,
              size: 15,
            ),

            const SizedBox(width: 6),

            Text(
              isToday
                  ? 'HAPPY BIRTHDAY!'
                  : 'BIRTHDAY CELEBRANT',
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday
                      ? AppColors.orange
                      : AppColors.primary
                          .withValues(
                            alpha: 0.45,
                          ),
                  width: 2,
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppColors.orange
                              .withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child:
                      person.imageUrl == null
                          ? _avatarFallback(
                              person.name,
                            )
                          : Image.network(
                              person.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return _avatarFallback(
                                  person.name,
                                );
                              },
                            ),
                ),
              ),
            ),

            if (isToday)
              Positioned(
                right: -7,
                bottom: -1,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bgDeep,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                )
                    .animate(
                      onPlay: (controller) =>
                          controller.repeat(
                        reverse: true,
                      ),
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
                      duration: 850.ms,
                    ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          person.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textTitle,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          person.department,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          isToday
              ? 'Wishing you an amazing birthday! 🎂'
              : 'Celebrating on ${_birthdayDate(person.birthdate)} 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isToday
                ? AppColors.textBody
                : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isToday
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(
              alpha: 0.11,
            ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            isToday
                ? '🎉 TODAY'
                : _birthdayDate(
                    person.birthdate,
                  ).toUpperCase(),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    ),
  );

  if (!isToday) {
    return card;
  }

  return card
      .animate(
        onPlay: (controller) =>
            controller.repeat(
          reverse: true,
        ),
      )
      .shimmer(
        duration: 1800.ms,
        color: AppColors.orange.withValues(
          alpha: 0.14,
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
                .substring(0, 1)
                .toUpperCase();

    return Container(
      alignment: Alignment.center,
      color: AppColors.primary
          .withValues(alpha: 0.14),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
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
          const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color:
                    AppColors.textBody,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 350.ms,
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
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 50,
            ),
            child: GlassCard(
              borderRadius:
                  const BorderRadius
                      .vertical(
                top: Radius.circular(28),
              ),
              padding:
                  const EdgeInsets.all(
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
                      child: Container(
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
                              BoxFit.cover,
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
                      announcement.tag
                          .toUpperCase(),
                      style:
                          const TextStyle(
                        color:
                            AppColors.primary,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      announcement.title,
                      style:
                          const TextStyle(
                        color: AppColors
                            .textTitle,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w900,
                        height: 1.2,
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
                        color: AppColors
                            .textMuted,
                        fontSize: 11,
                      ),
                    ),

                    if (announcement
                        .summary
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        announcement
                            .summary
                            .trim(),
                        style:
                            const TextStyle(
                          color: AppColors
                              .textBody,
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w700,
                          height: 1.5,
                        ),
                      ),
                    ],

                    if (announcement
                        .body
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        announcement.body
                            .trim(),
                        style:
                            const TextStyle(
                          color: AppColors
                              .textBody,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 28,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          FilledButton(
                        onPressed: () {
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
              duration: 300.ms,
            )
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 350.ms,
            );
      },
    );
  }

  String _previewText(
    HubAnnouncement announcement,
  ) {
    if (announcement.summary
        .trim()
        .isNotEmpty) {
      return announcement.summary
          .trim();
    }

    if (announcement.body
        .trim()
        .isNotEmpty) {
      return announcement.body
          .trim();
    }

    return 'Tap to read this announcement.';
  }

String _fullMonthName(int month) {
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

  return months[month - 1];
}


  String _birthdayDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }
}