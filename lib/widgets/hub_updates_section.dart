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
    return StreamBuilder<
        List<BirthdayCelebrant>>(
      stream: _celebrants,
      builder: (context, snapshot) {
        final all =
            snapshot.data ??
                const <BirthdayCelebrant>[];

        final now = DateTime.now();

        final today =
            all.where((person) {
          return person.birthdate.month ==
                  now.month &&
              person.birthdate.day ==
                  now.day;
        }).toList();

        final thisMonth =
            all.where((person) {
          return person.birthdate.month ==
              now.month;
        }).toList();

        final shown =
            today.isNotEmpty
                ? today
                : thisMonth;

        final subtitle =
            today.isNotEmpty
                ? "Today's celebrants"
                : "This month's celebrants";

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cake_rounded,
                  color: AppColors.orange,
                  size: 22,
                )
                    .animate(
                      onPlay:
                          (controller) =>
                              controller
                                  .repeat(),
                    )
                    .shimmer(
                      duration:
                          1600.ms,
                      color: AppColors
                          .warning
                          .withValues(
                            alpha: 0.45,
                          ),
                    ),
                const SizedBox(width: 8),
                const Text(
                  'Birthday Celebrants',
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
                  duration: 400.ms,
                )
                .slideY(
                  begin: 0.10,
                  end: 0,
                  duration: 400.ms,
                ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                color:
                    AppColors.textMuted,
                fontSize: 11,
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
            else
              SizedBox(
                height: 190,
                child:
                    ListView.separated(
                  scrollDirection:
                      Axis.horizontal,
                  physics:
                      const BouncingScrollPhysics(),
                  itemCount:
                      shown.length,
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    width: 10,
                  ),
                  itemBuilder:
                      (context, index) {
                    final person =
                        shown[index];

                    return _celebrantCard(
                      person,
                    )
                        .animate(
                          delay:
                              (index * 80).ms,
                        )
                        .fadeIn(
                          duration:
                              420.ms,
                        )
                        .slideY(
                          begin: 0.14,
                          end: 0,
                          duration:
                              420.ms,
                          curve: Curves
                              .easeOutCubic,
                        );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _celebrantCard(
    BirthdayCelebrant person,
  ) {
    final now = DateTime.now();

    final isToday =
        person.birthdate.month ==
                now.month &&
            person.birthdate.day ==
                now.day;

    final isHighlighted =
        _highlightCelebrantIds
            .contains(person.id);

    final highlighted =
        isToday || isHighlighted;

    final card = SizedBox(
      width: 142,
      child: GlassCard(
        padding:
            const EdgeInsets.all(12),
        hasGlow: highlighted,
        borderColor: highlighted
            ? AppColors.orange
                .withValues(alpha: 0.60)
            : null,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    3,
                  ),
                  decoration:
                      BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: highlighted
                          ? AppColors.orange
                          : AppColors
                              .cardBorder,
                      width:
                          highlighted
                              ? 2
                              : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child:
                          person.imageUrl ==
                                  null
                              ? _avatarFallback(
                                  person.name,
                                )
                              : Image.network(
                                  person
                                      .imageUrl!,
                                  fit: BoxFit
                                      .cover,
                                  errorBuilder:
                                      (
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
                ),

                if (isToday)
                  Positioned(
                    right: -7,
                    bottom: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .orange,
                        shape:
                            BoxShape.circle,
                        border:
                            Border.all(
                          color: AppColors
                              .bgDeep,
                          width: 2,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .cake_rounded,
                        size: 14,
                        color:
                            Colors.white,
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
                              1100.ms,
                          color: Colors
                              .white
                              .withValues(
                            alpha: 0.50,
                          ),
                        ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              person.name,
              textAlign:
                  TextAlign.center,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    AppColors.textTitle,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              person.department,
              textAlign:
                  TextAlign.center,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    AppColors.textMuted,
                fontSize: 9,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              isToday
                  ? '🎉 TODAY'
                  : _birthdayDate(
                      person.birthdate,
                    ),
              style: TextStyle(
                color: isToday
                    ? AppColors.orange
                    : AppColors
                        .textMuted,
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (!highlighted) {
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
          duration: 1500.ms,
          color: AppColors.orange
              .withValues(alpha: 0.16),
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