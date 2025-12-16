import 'package:flutter/material.dart';

class SleepEnergyTracker extends StatefulWidget {
  final Function(int) onSleepChanged;
  final Function(int) onEnergyChanged;
  const SleepEnergyTracker(
      {super.key, required this.onSleepChanged, required this.onEnergyChanged});

  @override
  State<SleepEnergyTracker> createState() => _SleepEnergyTrackerState();
}

class _SleepEnergyTrackerState extends State<SleepEnergyTracker> {
  int _sleepQuality = 1;
  int _energyLevel = 2;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.nightlight_round),
                SizedBox(width: 8),
                Text(
                  'Sleep & Energy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Sleep Quality'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text('😴 Poor'),
                  selected: _sleepQuality == 0,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sleepQuality = 0;
                      });
                      widget.onSleepChanged(0);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('😊 OK'),
                  selected: _sleepQuality == 1,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sleepQuality = 1;
                      });
                      widget.onSleepChanged(1);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('😁 Good'),
                  selected: _sleepQuality == 2,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sleepQuality = 2;
                      });
                      widget.onSleepChanged(2);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Energy Level'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text('🔋 Low'),
                  selected: _energyLevel == 0,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _energyLevel = 0;
                      });
                      widget.onEnergyChanged(0);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('⚡️ Medium'),
                  selected: _energyLevel == 1,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _energyLevel = 1;
                      });
                      widget.onEnergyChanged(1);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('✨ High'),
                  selected: _energyLevel == 2,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _energyLevel = 2;
                      });
                      widget.onEnergyChanged(2);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
