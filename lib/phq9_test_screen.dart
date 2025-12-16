import 'package:flutter/material.dart';
import 'package:mood_tracker/database_helper.dart';
import 'package:mood_tracker/phq9_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class PHQ9TestScreen extends StatefulWidget {
  const PHQ9TestScreen({super.key});

  @override
  State<PHQ9TestScreen> createState() => _PHQ9TestScreenState();
}

class _PHQ9TestScreenState extends State<PHQ9TestScreen> {
  bool _showResult = false;
  List<PHQ9Result> _results = [];

  final List<PHQ9Question> _questions = [
    PHQ9Question(questionText: 'Little interest or pleasure in doing things'),
    PHQ9Question(questionText: 'Feeling down, depressed, or hopeless'),
    PHQ9Question(questionText: 'Trouble falling or staying asleep, or sleeping too much'),
    PHQ9Question(questionText: 'Feeling tired or having little energy'),
    PHQ9Question(questionText: 'Poor appetite or overeating'),
    PHQ9Question(
        questionText:
            'Feeling bad about yourself - or that you are a failure or have let yourself or your family down'),
    PHQ9Question(questionText: 'Trouble concentrating on things, such as reading the newspaper or watching television'),
    PHQ9Question(
        questionText:
            'Moving or speaking so slowly that other people could have noticed. Or the opposite - being so fidgety or restless that you have been moving around a lot more than usual'),
    PHQ9Question(questionText: 'Thoughts that you would be better off dead, or of hurting yourself'),
  ];

  Future<void> _submitTest() async {
    final totalScore = _questions.fold(0, (sum, item) => sum + item.score);
    final result = PHQ9Result(date: DateTime.now(), score: totalScore);
    await DatabaseHelper.instance.insertPHQ9Result(result);

    final results = await DatabaseHelper.instance.getPHQ9Results();

    setState(() {
      _results = results;
      _showResult = true;
    });

    if (_checkConsistentlyHigh(results)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSupportDialog();
      });
    }
  }

  bool _checkConsistentlyHigh(List<PHQ9Result> results) {
    final recentResults = results.length > 5 ? results.sublist(results.length - 5) : results;
    return recentResults.every((result) => result.score >= 18);
  }

  String _getSeverity(int score) {
    if (score <= 4) return 'Minimal';
    if (score <= 9) return 'Mild';
    if (score <= 14) return 'Moderate';
    if (score <= 19) return 'Moderately Severe';
    return 'Severe';
  }

  Future<void> _findNearbyCounselors() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable them in your settings.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied. We cannot request permissions.')));
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition();
      final lat = position.latitude;
      final lon = position.longitude;

      final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=counselors&location=$lat,$lon');

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not find nearby counselors: $e')));
      }
    }
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
                _findNearbyCounselors();
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
        title: Text(_showResult ? 'PHQ-9 Analysis' : 'PHQ-9 Depression Test'),
      ),
      body: _showResult ? _buildResultView() : _buildTestView(),
    );
  }

  Widget _buildTestView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ..._questions.asMap().entries.map((entry) {
              final question = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question.questionText, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      RadioListTile<int>(
                        title: const Text('Not at all'),
                        value: 0,
                        groupValue: question.score,
                        onChanged: (value) {
                          setState(() {
                            question.score = value!;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('Several days'),
                        value: 1,
                        groupValue: question.score,
                        onChanged: (value) {
                          setState(() {
                            question.score = value!;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('More than half the days'),
                        value: 2,
                        groupValue: question.score,
                        onChanged: (value) {
                          setState(() {
                            question.score = value!;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('Nearly every day'),
                        value: 3,
                        groupValue: question.score,
                        onChanged: (value) {
                          setState(() {
                            question.score = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton(
              onPressed: _submitTest,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (_results.isEmpty) {
      return const Center(child: Text('No results to display.'));
    }
    final latestResult = _results.last;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Severity Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            latestResult.score.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: latestResult.score / 27,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0-4\nMinimal'),
                        Text('5-9\nMild'),
                        Text('10-14\nModerate'),
                        Text('15-19\nMod. Severe'),
                        Text('20-27\nSevere'),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Past 7 Days Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  barGroups: _results.asMap().entries.map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: result.score.toDouble(),
                          color: result.score >= 18 ? Colors.red.shade300 : Colors.blue.shade300,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
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
                          if (index >= 0 && index < _results.length) {
                            return Text(DateFormat.E().format(_results[index].date));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('PHQ-9 Severity Scale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  }
}
