import 'package:flutter/material.dart';

class Mood {
  final String emoji;
  final String name;
  final DateTime timestamp;

  Mood({required this.emoji, required this.name, required this.timestamp});
}

class QuickMoodCheck extends StatelessWidget {
  final Function(Mood) onMoodSelected;

  const QuickMoodCheck({super.key, required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.insights),
                SizedBox(width: 8),
                Text(
                  'Quick Mood Check',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MoodButton(
                    mood: Mood(name: 'Great', emoji: '😊', timestamp: DateTime.now()),
                    onMoodSelected: onMoodSelected),
                MoodButton(
                    mood: Mood(name: 'Good', emoji: '🙂', timestamp: DateTime.now()),
                    onMoodSelected: onMoodSelected),
                MoodButton(
                    mood: Mood(name: 'Okay', emoji: '😐', timestamp: DateTime.now()),
                    onMoodSelected: onMoodSelected),
                MoodButton(
                    mood: Mood(name: 'Low', emoji: '😟', timestamp: DateTime.now()),
                    onMoodSelected: onMoodSelected),
                MoodButton(
                    mood: Mood(name: 'Tough', emoji: '😢', timestamp: DateTime.now()),
                    onMoodSelected: onMoodSelected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final Mood mood;
  final Function(Mood) onMoodSelected;

  const MoodButton({
    super.key,
    required this.mood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onMoodSelected(mood.copyWith(timestamp: DateTime.now())),
      child: Column(
        children: [
          Text(
            mood.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(mood.name),
        ],
      ),
    );
  }
}

extension MoodCopyWith on Mood {
  Mood copyWith({String? emoji, String? name, DateTime? timestamp}) {
    return Mood(
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
