import 'package:flutter/material.dart';
import 'package:mood_tracker/database_helper.dart';
import 'package:mood_tracker/phq9_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PHQ9ResultScreen extends StatefulWidget {
  const PHQ9ResultScreen({super.key});

  @override
  State<PHQ9ResultScreen> createState() => _PHQ9ResultScreenState();
}

class _PHQ9ResultScreenState extends State<PHQ9ResultScreen> {
  late Future<List<PHQ9Result>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = DatabaseHelper.instance.getPHQ9Results();
  }

  String _getSeverity(int score) {
    if (score <= 4) return 'Minimal';
    if (score <= 9) return 'Mild';
    if (score <= 14) return 'Moderate';
    if (score <= 19) return 'Moderately Severe';
    return 'Severe';
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Immediate Support Recommended'),
          content: const Text(
              'We\'ve noticed your PHQ-9 scores have been consistently high (≥18) for the past 5 days, indicating moderately severe to severe depression symptoms. Your wellbeing is important to us.\n\nWould you like to connect with a professional counselor?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement Find Nearby Counselors
              },
              child: const Text('Find Nearby Counselors'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I\'m Getting Help'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHQ-9 Depression Analysis'),
      ),
      body: FutureBuilder<List<PHQ9Result>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No PHQ-9 results yet.'));
          }

          final results = snapshot.data!;
          final latestResult = results.last;

          final recentResults = results.length > 5
              ? results.sublist(results.length - 5)
              : results;
          final consistentlyHigh = recentResults.every((result) => result.score >= 18);

          if (consistentlyHigh) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSupportDialog();
            });
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Severity Level: ${_getSeverity(latestResult.score)}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: latestResult.score / 27,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text('Score: ${latestResult.score}'),
                  const SizedBox(height: 24),
                  const Text('Past 7 Days Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: BarChart(
                      BarChartData(
                        barGroups: results.asMap().entries.map((entry) {
                          final index = entry.key;
                          final result = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: result.score.toDouble(),
                                color: result.score >= 18 ? Colors.red : Colors.blue,
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < results.length) {
                                  return Text(DateFormat.E().format(results[index].date));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('PHQ-9 Severity Scale', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('0-4: Minimal depression'),
                  const Text('5-9: Mild depression'),
                  const Text('10-14: Moderate depression'),
                  const Text('15-19: Moderately severe depression'),
                  const Text('20-27: Severe depression'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
