import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/mood_check.dart';
import 'package:share_plus/share_plus.dart';

class Timeline extends StatefulWidget {
  final List<Mood> moods;

  const Timeline({super.key, required this.moods});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  int _selectedIndex = 1;

  void _share() {
    final now = DateTime.now();
    final monthName = DateFormat.MMMM().format(now);
    final year = now.year;

    final Map<DateTime, Mood> latestMoods = {};
    for (var mood in widget.moods) {
      final day = DateTime(mood.timestamp.year, mood.timestamp.month, mood.timestamp.day);
      latestMoods[day] = mood;
    }

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthlyMoods = latestMoods.values.where((mood) {
      final moodDate = DateTime(mood.timestamp.year, mood.timestamp.month, mood.timestamp.day);
      return !moodDate.isBefore(monthStart) && !moodDate.isAfter(monthEnd);
    }).toList();

    if (monthlyMoods.isEmpty) {
      Share.share('No mood data available for $monthName $year to generate a report.');
      return;
    }

    final moodCounts = {
      'Great': 0,
      'Good': 0,
      'Okay': 0,
      'Low': 0,
      'Tough': 0,
    };
    double totalMoodValue = 0;
    for (var mood in monthlyMoods) {
      moodCounts[mood.name] = (moodCounts[mood.name] ?? 0) + 1;
      totalMoodValue += _moodToValue(mood.name);
    }

    final averageValue = totalMoodValue / monthlyMoods.length;
    final averageMoodName = _valueToMoodName(averageValue);

    final report = StringBuffer();
    report.writeln('Monthly Mood Report ($monthName $year)');
    report.writeln('----------------------------------');
    moodCounts.forEach((name, count) {
      if (count > 0) {
        report.writeln('$name: $count ${count == 1 ? 'time' : 'times'}');
      }
    });
    report.writeln('----------------------------------');
    report.writeln('Average Mood: $averageMoodName');
    report.writeln('\nThis report is generated for counseling purposes.');

    Share.share(report.toString());
  }

  String _valueToMoodName(double value) {
    final roundedValue = value.round();
    switch (roundedValue) {
      case 0:
        return 'Tough';
      case 1:
        return 'Low';
      case 2:
        return 'Okay';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      default:
        return 'Okay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text(
                      'Timeline',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _share,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Daily'),
                  selected: _selectedIndex == 0,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Weekly'),
                  selected: _selectedIndex == 1,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Monthly'),
                  selected: _selectedIndex == 2,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getDateRange(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartData(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.deepPurple,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurple.withOpacity(0.3),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Text(DateFormat.E().format(date));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Tough');
                            case 1:
                              return const Text('Low');
                            case 2:
                              return const Text('Okay');
                            case 3:
                              return const Text('Good');
                            case 4:
                              return const Text('Great');
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(
                    show: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final formatter = DateFormat('d MMM');

    if (_selectedIndex == 0) { // Daily
      return formatter.format(today);
    } else if (_selectedIndex == 1) { // Weekly
      final weekStart = today.subtract(const Duration(days: 6));
      return '${formatter.format(weekStart)} - ${formatter.format(today)}';
    } else { // Monthly
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      return '${formatter.format(monthStart)} - ${formatter.format(monthEnd)}';
    }
  }


  List<FlSpot> _getChartData() {
    if (widget.moods.isEmpty) {
      return [];
    }

    final Map<DateTime, Mood> latestMoods = {};
    for (var mood in widget.moods) {
      final day = DateTime(mood.timestamp.year, mood.timestamp.month, mood.timestamp.day);
      latestMoods[day] = mood;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredMoods = latestMoods.entries.where((entry) {
      final moodDate = entry.key;
      if (_selectedIndex == 0) { // Daily
        return moodDate == today;
      } else if (_selectedIndex == 1) { // Weekly
        final weekStart = today.subtract(const Duration(days: 6));
        return !moodDate.isBefore(weekStart) && !moodDate.isAfter(today);
      } else { // Monthly
        final monthStart = DateTime(today.year, today.month, 1);
        final monthEnd = DateTime(today.year, today.month + 1, 0);
        return moodDate.isAfter(monthStart.subtract(const Duration(days: 1))) && moodDate.isBefore(monthEnd.add(const Duration(days: 1)));
      }
    }).map((entry) => entry.value);

    return filteredMoods
        .map((mood) => FlSpot(
              mood.timestamp.millisecondsSinceEpoch.toDouble(),
              _moodToValue(mood.name),
            ))
        .toList();
  }

  double _moodToValue(String moodName) {
    switch (moodName) {
      case 'Tough':
        return 0;
      case 'Low':
        return 1;
      case 'Okay':
        return 2;
      case 'Good':
        return 3;
      case 'Great':
        return 4;
      default:
        return 2;
    }
  }
}
