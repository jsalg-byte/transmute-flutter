import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/theme/transmute_palette.dart';
import '../../../shared/widgets/app_shell.dart';

class TrainingCalendarScreen extends ConsumerStatefulWidget {
  const TrainingCalendarScreen({super.key});

  @override
  ConsumerState<TrainingCalendarScreen> createState() =>
      _TrainingCalendarScreenState();
}

class _TrainingCalendarScreenState
    extends ConsumerState<TrainingCalendarScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  static const _monthNames = [
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

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(
      streakProvider((year: _year, month: _month)),
    );
    final palette = TransmutePalette.of(context);

    return AppShell(
      title: 'Training calendar',
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training Calendar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inspect your qualified consistency and dated workouts.',
                      style: TextStyle(color: palette.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: _prevMonth,
              ),
              Text(
                '${_monthNames[_month - 1]} $_year',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),
          streakAsync.when(
            loading: () => const TransmuteStatePanel(
              kind: TransmuteStateKind.loading,
              title: 'Loading calendar',
              message: 'Fetching qualified training records...',
            ),
            error: (_, _) => TransmuteStatePanel(
              kind: TransmuteStateKind.error,
              title: 'Calendar unavailable',
              message: 'Your training calendar could not be loaded.',
              action: TransmuteButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(
                  streakProvider((year: _year, month: _month)),
                ),
              ),
            ),
            data: (streakData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streak summary cards
                  Row(
                    children: [
                      Expanded(
                        child: TransmutePanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: palette.oxide,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Current streak',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${streakData.currentStreak} day${streakData.currentStreak == 1 ? '' : 's'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                streakData.lastQualifiedDate != null
                                    ? 'Last qualified: ${streakData.lastQualifiedDate}'
                                    : 'No qualified days yet',
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TransmutePanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    color: palette.gold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Best streak',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${streakData.bestStreak} day${streakData.bestStreak == 1 ? '' : 's'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Historical record run',
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Calendar grid
                  _CalendarMonthGrid(
                    monthData: streakData.calendarMonth,
                    palette: palette,
                  ),
                  const SizedBox(height: 20),
                  // Legend & Rules explanation
                  TransmutePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendar Legend & Rules',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _LegendItem(
                              color: palette.oxide,
                              label: 'Qualified (≥3 working sets)',
                            ),
                            _LegendItem(
                              color: palette.recovering,
                              label: 'Completed (<3 working sets)',
                            ),
                            _LegendItem(
                              color: palette.raised,
                              label: 'Rest / No workout',
                              bordered: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A qualified training day requires at least 3 acknowledged working sets in a completed session. Streaks count consecutive local calendar days ending today or yesterday without retroactive shift.',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.monthData,
    required this.palette,
  });

  final CalendarMonthData monthData;
  final TransmutePalette palette;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    // First day of month offset
    final firstDay = DateTime(monthData.year, monthData.month, 1);
    final startOffset = firstDay.weekday % 7; // Sunday = 0

    return TransmutePanel(
      child: Column(
        children: [
          Row(
            children: [
              for (final wd in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      wd,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + monthData.days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final dayIndex = index - startOffset;
              final dayStatus = monthData.days[dayIndex];
              final dayNum = dayIndex + 1;

              Color bg;
              Color textColor;
              Border? border;

              switch (dayStatus.type) {
                case CalendarDayType.qualified:
                  bg = palette.oxide;
                  textColor = Colors.black;
                case CalendarDayType.completed:
                  bg = palette.recovering;
                  textColor = Colors.black;
                case CalendarDayType.future:
                  bg = Colors.transparent;
                  textColor = palette.muted.withValues(alpha: 0.4);
                case CalendarDayType.rest:
                  bg = palette.raised;
                  textColor = palette.muted;
                  border = Border.all(color: palette.divider);
              }

              return Tooltip(
                message:
                    '${dayStatus.date}: ${dayStatus.type.name.toUpperCase()} (${dayStatus.workingSetCount} working sets, ${dayStatus.workoutCount} workouts)',
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: dayStatus.type == CalendarDayType.qualified
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered ? Border.all(color: Colors.white24) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
