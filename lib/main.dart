import 'package:flutter/material.dart';
import 'package:mood_tracker/database_helper.dart';
import 'package:mood_tracker/daily_habits.dart';
import 'package:mood_tracker/happy_moments.dart';
import 'package:mood_tracker/mood_check.dart';
import 'package:mood_tracker/overview_chart.dart';
import 'package:mood_tracker/phq9_test_screen.dart';
import 'package:mood_tracker/progress_bar.dart';
import 'package:mood_tracker/sleep_energy_tracker.dart';
import 'package:mood_tracker/stress_level_slider.dart';
import 'package:mood_tracker/timeline.dart';

void main() {
  runApp(const MyApp());
}

class DailyRecord {
  final DateTime date;
  final double stressLevel;
  final int sleepQuality;
  final int energyLevel;

  DailyRecord({
    required this.date,
    required this.stressLevel,
    required this.sleepQuality,
    required this.energyLevel,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Mood Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Mood> _moods = [];
  double _progress = 0.4; // Initial progress
  List<DailyRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbHelper = DatabaseHelper.instance;
    final moods = await dbHelper.getMoods();
    final records = await dbHelper.getDailyRecords();
    setState(() {
      _moods = moods;
      _records = records;
    });
  }

  Future<void> _onMoodSelected(Mood mood) async {
    await DatabaseHelper.instance.insertMood(mood);
    _loadData();
  }

  void _onProgressChanged(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  Future<void> _updateDailyRecord({
    double? stressLevel,
    int? sleepQuality,
    int? energyLevel,
  }) async {
    final today = DateTime.now();
    final todayRecordIndex = _records.indexWhere((record) =>
        record.date.year == today.year &&
        record.date.month == today.month &&
        record.date.day == today.day);

    DailyRecord record;
    if (todayRecordIndex != -1) {
      final oldRecord = _records[todayRecordIndex];
      record = DailyRecord(
        date: oldRecord.date,
        stressLevel: stressLevel ?? oldRecord.stressLevel,
        sleepQuality: sleepQuality ?? oldRecord.sleepQuality,
        energyLevel: energyLevel ?? oldRecord.energyLevel,
      );
    } else {
      record = DailyRecord(
        date: today,
        stressLevel: stressLevel ?? 5.0, // Default value
        sleepQuality: sleepQuality ?? 1, // Default value
        energyLevel: energyLevel ?? 1, // Default value
      );
    }
    await DatabaseHelper.instance.upsertDailyRecord(record);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PHQ9TestScreen()),
                  );
                },
                child: const Text('Take PHQ-9 Test'),
              ),
              const SizedBox(height: 16),
              QuickMoodCheck(onMoodSelected: _onMoodSelected),
              const SizedBox(height: 16),
              Timeline(moods: _moods),
              const SizedBox(height: 16),
              StressLevelSlider(
                onStressChanged: (value) => _updateDailyRecord(stressLevel: value),
              ),
              const SizedBox(height: 16),
              SleepEnergyTracker(
                onSleepChanged: (value) => _updateDailyRecord(sleepQuality: value),
                onEnergyChanged: (value) => _updateDailyRecord(energyLevel: value),
              ),
              const SizedBox(height: 16),
              OverviewChart(records: _records),
              const SizedBox(height: 16),
              ProgressBar(progress: _progress),
              const SizedBox(height: 16),
              DailyHabits(onProgressChanged: _onProgressChanged),
              const SizedBox(height: 16),
              const HappyMoments(),
            ],
          ),
        ),
      ),
    );
  }
}
