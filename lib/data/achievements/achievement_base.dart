import 'package:flutter/material.dart';
import 'package:flux/data/models/habit.dart';

// Achievement definition class
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int points;
  final AchievementRarity rarity;
  final bool Function(Habit) checkCondition;
  final bool isBadAchievement;
  
  const AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.rarity,
    required this.checkCondition,
    this.isBadAchievement = false,
  });
}

// Achievement earned class
class AchievementEarned {
  final AchievementDefinition definition;
  final DateTime earnedAt;
  final String habitName;
  
  AchievementEarned({
    required this.definition,
    required this.earnedAt,
    required this.habitName,
  });
}

// Achievement rarity enum
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

extension AchievementRarityExtension on AchievementRarity {
  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
      case AchievementRarity.mythic:
        return Colors.deepOrange;
    }
  }
  
  String get name {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
      case AchievementRarity.mythic:
        return 'Mythic';
    }
  }
}

// Helper functions for achievement conditions
class AchievementHelpers {
  static int getConsecutiveSkips(Habit habit) {
    int consecutiveSkips = 0;
    final sortedEntries = habit.entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (final entry in sortedEntries) {
      if (entry.isSkipped == true || (!habit.isPositiveDay(entry))) {
        consecutiveSkips++;
      } else {
        break;
      }
    }
    return consecutiveSkips;
  }

  static int getDaysWithoutActivity(Habit habit) {
    if (habit.entries.isEmpty) return 0;
    
    final lastEntry = habit.entries.reduce((a, b) => 
      a.date.isAfter(b.date) ? a : b);
    
    return DateTime.now().difference(lastEntry.date).inDays;
  }

  static int getStreakResets(Habit habit) {
    int resets = 0;
    int currentStreak = 0;
    final sortedEntries = habit.entries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    for (final entry in sortedEntries) {
      if (habit.isPositiveDay(entry)) {
        currentStreak++;
      } else {
        if (currentStreak > 0) {
          resets++;
        }
        currentStreak = 0;
      }
    }
    return resets;
  }

  static bool isTimeInRange(DateTime time, int startHour, int endHour) {
    return time.hour >= startHour && time.hour <= endHour;
  }

  static int getTotalEntries(Habit habit) {
    return habit.entries.length;
  }

  static double getSuccessRate(Habit habit) {
    return habit.successRate;
  }

  static int getCurrentStreak(Habit habit) {
    return habit.currentStreak;
  }

  static int getTotalPoints(Habit habit) {
    return habit.totalPoints;
  }
} 