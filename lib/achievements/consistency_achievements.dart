import 'package:flutter/material.dart';
import 'package:flux/achievements/achievement_base.dart';
import 'package:flux/habit.dart';

final Map<String, AchievementDefinition> consistencyAchievements = {
  // Success Rate Achievements
  'good_start': AchievementDefinition(
    id: 'good_start',
    name: 'Good Start',
    description: 'Achieve 50% success rate with 10+ entries',
    icon: Icons.thumb_up,
    color: Colors.green,
    points: 100,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 50 && 
                              AchievementHelpers.getTotalEntries(habit) >= 10,
  ),

  'above_average': AchievementDefinition(
    id: 'above_average',
    name: 'Above Average',
    description: 'Achieve 70% success rate with 20+ entries',
    icon: Icons.trending_up,
    color: Colors.blue,
    points: 200,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 70 && 
                              AchievementHelpers.getTotalEntries(habit) >= 20,
  ),

  'consistency_king': AchievementDefinition(
    id: 'consistency_king',
    name: 'Consistency King',
    description: 'Achieve 80% success rate with 30+ entries',
    icon: Icons.star,
    color: Colors.orange,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 80 && 
                              AchievementHelpers.getTotalEntries(habit) >= 30,
  ),

  'excellence_standard': AchievementDefinition(
    id: 'excellence_standard',
    name: 'Excellence Standard',
    description: 'Achieve 90% success rate with 50+ entries',
    icon: Icons.verified,
    color: Colors.purple,
    points: 750,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 90 && 
                              AchievementHelpers.getTotalEntries(habit) >= 50,
  ),

  'perfectionist': AchievementDefinition(
    id: 'perfectionist',
    name: 'Perfectionist',
    description: 'Maintain 95% success rate with 100+ entries',
    icon: Icons.auto_awesome,
    color: Color(0xFFFFD700), // Gold
    points: 1500,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 95 && 
                              AchievementHelpers.getTotalEntries(habit) >= 100,
  ),

  'flawless_master': AchievementDefinition(
    id: 'flawless_master',
    name: 'Flawless Master',
    description: 'Maintain 100% success rate with 50+ entries',
    icon: Icons.diamond,
    color: Colors.cyan,
    points: 2000,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => AchievementHelpers.getSuccessRate(habit) >= 100 && 
                              AchievementHelpers.getTotalEntries(habit) >= 50,
  ),

  // Perfect Streaks
  'perfect_week': AchievementDefinition(
    id: 'perfect_week',
    name: 'Perfect Week',
    description: 'Complete 7 days without missing any',
    icon: Icons.check_circle,
    color: Colors.green,
    points: 150,
    rarity: AchievementRarity.common,
    checkCondition: (habit) => _checkPerfectDays(habit, 7),
  ),

  'perfect_month': AchievementDefinition(
    id: 'perfect_month',
    name: 'Perfect Month',
    description: 'Complete 30 days without missing any',
    icon: Icons.check_circle_outline,
    color: Colors.blue,
    points: 600,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkPerfectDays(habit, 30),
  ),

  'perfect_quarter': AchievementDefinition(
    id: 'perfect_quarter',
    name: 'Perfect Quarter',
    description: 'Complete 90 days without missing any',
    icon: Icons.workspace_premium,
    color: Colors.purple,
    points: 1800,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => _checkPerfectDays(habit, 90),
  ),

  // Comeback Achievements
  'comeback_kid': AchievementDefinition(
    id: 'comeback_kid',
    name: 'Comeback Kid',
    description: 'Improve from 30% to 80% success rate',
    icon: Icons.trending_up,
    color: Colors.orange,
    points: 500,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkComebackStory(habit),
  ),

  'turnaround_master': AchievementDefinition(
    id: 'turnaround_master',
    name: 'Turnaround Master',
    description: 'Improve from 20% to 90% success rate',
    icon: Icons.refresh,
    color: Colors.green,
    points: 1000,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkTurnaroundStory(habit),
  ),

  // Pattern Achievements
  'steady_eddie': AchievementDefinition(
    id: 'steady_eddie',
    name: 'Steady Eddie',
    description: 'Maintain same success rate (±5%) for 30 days',
    icon: Icons.straighten,
    color: Colors.blueGrey,
    points: 300,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkSteadyPattern(habit),
  ),

  'gradual_improvement': AchievementDefinition(
    id: 'gradual_improvement',
    name: 'Gradual Improvement',
    description: 'Improve success rate by 1% each week for 8 weeks',
    icon: Icons.stacked_line_chart,
    color: Colors.teal,
    points: 800,
    rarity: AchievementRarity.rare,
    checkCondition: (habit) => _checkGradualImprovement(habit),
  ),

  'weekend_consistency': AchievementDefinition(
    id: 'weekend_consistency',
    name: 'Weekend Consistency',
    description: 'Complete 90% of weekend habits for 2 months',
    icon: Icons.weekend,
    color: Colors.indigo,
    points: 400,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkWeekendConsistency(habit),
  ),

  'weekday_warrior': AchievementDefinition(
    id: 'weekday_warrior',
    name: 'Weekday Warrior',
    description: 'Complete 95% of weekday habits for 1 month',
    icon: Icons.business_center,
    color: Colors.brown,
    points: 350,
    rarity: AchievementRarity.uncommon,
    checkCondition: (habit) => _checkWeekdayConsistency(habit),
  ),

  // Advanced Consistency
  'never_miss_twice': AchievementDefinition(
    id: 'never_miss_twice',
    name: 'Never Miss Twice',
    description: 'Never miss the same habit two days in a row for 60 days',
    icon: Icons.block,
    color: Colors.red,
    points: 1200,
    rarity: AchievementRarity.epic,
    checkCondition: (habit) => _checkNeverMissTwice(habit),
  ),

  'habit_guardian': AchievementDefinition(
    id: 'habit_guardian',
    name: 'Habit Guardian',
    description: 'Maintain 85%+ success rate for 6 months straight',
    icon: Icons.shield,
    color: Color(0xFFFFD700), // Gold
    points: 2500,
    rarity: AchievementRarity.legendary,
    checkCondition: (habit) => _checkLongTermConsistency(habit),
  ),

  'consistency_legend': AchievementDefinition(
    id: 'consistency_legend',
    name: 'Consistency Legend',
    description: 'Maintain 90%+ success rate for 1 year',
    icon: Icons.emoji_events,
    color: Colors.amber,
    points: 5000,
    rarity: AchievementRarity.mythic,
    checkCondition: (habit) => _checkYearlyConsistency(habit),
  ),
};

// Helper functions for consistency achievements
bool _checkPerfectDays(Habit habit, int targetDays) {
  if (habit.entries.length < targetDays) return false;
  
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= targetDays)
      .toList();
  
  return recentEntries.length >= targetDays && 
         recentEntries.every((entry) => habit.isPositiveDay(entry));
}

bool _checkComebackStory(Habit habit) {
  if (habit.entries.length < 20) return false;
  
  // Check if early success rate was low and current is high
  final earlyEntries = habit.entries.take(10).toList();
  final recentEntries = habit.entries.skip(habit.entries.length - 10).toList();
  
  final earlySuccess = earlyEntries.where((e) => habit.isPositiveDay(e)).length / earlyEntries.length * 100;
  final recentSuccess = recentEntries.where((e) => habit.isPositiveDay(e)).length / recentEntries.length * 100;
  
  return earlySuccess <= 30 && recentSuccess >= 80;
}

bool _checkTurnaroundStory(Habit habit) {
  if (habit.entries.length < 30) return false;
  
  final earlyEntries = habit.entries.take(15).toList();
  final recentEntries = habit.entries.skip(habit.entries.length - 15).toList();
  
  final earlySuccess = earlyEntries.where((e) => habit.isPositiveDay(e)).length / earlyEntries.length * 100;
  final recentSuccess = recentEntries.where((e) => habit.isPositiveDay(e)).length / recentEntries.length * 100;
  
  return earlySuccess <= 20 && recentSuccess >= 90;
}

bool _checkSteadyPattern(Habit habit) {
  if (habit.entries.length < 30) return false;
  
  // Check if success rate has remained steady
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 30)
      .toList();
  
  if (recentEntries.length < 30) return false;
  
  // Calculate weekly success rates
  final weeklyRates = <double>[];
  for (int week = 0; week < 4; week++) {
    final weekEntries = recentEntries
        .where((e) => DateTime.now().difference(e.date).inDays >= week * 7 &&
                     DateTime.now().difference(e.date).inDays < (week + 1) * 7)
        .toList();
    
    if (weekEntries.isNotEmpty) {
      final weekRate = weekEntries.where((e) => habit.isPositiveDay(e)).length / weekEntries.length * 100;
      weeklyRates.add(weekRate);
    }
  }
  
  if (weeklyRates.length < 4) return false;
  
  // Check if all weekly rates are within 5% of each other
  final avgRate = weeklyRates.reduce((a, b) => a + b) / weeklyRates.length;
  return weeklyRates.every((rate) => (rate - avgRate).abs() <= 5);
}

bool _checkGradualImprovement(Habit habit) {
  // Implementation would check for gradual improvement pattern
  return false; // Placeholder
}

bool _checkWeekendConsistency(Habit habit) {
  // Implementation would check weekend completion rate
  return false; // Placeholder
}

bool _checkWeekdayConsistency(Habit habit) {
  // Implementation would check weekday completion rate
  return false; // Placeholder
}

bool _checkNeverMissTwice(Habit habit) {
  if (habit.entries.length < 60) return false;
  
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 60)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  
  for (int i = 0; i < recentEntries.length - 1; i++) {
    final current = recentEntries[i];
    final next = recentEntries[i + 1];
    
    if (!habit.isPositiveDay(current) && !habit.isPositiveDay(next)) {
      // Check if they are consecutive days
      if (next.date.difference(current.date).inDays == 1) {
        return false;
      }
    }
  }
  
  return true;
}

bool _checkLongTermConsistency(Habit habit) {
  if (habit.entries.length < 180) return false; // 6 months
  
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 180)
      .toList();
  
  final successRate = recentEntries.where((e) => habit.isPositiveDay(e)).length / recentEntries.length * 100;
  return successRate >= 85;
}

bool _checkYearlyConsistency(Habit habit) {
  if (habit.entries.length < 365) return false; // 1 year
  
  final recentEntries = habit.entries
      .where((entry) => DateTime.now().difference(entry.date).inDays <= 365)
      .toList();
  
  final successRate = recentEntries.where((e) => habit.isPositiveDay(e)).length / recentEntries.length * 100;
  return successRate >= 90;
} 