import 'package:flutter/material.dart';
import 'package:flux/data/achievements/achievement_base.dart';
import 'package:flux/data/models/habit.dart';

final Map<String, AchievementDefinition> streakAchievements = {
  // Basic Streaks
  'first_3_days': AchievementDefinition(
    id: 'first_3_days',
    name: 'Getting Started',
    description: 'Complete a 3-day streak',
    icon: Icons.emoji_flags,
    color: Colors.green,
    points: 25,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 3,
  ),

  'first_week': AchievementDefinition(
    id: 'first_week',
    name: 'Week Warrior',
    description: 'Complete a 7-day streak',
    icon: Icons.local_fire_department,
    color: Colors.orange,
    points: 100,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 7,
  ),

  'two_weeks': AchievementDefinition(
    id: 'two_weeks',
    name: 'Fortnight Fighter',
    description: 'Complete a 14-day streak',
    icon: Icons.whatshot,
    color: Colors.deepOrange,
    points: 200,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 14,
  ),

  'three_weeks': AchievementDefinition(
    id: 'three_weeks',
    name: 'Triple Week Champion',
    description: 'Complete a 21-day streak',
    icon: Icons.star,
    color: Colors.amber,
    points: 350,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 21,
  ),

  'first_month': AchievementDefinition(
    id: 'first_month',
    name: 'Month Master',
    description: 'Complete a 30-day streak',
    icon: Icons.emoji_events,
    color: Colors.blue,
    points: 500,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 30,
  ),

  'six_weeks': AchievementDefinition(
    id: 'six_weeks',
    name: 'Six Week Specialist',
    description: 'Complete a 42-day streak',
    icon: Icons.military_tech,
    color: Colors.indigo,
    points: 750,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 42,
  ),

  'two_months': AchievementDefinition(
    id: 'two_months',
    name: 'Two Month Titan',
    description: 'Complete a 60-day streak',
    icon: Icons.diamond,
    color: Colors.purple,
    points: 1000,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 60,
  ),

  'three_months': AchievementDefinition(
    id: 'three_months',
    name: 'Quarter Conqueror',
    description: 'Complete a 90-day streak',
    icon: Icons.workspace_premium,
    color: Colors.deepPurple,
    points: 1500,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 90,
  ),

  'centurion': AchievementDefinition(
    id: 'centurion',
    name: '100-Day Centurion',
    description: 'Complete a legendary 100-day streak',
    icon: Icons.security,
    color: Color(0xFFFFD700),
    points: 2000,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 100,
  ),

  'half_year': AchievementDefinition(
    id: 'half_year',
    name: 'Half Year Hero',
    description: 'Complete a 180-day streak',
    icon: Icons.shield,
    color: Colors.cyan,
    points: 3500,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 180,
  ),

  'year_warrior': AchievementDefinition(
    id: 'year_warrior',
    name: 'Year Warrior',
    description: 'Complete an epic 365-day streak',
    icon: Icons.celebration,
    color: Colors.amber,
    points: 10000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getCurrentStreak(habit) >= 365,
  ),

  // Special Streaks
  'weekend_warrior': AchievementDefinition(
    id: 'weekend_warrior',
    name: 'Weekend Warrior',
    description: 'Complete 4 consecutive weekends',
    icon: Icons.weekend,
    color: Colors.teal,
    points: 300,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkWeekendStreak(habit),
  ),

  'weekday_champion': AchievementDefinition(
    id: 'weekday_champion',
    name: 'Weekday Champion',
    description: 'Complete 20 weekdays in a row',
    icon: Icons.business_center,
    color: Colors.blueGrey,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkWeekdayStreak(habit),
  ),

  'streak_reborn': AchievementDefinition(
    id: 'streak_reborn',
    name: 'Streak Reborn',
    description: 'Start a 30-day streak after losing a 50+ day streak',
    icon: Icons.refresh,
    color: Colors.green,
    points: 600,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkStreakReborn(habit),
  ),

  'unbreakable': AchievementDefinition(
    id: 'unbreakable',
    name: 'Unbreakable',
    description: 'Never break a streak for 6 months',
    icon: Icons.shield_outlined,
    color: Colors.indigo,
    points: 2500,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkUnbreakable(habit),
  ),

  'phoenix': AchievementDefinition(
    id: 'phoenix',
    name: 'Phoenix',
    description: 'Rebuild a streak 5 times to 30+ days',
    icon: Icons.local_fire_department,
    color: Colors.red,
    points: 1200,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => _checkPhoenix(habit),
  ),
};

// Helper functions for complex streak conditions
bool _checkWeekendStreak(Habit habit) {
  // Implementation would check for consecutive weekend completions
  return false; // Placeholder
}

bool _checkWeekdayStreak(Habit habit) {
  // Implementation would check for consecutive weekday completions
  return false; // Placeholder
}

bool _checkStreakReborn(Habit habit) {
  // Implementation would check for streak rebuild after major loss
  return false; // Placeholder
}

bool _checkUnbreakable(Habit habit) {
  // Implementation would check for no streak breaks in 6 months
  return false; // Placeholder
}

bool _checkPhoenix(Habit habit) {
  // Implementation would check for multiple streak rebuilds
  return false; // Placeholder
} 