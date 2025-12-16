import 'package:flutter/material.dart';

class StressLevelSlider extends StatefulWidget {
  final Function(double) onStressChanged;
  const StressLevelSlider({super.key, required this.onStressChanged});

  @override
  State<StressLevelSlider> createState() => _StressLevelSliderState();
}

class _StressLevelSliderState extends State<StressLevelSlider> {
  double _stressLevel = 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.flash_on),
                    SizedBox(width: 8),
                    Text(
                      'Stress Level',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _stressLevel.toInt().toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _stressLevel,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _stressLevel = value;
                });
                widget.onStressChanged(value);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('😌 Relaxed'),
                Text('😵 Overwhelmed'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
