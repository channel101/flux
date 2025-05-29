import 'package:flutter/material.dart';
import 'package:flux/achievements/achievement_base.dart';
import 'package:flux/habit.dart';

final Map<String, AchievementDefinition> badAchievements = {
  // Procrastination Achievements
  'procrastinator': AchievementDefinition(
    id: 'procrastinator',
    name: 'Master Procrastinator',
    description: 'Skipped a habit 10 times in a row',
    icon: Icons.snooze,
    color: Colors.red,
    points: -50,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => AchievementHelpers.getConsecutiveSkips(habit) >= 10,
  ),

  'chronic_delayer': AchievementDefinition(
    id: 'chronic_delayer',
    name: 'Chronic Delayer',
    description: 'Postponed habits 25 times',
    icon: Icons.schedule,
    color: Colors.red,
    points: -100,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkPostponements(habit, 25),
  ),

  'tomorrow_champion': AchievementDefinition(
    id: 'tomorrow_champion',
    name: 'Tomorrow Champion',
    description: '"I\'ll start tomorrow" - said 50 times',
    icon: Icons.event,
    color: Colors.red,
    points: -200,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkTomorrowSyndrome(habit),
  ),

  // Laziness Achievements
  'couch_potato': AchievementDefinition(
    id: 'couch_potato',
    name: 'Couch Potato Champion',
    description: 'Ignored all habits for a week straight',
    icon: Icons.weekend,
    color: Colors.red,
    points: -150,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => AchievementHelpers.getDaysWithoutActivity(habit) >= 7,
  ),

  'hibernation_master': AchievementDefinition(
    id: 'hibernation_master',
    name: 'Hibernation Master',
    description: 'Didn\'t touch the app for 30 days',
    icon: Icons.hotel,
    color: Colors.red,
    points: -300,
    rarity: AchievementRarity.epic,
    isBadAchievement: true,
    checkCondition: (habit) => AchievementHelpers.getDaysWithoutActivity(habit) >= 30,
  ),

  'digital_hermit': AchievementDefinition(
    id: 'digital_hermit',
    name: 'Digital Hermit',
    description: 'Vanished from the app for 90 days',
    icon: Icons.phone_disabled,
    color: Colors.red,
    points: -500,
    rarity: AchievementRarity.legendary,
    isBadAchievement: true,
    checkCondition: (habit) => AchievementHelpers.getDaysWithoutActivity(habit) >= 90,
  ),

  // Excuse Making
  'excuse_master': AchievementDefinition(
    id: 'excuse_master',
    name: 'Excuse Master',
    description: 'Found 100 creative excuses',
    icon: Icons.emoji_people,
    color: Colors.red,
    points: -250,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkExcuseMaking(habit),
  ),

  'weather_dependent': AchievementDefinition(
    id: 'weather_dependent',
    name: 'Weather Dependent',
    description: 'Blamed the weather 20 times',
    icon: Icons.wb_cloudy,
    color: Colors.red,
    points: -75,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => _checkWeatherExcuses(habit),
  ),

  'traffic_victim': AchievementDefinition(
    id: 'traffic_victim',
    name: 'Traffic Victim',
    description: 'Blamed traffic for missing habits 15 times',
    icon: Icons.traffic,
    color: Colors.red,
    points: -60,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => _checkTrafficExcuses(habit),
  ),

  // Streak Breaking
  'streak_breaker': AchievementDefinition(
    id: 'streak_breaker',
    name: 'Streak Breaker',
    description: 'Broke a 30+ day streak',
    icon: Icons.heart_broken,
    color: Colors.red,
    points: -200,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkStreakBreaking(habit, 30),
  ),

  'dream_crusher': AchievementDefinition(
    id: 'dream_crusher',
    name: 'Dream Crusher',
    description: 'Broke a 100+ day streak',
    icon: Icons.dangerous,
    color: Colors.red,
    points: -500,
    rarity: AchievementRarity.epic,
    isBadAchievement: true,
    checkCondition: (habit) => _checkStreakBreaking(habit, 100),
  ),

  'serial_quitter': AchievementDefinition(
    id: 'serial_quitter',
    name: 'Serial Quitter',
    description: 'Abandoned 10 different habits',
    icon: Icons.exit_to_app,
    color: Colors.red,
    points: -400,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkSerialQuitting(habit),
  ),

  // Bad Timing
  'midnight_snacker': AchievementDefinition(
    id: 'midnight_snacker',
    name: 'Midnight Snacker',
    description: 'Failed diet habits 30 times at night',
    icon: Icons.nightlight,
    color: Colors.red,
    points: -120,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkMidnightFailures(habit),
  ),

  'weekend_warrior_fail': AchievementDefinition(
    id: 'weekend_warrior_fail',
    name: 'Weekend Warrior Fail',
    description: 'Only fails habits on weekends',
    icon: Icons.weekend,
    color: Colors.red,
    points: -100,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => _checkWeekendFailures(habit),
  ),

  // Self-Sabotage
  'self_saboteur': AchievementDefinition(
    id: 'self_saboteur',
    name: 'Self Saboteur',
    description: 'Perfectly sabotaged your own progress',
    icon: Icons.self_improvement,
    color: Colors.red,
    points: -300,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkSelfSabotage(habit),
  ),

  'perfectionist_paralysis': AchievementDefinition(
    id: 'perfectionist_paralysis',
    name: 'Perfectionist Paralysis',
    description: 'Too afraid to start because it won\'t be perfect',
    icon: Icons.pause_circle,
    color: Colors.red,
    points: -150,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkPerfectionistParalysis(habit),
  ),

  // Notification Negligence
  'notification_ninja': AchievementDefinition(
    id: 'notification_ninja',
    name: 'Notification Ninja',
    description: 'Ignored 100 habit reminders',
    icon: Icons.notifications_off,
    color: Colors.red,
    points: -200,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkIgnoredNotifications(habit),
  ),

  'snooze_champion': AchievementDefinition(
    id: 'snooze_champion',
    name: 'Snooze Champion',
    description: 'Snoozed alarms 50 times',
    icon: Icons.alarm_off,
    color: Colors.red,
    points: -100,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => _checkSnoozeCount(habit),
  ),

  // Ambition Overload
  'wishful_thinker': AchievementDefinition(
    id: 'wishful_thinker',
    name: 'Wishful Thinker',
    description: 'Set unrealistic goals and failed them all',
    icon: Icons.cloud,
    color: Colors.red,
    points: -180,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkUnrealisticGoals(habit),
  ),

  'habit_hoarder': AchievementDefinition(
    id: 'habit_hoarder',
    name: 'Habit Hoarder',
    description: 'Created 20 habits but only completed 5',
    icon: Icons.inventory_2,
    color: Colors.red,
    points: -250,
    rarity: AchievementRarity.rare,
    isBadAchievement: true,
    checkCondition: (habit) => _checkHabitHoarding(habit),
  ),

  // Funny Fails
  'monday_hater': AchievementDefinition(
    id: 'monday_hater',
    name: 'Monday Hater',
    description: 'Failed habits specifically on Mondays 10 times',
    icon: Icons.sentiment_very_dissatisfied,
    color: Colors.red,
    points: -80,
    rarity: AchievementRarity.common,
    isBadAchievement: true,
    checkCondition: (habit) => _checkMondayFailures(habit),
  ),

  'motivation_vampire': AchievementDefinition(
    id: 'motivation_vampire',
    name: 'Motivation Vampire',
    description: 'Sucked the motivation out of everything',
    icon: Icons.sentiment_dissatisfied,
    color: Colors.red,
    points: -150,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkMotivationDrain(habit),
  ),

  'commitment_phobia': AchievementDefinition(
    id: 'commitment_phobia',
    name: 'Commitment Phobia',
    description: 'Scared of commitment to any habit',
    icon: Icons.warning,
    color: Colors.red,
    points: -120,
    rarity: AchievementRarity.uncommon,
    isBadAchievement: true,
    checkCondition: (habit) => _checkCommitmentIssues(habit),
  ),
};

// Helper functions for bad achievements
bool _checkPostponements(Habit habit, int count) {
  // Implementation would track postponement behavior
  return false; // Placeholder
}

bool _checkTomorrowSyndrome(Habit habit) {
  // Implementation would track "tomorrow" promises
  return false; // Placeholder
}

bool _checkExcuseMaking(Habit habit) {
  // Implementation would track excuse patterns
  return false; // Placeholder
}

bool _checkWeatherExcuses(Habit habit) {
  // Implementation would track weather-related excuses
  return false; // Placeholder
}

bool _checkTrafficExcuses(Habit habit) {
  // Implementation would track traffic-related excuses
  return false; // Placeholder
}

bool _checkStreakBreaking(Habit habit, int minStreak) {
  // Check if a significant streak was broken
  return false; // Placeholder - would need streak history
}

bool _checkSerialQuitting(Habit habit) {
  // Implementation would check across multiple habits
  return false; // Placeholder
}

bool _checkMidnightFailures(Habit habit) {
  int nightFailures = 0;
  for (final entry in habit.entries) {
    if (entry.date.hour >= 22 && !habit.isPositiveDay(entry)) {
      nightFailures++;
    }
  }
  return nightFailures >= 30;
}

bool _checkWeekendFailures(Habit habit) {
  int weekendFailures = 0;
  int weekendTotal = 0;
  
  for (final entry in habit.entries) {
    if (entry.date.weekday == DateTime.saturday || 
        entry.date.weekday == DateTime.sunday) {
      weekendTotal++;
      if (!habit.isPositiveDay(entry)) {
        weekendFailures++;
      }
    }
  }
  
  return weekendTotal > 10 && (weekendFailures / weekendTotal) > 0.8;
}

bool _checkSelfSabotage(Habit habit) {
  // Implementation would detect self-sabotage patterns
  return false; // Placeholder
}

bool _checkPerfectionistParalysis(Habit habit) {
  // Check for patterns of starting and stopping quickly
  if (habit.entries.isEmpty) return false;
  
  final firstEntry = habit.entries.reduce((a, b) => 
    a.date.isBefore(b.date) ? a : b);
  
  return habit.entries.length < 5 && 
         DateTime.now().difference(firstEntry.date).inDays > 30;
}

bool _checkIgnoredNotifications(Habit habit) {
  // Implementation would track notification interactions
  return false; // Placeholder
}

bool _checkSnoozeCount(Habit habit) {
  // Implementation would track snooze behavior
  return false; // Placeholder
}

bool _checkUnrealisticGoals(Habit habit) {
  return habit.targetValue != null && 
         habit.targetValue! > 100 && 
         AchievementHelpers.getSuccessRate(habit) < 10;
}

bool _checkHabitHoarding(Habit habit) {
  // Implementation would check across all user habits
  return false; // Placeholder
}

bool _checkMondayFailures(Habit habit) {
  int mondayFailures = 0;
  for (final entry in habit.entries) {
    if (entry.date.weekday == DateTime.monday && !habit.isPositiveDay(entry)) {
      mondayFailures++;
    }
  }
  return mondayFailures >= 10;
}

bool _checkMotivationDrain(Habit habit) {
  // Implementation would check for consistent motivation decline
  return false; // Placeholder
}

bool _checkCommitmentIssues(Habit habit) {
  if (habit.entries.isEmpty) return false;
  
  final firstEntry = habit.entries.reduce((a, b) => 
    a.date.isBefore(b.date) ? a : b);
  
  return habit.entries.length < 10 && 
         DateTime.now().difference(firstEntry.date).inDays > 60;
} 