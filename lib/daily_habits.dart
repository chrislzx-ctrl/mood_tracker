import 'package:flutter/material.dart';
import 'package:mood_tracker/database_helper.dart';
import 'package:mood_tracker/habit_model.dart';

class DailyHabits extends StatefulWidget {
  final Function(double) onProgressChanged;

  const DailyHabits({super.key, required this.onProgressChanged});

  @override
  State<DailyHabits> createState() => _DailyHabitsState();
}

class _DailyHabitsState extends State<DailyHabits> {
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await DatabaseHelper.instance.getHabits();
    setState(() {
      _habits = habits;
    });
    _updateProgress();
  }

  void _showManageHabitsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manage Habits'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAddHabitRow(setState),
                    const Divider(),
                    _buildHabitList(setState),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddHabitRow(StateSetter setState) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Add a new habit'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            if (controller.text.isNotEmpty) {
              final newHabit = Habit(name: controller.text, lastCompleted: DateTime.now());
              await DatabaseHelper.instance.insertHabit(newHabit);
              _loadHabits();
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildHabitList(StateSetter setState) {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return ListTile(
            title: Text(habit.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editHabit(index, setState),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteHabit(habit.name);
                    _loadHabits();
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editHabit(int index, StateSetter dialogSetState) {
    final controller = TextEditingController(text: _habits[index].name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Habit'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final updatedHabit = _habits[index];
                  updatedHabit.name = controller.text;
                  await DatabaseHelper.instance.updateHabit(updatedHabit);
                  _loadHabits();
                  dialogSetState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleHabit(int index) async {
    final habit = _habits[index];
    habit.isCompleted = !habit.isCompleted;

    if (habit.isCompleted) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCompletedDay =
          DateTime(habit.lastCompleted.year, habit.lastCompleted.month, habit.lastCompleted.day);

      if (today.isAfter(lastCompletedDay)) {
        if (today.difference(lastCompletedDay).inDays == 1) {
          habit.streak++;
        } else {
          habit.streak = 1; // Streak broken
        }
      } else if (habit.streak == 0) {
        habit.streak = 1; // First time checking
      }
      habit.lastCompleted = now;
    } else {
      // When unchecking, reduce the streak but not below 0.
      if (habit.streak > 0) {
        habit.streak--;
      }
      // Set lastCompleted to a day before to allow re-checking on the same day.
      habit.lastCompleted = DateTime.now().subtract(const Duration(days: 1));
    }

    await DatabaseHelper.instance.updateHabit(habit);
    _loadHabits();
  }

  void _updateProgress() {
    if (_habits.isNotEmpty) {
      final completedHabits = _habits.where((habit) => habit.isCompleted).length;
      widget.onProgressChanged(completedHabits / _habits.length);
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
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text(
                      'Daily Habits',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showManageHabitsDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._habits.asMap().entries.map((entry) {
              final index = entry.key;
              final habit = entry.value;
              return ListTile(
                leading: Checkbox(
                  value: habit.isCompleted,
                  onChanged: (value) => _toggleHabit(index),
                  shape: const CircleBorder(),
                ),
                title: Text(habit.name),
                subtitle: Text('${habit.streak} day streak 🔥'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
