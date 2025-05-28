// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/habit_entry.dart';
import 'package:flux/main.dart';

class Habit {
  String name;
  HabitType type;
  ReportDisplay displayMode;
  IconData? icon;
  List<HabitEntry> entries;
  Color? color;
  bool isArchived;
  String? notes;
  int reminderHour;
  int reminderMinute;
  bool hasReminder;
  
  // New fields for enhanced functionality
  String? category; // Habit category/group
  HabitFrequency frequency; // How often the habit should occur
  List<int> customDays; // For CustomDays frequency (0=Sunday, 6=Saturday)
  int? targetFrequency; // For XTimesPerWeek/Month
  double? targetValue; // Target value for measurable goals
  HabitUnit unit; // Unit of measurement
  String? customUnit; // Custom unit name
  DateTime? pauseStartDate; // When habit was paused
  DateTime? pauseEndDate; // When pause ends
  bool isPaused; // Whether habit is currently paused
  
  Habit({
    required this.name, 
    this.type = HabitType.SuccessBased,
    this.displayMode = ReportDisplay.Rate, 
    this.icon, 
    this.color,
    this.isArchived = false,
    this.notes,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.hasReminder = false,
    this.category,
    this.frequency = HabitFrequency.Daily,
    this.customDays = const [],
    this.targetFrequency,
    this.targetValue,
    this.unit = HabitUnit.Count,
    this.customUnit,
    this.pauseStartDate,
    this.pauseEndDate,
    this.isPaused = false,
    List<HabitEntry>? entries
  }) : entries = entries ?? [];
  
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.index,
        'displayMode': displayMode.index,
        'icon': icon?.codePoint,
        'color': color?.value,
        'isArchived': isArchived,
        'notes': notes,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'hasReminder': hasReminder,
        'category': category,
        'frequency': frequency.index,
        'customDays': customDays,
        'targetFrequency': targetFrequency,
        'targetValue': targetValue,
        'unit': unit.index,
        'customUnit': customUnit,
        'pauseStartDate': pauseStartDate?.toIso8601String(),
        'pauseEndDate': pauseEndDate?.toIso8601String(),
        'isPaused': isPaused,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
      
  static Habit fromJson(Map<String, dynamic> json) => Habit(
        name: json['name'],
        type: HabitType.values[json['type'] ?? 1],
        displayMode: ReportDisplay.values[json['displayMode'] ?? 0],
        icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
        color: json['color'] != null ? Color(json['color']) : null,
        isArchived: json['isArchived'] ?? false,
        notes: json['notes'],
        reminderHour: json['reminderHour'] ?? 20,
        reminderMinute: json['reminderMinute'] ?? 0,
        hasReminder: json['hasReminder'] ?? false,
        category: json['category'],
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
        customDays: List<int>.from(json['customDays'] ?? []),
        targetFrequency: json['targetFrequency'],
        targetValue: json['targetValue']?.toDouble(),
        unit: HabitUnit.values[json['unit'] ?? 0],
        customUnit: json['customUnit'],
        pauseStartDate: json['pauseStartDate'] != null ? DateTime.parse(json['pauseStartDate']) : null,
        pauseEndDate: json['pauseEndDate'] != null ? DateTime.parse(json['pauseEndDate']) : null,
        isPaused: json['isPaused'] ?? false,
        entries: (json['entries'] as List?)
            ?.map((e) => HabitEntry.fromJson(e))
            .toList() ?? [],
      );
      
  int getNextDayNumber() {
    return entries.isEmpty ? 1 : entries.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  bool isPositiveDay(HabitEntry entry) {
    if (entry.isSkipped) return true; // Skipped days don't break streaks
    
    switch (type) {
      case HabitType.FailBased:
        if (targetValue != null && entry.value != null) {
          return entry.value! <= targetValue!; // Success if under target for avoid habits
        }
        return entry.count == 0;
      case HabitType.SuccessBased:
        if (targetValue != null && entry.value != null) {
          return entry.value! >= targetValue!; // Success if meeting target
        }
        return entry.count > 0;
      case HabitType.DoneBased:
        return entry.count > 0;
    }
  }
  
  // Check if habit is due today based on frequency
  bool isDueToday() {
    if (isPaused) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.Weekdays:
        return now.weekday <= 5; // Monday = 1, Friday = 5
      case HabitFrequency.Weekends:
        return now.weekday > 5; // Saturday = 6, Sunday = 7
      case HabitFrequency.CustomDays:
        final todayIndex = now.weekday % 7; // Convert to 0=Sunday format
        return customDays.contains(todayIndex);
      case HabitFrequency.XTimesPerWeek:
      case HabitFrequency.XTimesPerMonth:
        return _checkFrequencyTarget(today);
    }
  }
  
  bool _checkFrequencyTarget(DateTime today) {
    if (targetFrequency == null) return true;
    
    if (frequency == HabitFrequency.XTimesPerWeek) {
      final weekStart = today.subtract(Duration(days: today.weekday % 7));
      final weekEnd = weekStart.add(Duration(days: 6));
      final weekEntries = entries.where((e) => 
        e.date.isAfter(weekStart.subtract(Duration(days: 1))) && 
        e.date.isBefore(weekEnd.add(Duration(days: 1))) &&
        isPositiveDay(e)
      ).length;
      return weekEntries < targetFrequency!;
    } else if (frequency == HabitFrequency.XTimesPerMonth) {
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      final monthEntries = entries.where((e) => 
        e.date.isAfter(monthStart.subtract(Duration(days: 1))) && 
        e.date.isBefore(monthEnd.add(Duration(days: 1))) &&
        isPositiveDay(e)
      ).length;
      return monthEntries < targetFrequency!;
    }
    
    return true;
  }
  
  // Get time since last failure for avoid habits
  String getTimeSinceLastFailure() {
    if (type != HabitType.FailBased || entries.isEmpty) return "No data";
    
    final failureEntries = entries.where((e) => !isPositiveDay(e) && !e.isSkipped).toList();
    if (failureEntries.isEmpty) {
      // Never failed, show time since first entry
      final firstEntry = entries.first;
      final duration = DateTime.now().difference(firstEntry.date);
      return _formatDuration(duration);
    }
    
    failureEntries.sort((a, b) => b.date.compareTo(a.date));
    final lastFailure = failureEntries.first;
    final duration = DateTime.now().difference(lastFailure.date);
    return _formatDuration(duration);
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays}d clean";
    } else if (duration.inHours > 0) {
      return "${duration.inHours}h clean";
    } else {
      return "${duration.inMinutes}m clean";
    }
  }
  
  int get positiveCount => entries.where((e) => isPositiveDay(e)).length;
  int get negativeCount => entries.length - positiveCount;
  double get successRate => entries.isEmpty ? 0 : (positiveCount / entries.length) * 100;
  
  // Calculate streaks considering frequency
  int get currentStreak {
    int streak = 0;
    if (entries.isEmpty) return 0;
    
    var sortedEntries = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    
    // For frequency-based habits, we need to check expected days
    if (frequency != HabitFrequency.Daily) {
      return _calculateFrequencyStreak(sortedEntries);
    }
    
    // Daily habit streak calculation
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int _calculateFrequencyStreak(List<HabitEntry> sortedEntries) {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        streak++;
        currentDate = entry.date;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int get bestStreak {
    if (entries.isEmpty) return 0;
    
    int currentBest = 0;
    int current = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        current++;
        if (current > currentBest) {
          currentBest = current;
        }
      } else {
        current = 0;
      }
    }
    
    return currentBest;
  }
  
  // Add extra utility methods
  
  String get formattedName {
    return formatPascalCase(name);
  }
  
  bool get hasEntries => entries.isNotEmpty;
  
  // Get total value/count aggregated
  double getTotalValue() {
    return entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
  }
  
  // Get average value per entry
  double getAverageValue() {
    if (entries.isEmpty) return 0.0;
    return getTotalValue() / entries.length;
  }
  
  // Get unit display name
  String getUnitDisplayName() {
    switch (unit) {
      case HabitUnit.Count:
        return 'times';
      case HabitUnit.Minutes:
        return 'min';
      case HabitUnit.Hours:
        return 'hrs';
      case HabitUnit.Pages:
        return 'pages';
      case HabitUnit.Kilometers:
        return 'km';
      case HabitUnit.Miles:
        return 'miles';
      case HabitUnit.Grams:
        return 'g';
      case HabitUnit.Pounds:
        return 'lbs';
      case HabitUnit.Dollars:
        return '\$';
      case HabitUnit.Custom:
        return customUnit ?? 'units';
    }
  }
  
  // Negative streak
  int get longestNegativeStreak {
    if (entries.isEmpty) return 0;
    
    int currentNegative = 0;
    int maxNegative = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    
    for (var entry in sortedEntries) {
      if (!isPositiveDay(entry)) {
        currentNegative++;
        if (currentNegative > maxNegative) {
          maxNegative = currentNegative;
        }
      } else {
        currentNegative = 0;
      }
    }
    
    return maxNegative;
  }
}
