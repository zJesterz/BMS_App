import 'package:flutter/material.dart';

class HistoryEvent {
  final DateTime timestamp;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const HistoryEvent({
    required this.timestamp,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
