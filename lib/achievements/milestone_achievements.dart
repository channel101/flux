import 'package:flutter/material.dart';
import 'package:flux/achievements/achievement_base.dart';
import 'package:flux/habit.dart';

final Map<String, AchievementDefinition> milestoneAchievements = {
  // Entry Count Milestones
  'first_entry': AchievementDefinition(
    id: 'first_entry',
    name: 'First Step',
    description: 'Complete your first habit entry',
    icon: Icons.play_arrow,
    color: Colors.green,
    points: 10,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 1,
  ),

  'getting_started': AchievementDefinition(
    id: 'getting_started',
    name: 'Getting the Hang of It',
    description: 'Complete 10 entries',
    icon: Icons.trending_up,
    color: Colors.blue,
    points: 50,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 10,
  ),

  'quarter_century': AchievementDefinition(
    id: 'quarter_century',
    name: 'Quarter Century',
    description: 'Complete 25 entries',
    icon: Icons.star_border,
    color: Colors.orange,
    points: 125,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 25,
  ),

  'half_century': AchievementDefinition(
    id: 'half_century',
    name: 'Half Century',
    description: 'Complete 50 entries',
    icon: Icons.star_half,
    color: Colors.purple,
    points: 250,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 50,
  ),

  'century_club': AchievementDefinition(
    id: 'century_club',
    name: 'Century Club',
    description: 'Complete 100 entries',
    icon: Icons.star,
    color: Colors.indigo,
    points: 500,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 100,
  ),

  'double_century': AchievementDefinition(
    id: 'double_century',
    name: 'Double Century',
    description: 'Complete 200 entries',
    icon: Icons.stars,
    color: Colors.deepPurple,
    points: 1000,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 200,
  ),

  'triple_century': AchievementDefinition(
    id: 'triple_century',
    name: 'Triple Century',
    description: 'Complete 300 entries',
    icon: Icons.auto_awesome,
    color: Colors.cyan,
    points: 1500,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 300,
  ),

  'half_millennium': AchievementDefinition(
    id: 'half_millennium',
    name: 'Half Millennium',
    description: 'Complete 500 entries',
    icon: Icons.diamond,
    color: Color(0xFFFFD700), // Gold
    points: 2500,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 500,
  ),

  'millennium': AchievementDefinition(
    id: 'millennium',
    name: 'Millennium Master',
    description: 'Complete 1000 entries',
    icon: Icons.workspace_premium,
    color: Colors.amber,
    points: 5000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 1000,
  ),

  'dedication_master': AchievementDefinition(
    id: 'dedication_master',
    name: 'Dedication Master',
    description: 'Complete 2000 entries',
    icon: Icons.military_tech,
    color: Colors.deepOrange,
    points: 10000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 2000,
  ),

  // Time-based Milestones
  'morning_person': AchievementDefinition(
    id: 'morning_person',
    name: 'Morning Person',
    description: 'Complete 30 habits before 8 AM',
    icon: Icons.wb_sunny,
    color: Colors.orange,
    points: 300,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkMorningHabits(habit),
  ),

  'night_owl': AchievementDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Complete 30 habits after 9 PM',
    icon: Icons.nights_stay,
    color: Colors.indigo,
    points: 300,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkNightHabits(habit),
  ),

  'lunch_break_hero': AchievementDefinition(
    id: 'lunch_break_hero',
    name: 'Lunch Break Hero',
    description: 'Complete 20 habits during lunch (12-2 PM)',
    icon: Icons.lunch_dining,
    color: Colors.brown,
    points: 200,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkLunchHabits(habit),
  ),

  // Frequency Milestones
  'daily_grind': AchievementDefinition(
    id: 'daily_grind',
    name: 'Daily Grind',
    description: 'Complete the same habit 50 times',
    icon: Icons.repeat,
    color: Colors.teal,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getTotalEntries(habit) >= 50,
  ),

  'habit_machine': AchievementDefinition(
    id: 'habit_machine',
    name: 'Habit Machine',
    description: 'Complete entries for 100 consecutive days',
    icon: Icons.precision_manufacturing,
    color: Colors.grey,
    points: 800,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkConsecutiveDays(habit, 100),
  ),

  'unstoppable_force': AchievementDefinition(
    id: 'unstoppable_force',
    name: 'Unstoppable Force',
    description: 'Complete entries for 200 consecutive days',
    icon: Icons.speed,
    color: Colors.red,
    points: 1600,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => _checkConsecutiveDays(habit, 200),
  ),
};

// Helper functions for complex milestone conditions
bool _checkMorningHabits(Habit habit) {
  int morningCount = 0;
  for (final entry in habit.entries) {
    if (entry.date.hour <= 8) {
      morningCount++;
    }
  }
  return morningCount >= 30;
}

bool _checkNightHabits(Habit habit) {
  int nightCount = 0;
  for (final entry in habit.entries) {
    if (entry.date.hour >= 21) {
      nightCount++;
    }
  }
  return nightCount >= 30;
}

bool _checkLunchHabits(Habit habit) {
  int lunchCount = 0;
  for (final entry in habit.entries) {
    if (entry.date.hour >= 12 && entry.date.hour <= 14) {
      lunchCount++;
    }
  }
  return lunchCount >= 20;
}

bool _checkConsecutiveDays(Habit habit, int targetDays) {
  if (habit.entries.length < targetDays) return false;
  
  final sortedEntries = habit.entries.toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  
  int consecutiveDays = 1;
  DateTime? lastDate;
  
  for (final entry in sortedEntries) {
    if (lastDate != null) {
      final daysDiff = entry.date.difference(lastDate).inDays;
      if (daysDiff == 1) {
        consecutiveDays++;
        if (consecutiveDays >= targetDays) return true;
      } else {
        consecutiveDays = 1;
      }
    }
    lastDate = entry.date;
  }
  
  return false;
} 