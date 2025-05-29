import 'package:flutter/material.dart';
import 'package:flux/achievements/achievement_base.dart';
import 'package:flux/habit.dart';

final Map<String, AchievementDefinition> specialAchievements = {
  // Time-based Special Achievements
  'early_bird': AchievementDefinition(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Complete 20 habits before 6 AM',
    icon: Icons.wb_sunny,
    color: Colors.orange,
    points: 200,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkTimeBasedHabits(habit, 0, 6, 20),
  ),

  'sunrise_warrior': AchievementDefinition(
    id: 'sunrise_warrior',
    name: 'Sunrise Warrior',
    description: 'Complete 50 habits before sunrise',
    icon: Icons.wb_twilight,
    color: Colors.amber,
    points: 500,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkTimeBasedHabits(habit, 5, 7, 50),
  ),

  'night_owl': AchievementDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Complete 30 habits after 10 PM',
    icon: Icons.nights_stay,
    color: Colors.indigo,
    points: 300,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkTimeBasedHabits(habit, 22, 24, 30),
  ),

  'midnight_maverick': AchievementDefinition(
    id: 'midnight_maverick',
    name: 'Midnight Maverick',
    description: 'Complete 10 habits between 11 PM and 1 AM',
    icon: Icons.dark_mode,
    color: Colors.purple,
    points: 250,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkMidnightHabits(habit),
  ),

  // Seasonal Achievements
  'spring_renewal': AchievementDefinition(
    id: 'spring_renewal',
    name: 'Spring Renewal',
    description: 'Start a new habit during spring and maintain for 30 days',
    icon: Icons.local_florist,
    color: Colors.green,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkSeasonalStart(habit, 'spring'),
  ),

  'summer_dedication': AchievementDefinition(
    id: 'summer_dedication',
    name: 'Summer Dedication',
    description: 'Maintain habit consistency during summer vacation',
    icon: Icons.wb_sunny,
    color: Colors.yellow,
    points: 350,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkSeasonalConsistency(habit, 'summer'),
  ),

  'winter_warrior': AchievementDefinition(
    id: 'winter_warrior',
    name: 'Winter Warrior',
    description: 'Never miss a habit during winter months',
    icon: Icons.ac_unit,
    color: Colors.blue,
    points: 600,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkSeasonalConsistency(habit, 'winter'),
  ),

  // Holiday Achievements
  'new_year_resolution': AchievementDefinition(
    id: 'new_year_resolution',
    name: 'New Year Resolution Keeper',
    description: 'Start a habit on January 1st and keep it for 100 days',
    icon: Icons.celebration,
    color: Color(0xFFFFD700), // Gold
    points: 1000,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => _checkNewYearResolution(habit),
  ),

  'valentine_commitment': AchievementDefinition(
    id: 'valentine_commitment',
    name: 'Valentine Commitment',
    description: 'Show love to your habits on Valentine\'s Day',
    icon: Icons.favorite,
    color: Colors.pink,
    points: 150,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => _checkHolidayHabit(habit, 2, 14),
  ),

  'thanksgiving_gratitude': AchievementDefinition(
    id: 'thanksgiving_gratitude',
    name: 'Thanksgiving Gratitude',
    description: 'Complete habits on Thanksgiving Day',
    icon: Icons.emoji_food_beverage,
    color: Colors.brown,
    points: 200,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkThanksgivingHabit(habit),
  ),

  // Creative Achievements
  'habit_artist': AchievementDefinition(
    id: 'habit_artist',
    name: 'Habit Artist',
    description: 'Create a beautiful pattern with your habit completions',
    icon: Icons.palette,
    color: Colors.purple,
    points: 300,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkHabitPattern(habit),
  ),

  'rainbow_week': AchievementDefinition(
    id: 'rainbow_week',
    name: 'Rainbow Week',
    description: 'Complete habits every day for a week with different times',
    icon: Icons.color_lens,
    color: Colors.deepPurple,
    points: 250,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkRainbowWeek(habit),
  ),

  'minimalist': AchievementDefinition(
    id: 'minimalist',
    name: 'Minimalist',
    description: 'Maintain high success rate with minimal effort',
    icon: Icons.minimize,
    color: Colors.grey,
    points: 400,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkMinimalistApproach(habit),
  ),

  // Challenge Achievements
  'comeback_champion': AchievementDefinition(
    id: 'comeback_champion',
    name: 'Comeback Champion',
    description: 'Restart a habit after 30+ day break and reach new high',
    icon: Icons.trending_up,
    color: Colors.green,
    points: 750,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkComebackChampion(habit),
  ),

  'habit_surgeon': AchievementDefinition(
    id: 'habit_surgeon',
    name: 'Habit Surgeon',
    description: 'Precisely track habit with exact timing 50 times',
    icon: Icons.precision_manufacturing,
    color: Colors.blue,
    points: 500,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkPrecisionTracking(habit),
  ),

  'multi_tasker': AchievementDefinition(
    id: 'multi_tasker',
    name: 'Multi-Tasker',
    description: 'Complete multiple habits in a single session 20 times',
    icon: Icons.layers,
    color: Colors.teal,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkMultiTasking(habit),
  ),

  // Milestone Moments
  'first_thousand_points': AchievementDefinition(
    id: 'first_thousand_points',
    name: 'First Thousand',
    description: 'Earn your first 1,000 points',
    icon: Icons.star,
    color: Colors.amber,
    points: 100,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 1000,
  ),

  'point_collector': AchievementDefinition(
    id: 'point_collector',
    name: 'Point Collector',
    description: 'Earn 5,000 points total',
    icon: Icons.account_balance_wallet,
    color: Colors.green,
    points: 500,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 5000,
  ),

  'point_master': AchievementDefinition(
    id: 'point_master',
    name: 'Point Master',
    description: 'Earn 10,000 points total',
    icon: Icons.monetization_on,
    color: Color(0xFFFFD700), // Gold
    points: 1000,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 10000,
  ),

  'legend': AchievementDefinition(
    id: 'legend',
    name: 'Legend',
    description: 'Earn 25,000 points total',
    icon: Icons.emoji_events,
    color: Colors.purple,
    points: 2500,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 25000,
  ),

  'point_deity': AchievementDefinition(
    id: 'point_deity',
    name: 'Point Deity',
    description: 'Earn 50,000 points total',
    icon: Icons.auto_awesome,
    color: Colors.deepOrange,
    points: 5000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => AchievementHelpers.getTotalPoints(habit) >= 50000,
  ),
};

// Helper functions for special achievements
bool _checkTimeBasedHabits(Habit habit, int startHour, int endHour, int targetCount) {
  int count = 0;
  for (final entry in habit.entries) {
    final hour = entry.date.hour;
    if (hour >= startHour && hour < endHour) {
      count++;
    }
  }
  return count >= targetCount;
}

bool _checkMidnightHabits(Habit habit) {
  int count = 0;
  for (final entry in habit.entries) {
    final hour = entry.date.hour;
    if (hour >= 23 || hour <= 1) {
      count++;
    }
  }
  return count >= 10;
}

bool _checkSeasonalStart(Habit habit, String season) {
  if (habit.entries.isEmpty) return false;
  
  final firstEntry = habit.entries.reduce((a, b) => 
    a.date.isBefore(b.date) ? a : b);
  
  final month = firstEntry.date.month;
  bool isCorrectSeason = false;
  
  switch (season) {
    case 'spring':
      isCorrectSeason = month >= 3 && month <= 5;
      break;
    case 'summer':
      isCorrectSeason = month >= 6 && month <= 8;
      break;
    case 'fall':
      isCorrectSeason = month >= 9 && month <= 11;
      break;
    case 'winter':
      isCorrectSeason = month == 12 || month <= 2;
      break;
  }
  
  return isCorrectSeason && AchievementHelpers.getCurrentStreak(habit) >= 30;
}

bool _checkSeasonalConsistency(Habit habit, String season) {
  // Implementation would check consistency during specific season
  return false; // Placeholder
}

bool _checkNewYearResolution(Habit habit) {
  if (habit.entries.isEmpty) return false;
  
  final firstEntry = habit.entries.reduce((a, b) => 
    a.date.isBefore(b.date) ? a : b);
  
  return firstEntry.date.month == 1 && 
         firstEntry.date.day == 1 && 
         AchievementHelpers.getCurrentStreak(habit) >= 100;
}

bool _checkHolidayHabit(Habit habit, int month, int day) {
  for (final entry in habit.entries) {
    if (entry.date.month == month && entry.date.day == day) {
      return true;
    }
  }
  return false;
}

bool _checkThanksgivingHabit(Habit habit) {
  // Thanksgiving is the 4th Thursday of November
  for (final entry in habit.entries) {
    if (entry.date.month == 11 && entry.date.weekday == DateTime.thursday) {
      final day = entry.date.day;
      if (day >= 22 && day <= 28) {
        return true;
      }
    }
  }
  return false;
}

bool _checkHabitPattern(Habit habit) {
  // Implementation would check for interesting patterns
  return false; // Placeholder
}

bool _checkRainbowWeek(Habit habit) {
  // Check for 7 consecutive days with different completion times
  if (habit.entries.length < 7) return false;
  
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 7)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  
  if (recentEntries.length < 7) return false;
  
  final hours = recentEntries.map((e) => e.date.hour).toSet();
  return hours.length >= 5; // At least 5 different hours
}

bool _checkMinimalistApproach(Habit habit) {
  return AchievementHelpers.getSuccessRate(habit) >= 90 && 
         AchievementHelpers.getTotalEntries(habit) >= 30 &&
         _checkLowEffortPattern(habit);
}

bool _checkLowEffortPattern(Habit habit) {
  // Implementation would check for minimal time/effort pattern
  return false; // Placeholder
}

bool _checkComebackChampion(Habit habit) {
  // Implementation would check for comeback after long break
  return false; // Placeholder
}

bool _checkPrecisionTracking(Habit habit) {
  // Implementation would check for precise timing
  return false; // Placeholder
}

bool _checkMultiTasking(Habit habit) {
  // Implementation would check for multiple habits in same session
  return false; // Placeholder
} 