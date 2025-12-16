import 'package:flutter/material.dart';

class Habit {
  String name;
  bool isCompleted;
  int streak;
  DateTime lastCompleted;

  Habit({
    required this.name,
    this.isCompleted = false,
    this.streak = 0,
    required this.lastCompleted,
  });
}
