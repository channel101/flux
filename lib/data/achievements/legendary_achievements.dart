import 'package:flutter/material.dart';
import 'package:flux/data/achievements/achievement_base.dart';
import 'package:flux/data/models/habit.dart';

final Map<String, AchievementDefinition> legendaryAchievements = {
  // Legendary Streaks
  'immortal_streak': AchievementDefinition(
    id: 'immortal_streak',
    name: 'Immortal Streak',
    description: 'Maintain a 500-day streak',
    icon: Icons.auto_awesome,
    color: Color(0xFFFFD700), // Gold
    points: 15000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 500,
  ),

  'eternal_dedication': AchievementDefinition(
    id: 'eternal_dedication',
    name: 'Eternal Dedication',
    description: 'Maintain a 1000-day streak',
    icon: Icons.diamond,
    color: Colors.cyan,
    points: 50000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 1000,
  ),

  'transcendent': AchievementDefinition(
    id: 'transcendent',
    name: 'Transcendent',
    description: 'Achieve enlightenment with a 1500-day streak',
    icon: Icons.brightness_7,
    color: Colors.white,
    points: 100000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 1500,
  ),

  // Legendary Consistency
  'flawless_year': AchievementDefinition(
    id: 'flawless_year',
    name: 'Flawless Year',
    description: 'Maintain 100% success rate for 365 days',
    icon: Icons.verified,
    color: Color(0xFFFFD700), // Gold
    points: 25000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkFlawlessYear(habit),
  ),

  'perfectionist_supreme': AchievementDefinition(
    id: 'perfectionist_supreme',
    name: 'Perfectionist Supreme',
    description: 'Maintain 100% success rate for 2 years',
    icon: Icons.workspace_premium,
    color: Colors.purple,
    points: 75000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => _checkFlawlessTwoYears(habit),
  ),

  // Legendary Volume
  'habit_overlord': AchievementDefinition(
    id: 'habit_overlord',
    name: 'Habit Overlord',
    description: 'Complete 5000 habit entries',
    icon: Icons.emoji_events,
    color: Colors.amber,
    points: 30000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 5000,
  ),

  'habit_emperor': AchievementDefinition(
    id: 'habit_emperor',
    name: 'Habit Emperor',
    description: 'Complete 10000 habit entries',
    icon: Icons.military_tech,
    color: Colors.deepOrange,
    points: 100000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 10000,
  ),

  // Legendary Points
  'point_legend': AchievementDefinition(
    id: 'point_legend',
    name: 'Point Legend',
    description: 'Earn 100,000 points',
    icon: Icons.star,
    color: Color(0xFFFFD700), // Gold
    points: 10000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 100000,
  ),

  'point_deity': AchievementDefinition(
    id: 'point_deity',
    name: 'Point Deity',
    description: 'Earn 500,000 points',
    icon: Icons.auto_awesome,
    color: Colors.white,
    points: 50000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 500000,
  ),

  'point_omnipotent': AchievementDefinition(
    id: 'point_omnipotent',
    name: 'Point Omnipotent',
    description: 'Earn 1,000,000 points',
    icon: Icons.brightness_7,
    color: Colors.deepPurple,
    points: 100000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 1000000,
  ),

  // Time-based Legendary
  'decade_master': AchievementDefinition(
    id: 'decade_master',
    name: 'Decade Master',
    description: 'Maintain a habit for 10 years',
    icon: Icons.access_time,
    color: Colors.indigo,
    points: 200000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => _checkDecadeMaster(habit),
  ),

  'timeless_warrior': AchievementDefinition(
    id: 'timeless_warrior',
    name: 'Timeless Warrior',
    description: 'Complete habits across 4 different decades',
    icon: Icons.history,
    color: Colors.grey,
    points: 50000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkTimelessWarrior(habit),
  ),

  // Extreme Challenges
  'impossible_dreamer': AchievementDefinition(
    id: 'impossible_dreamer',
    name: 'Impossible Dreamer',
    description: 'Complete a habit every day for 3 years straight',
    icon: Icons.psychology,
    color: Colors.pink,
    points: 150000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 1095,
  ),

  'unbreakable_will': AchievementDefinition(
    id: 'unbreakable_will',
    name: 'Unbreakable Will',
    description: 'Never miss more than 2 days in a year',
    icon: Icons.shield,
    color: Colors.red,
    points: 35000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkUnbreakableWill(habit),
  ),

  'habit_sage': AchievementDefinition(
    id: 'habit_sage',
    name: 'Habit Sage',
    description: 'Maintain 95%+ success rate for 5 years',
    icon: Icons.self_improvement,
    color: Colors.teal,
    points: 80000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => _checkHabitSage(habit),
  ),

  // Ultra Rare
  'first_achiever': AchievementDefinition(
    id: 'first_achiever',
    name: 'First Achiever',
    description: 'Be the first to unlock this achievement',
    icon: Icons.emoji_events,
    color: Color(0xFFFFD700), // Gold
    points: 100000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => false, // Special condition
  ),

  'habit_pioneer': AchievementDefinition(
    id: 'habit_pioneer',
    name: 'Habit Pioneer',
    description: 'Create a habit that inspires others',
    icon: Icons.explore,
    color: Colors.green,
    points: 25000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkHabitPioneer(habit),
  ),

  'zen_master': AchievementDefinition(
    id: 'zen_master',
    name: 'Zen Master',
    description: 'Achieve perfect balance in all life areas',
    icon: Icons.spa,
    color: Colors.lightBlue,
    points: 50000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkZenMaster(habit),
  ),

  'habit_architect': AchievementDefinition(
    id: 'habit_architect',
    name: 'Habit Architect',
    description: 'Design the perfect habit tracking system',
    icon: Icons.architecture,
    color: Colors.brown,
    points: 40000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkHabitArchitect(habit),
  ),

  'motivation_master': AchievementDefinition(
    id: 'motivation_master',
    name: 'Motivation Master',
    description: 'Inspire yourself to achieve the impossible',
    icon: Icons.psychology_alt,
    color: Colors.orange,
    points: 30000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkMotivationMaster(habit),
  ),

  'habit_philosopher': AchievementDefinition(
    id: 'habit_philosopher',
    name: 'Habit Philosopher',
    description: 'Understand the deep meaning of habits',
    icon: Icons.school,
    color: Colors.deepPurple,
    points: 45000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkHabitPhilosopher(habit),
  ),

  'legendary_discipline': AchievementDefinition(
    id: 'legendary_discipline',
    name: 'Legendary Discipline',
    description: 'Show discipline that legends are made of',
    icon: Icons.fitness_center,
    color: Colors.red,
    points: 60000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => _checkLegendaryDiscipline(habit),
  ),
};

// Helper functions for legendary achievements
bool _checkFlawlessYear(Habit habit) {
  if (habit.entries.length < 365) return false;
  
  final yearEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 365)
      .toList();
  
  return yearEntries.length >= 365 && 
         yearEntries.every((entry) => habit.isPositiveDay(entry));
}

bool _checkFlawlessTwoYears(Habit habit) {
  if (habit.entries.length < 730) return false;
  
  final twoYearEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 730)
      .toList();
  
  return twoYearEntries.length >= 730 && 
         twoYearEntries.every((entry) => habit.isPositiveDay(entry));
}

bool _checkDecadeMaster(Habit habit) {
  if (habit.entries.isEmpty) return false;
  
  final firstEntry = habit.entries.reduce((a, b) => 
    a.date.isBefore(b.date) ? a : b);
  
  final daysSinceStart = DateTime.now().difference(firstEntry.date).inDays;
  return daysSinceStart >= 3650; // 10 years
}

bool _checkTimelessWarrior(Habit habit) {
  if (habit.entries.isEmpty) return false;
  
  final decades = <int>{};
  for (final entry in habit.entries) {
    decades.add(entry.date.year ~/ 10);
  }
  
  return decades.length >= 4;
}

bool _checkUnbreakableWill(Habit habit) {
  if (habit.entries.length < 300) return false; // Most of a year
  
  final yearEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 365)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  
  int consecutiveMisses = 0;
  int maxConsecutiveMisses = 0;
  
  DateTime? lastDate;
  for (final entry in yearEntries) {
    if (lastDate != null) {
      final daysDiff = entry.date.difference(lastDate).inDays;
      if (daysDiff > 1) {
        consecutiveMisses += daysDiff - 1;
        maxConsecutiveMisses = consecutiveMisses > maxConsecutiveMisses ? consecutiveMisses : maxConsecutiveMisses;
      } else {
        consecutiveMisses = 0;
      }
    }
    lastDate = entry.date;
  }
  
  return maxConsecutiveMisses <= 2;
}

bool _checkHabitSage(Habit habit) {
  if (habit.entries.length < 1500) return false; // ~5 years of entries
  
  final fiveYearEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 1825)
      .toList();
  
  if (fiveYearEntries.length < 1500) return false;
  
  final successRate = fiveYearEntries.where((e) => habit.isPositiveDay(e)).length / fiveYearEntries.length * 100;
  return successRate >= 95;
}

bool _checkHabitPioneer(Habit habit) {
  // Implementation would check for innovative habits or sharing
  return false; // Placeholder
}

bool _checkZenMaster(Habit habit) {
  // Implementation would check for balance across different habit types
  return false; // Placeholder
}

bool _checkHabitArchitect(Habit habit) {
  // Implementation would check for systematic habit organization
  return false; // Placeholder
}

bool _checkMotivationMaster(Habit habit) {
  // Implementation would check for overcoming difficult periods
  return false; // Placeholder
}

bool _checkHabitPhilosopher(Habit habit) {
  // Implementation would check for deep understanding patterns
  return false; // Placeholder
}

bool _checkLegendaryDiscipline(Habit habit) {
  return AchievementHelpers.getCurrentStreak(habit) >= 1000 &&
         AchievementHelpers.getSuccessRate(habit) >= 98 &&
         AchievementHelpers.getTotalEntries(habit) >= 2000;
} 