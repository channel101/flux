import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flux/habit.dart';
import 'package:flux/notification_service.dart';
import 'package:flux/storage_service.dart';

class AchievementsSystem {
  // Easy-to-edit achievement definitions
  static const Map<String, AchievementDefinition> achievementDefinitions = {
    // Streak Achievements
    'first_week': AchievementDefinition(
      id: 'first_week',
      name: 'First Week Warrior',
      description: 'Complete a 7-day streak',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      points: 100,
      rarity: AchievementRarity.common,
    ),
    'first_month': AchievementDefinition(
      id: 'first_month',
      name: 'Month Master',
      description: 'Complete a 30-day streak',
      icon: Icons.emoji_events,
      color: Colors.amber,
      points: 500,
      rarity: AchievementRarity.rare,
    ),
    'centurion': AchievementDefinition(
      id: 'centurion',
      name: '100-Day Centurion',
      description: 'Complete a legendary 100-day streak',
      icon: Icons.military_tech,
      color: Colors.deepPurple,
      points: 2000,
      rarity: AchievementRarity.legendary,
    ),
    'year_warrior': AchievementDefinition(
      id: 'year_warrior',
      name: 'Year Warrior',
      description: 'Complete an epic 365-day streak',
      icon: Icons.workspace_premium,
      color: Colors.amber,
      points: 10000,
      rarity: AchievementRarity.mythic,
    ),
    
    // Entry Count Achievements
    'getting_started': AchievementDefinition(
      id: 'getting_started',
      name: 'Getting Started',
      description: 'Complete 10 entries',
      icon: Icons.play_arrow,
      color: Colors.green,
      points: 50,
      rarity: AchievementRarity.common,
    ),
    'half_century': AchievementDefinition(
      id: 'half_century',
      name: 'Half Century',
      description: 'Complete 50 entries',
      icon: Icons.trending_up,
      color: Colors.blue,
      points: 250,
      rarity: AchievementRarity.uncommon,
    ),
    'century_club': AchievementDefinition(
      id: 'century_club',
      name: 'Century Club',
      description: 'Complete 100 entries',
      icon: Icons.verified,
      color: Colors.purple,
      points: 1000,
      rarity: AchievementRarity.rare,
    ),
    'dedication_master': AchievementDefinition(
      id: 'dedication_master',
      name: 'Dedication Master',
      description: 'Complete 500 entries',
      icon: Icons.diamond,
      color: Colors.cyan,
      points: 5000,
      rarity: AchievementRarity.legendary,
    ),
    
    // Consistency Achievements
    'consistency_king': AchievementDefinition(
      id: 'consistency_king',
      name: 'Consistency King',
      description: 'Achieve 80% success rate with 20+ entries',
      icon: Icons.star,
      color: Colors.yellow,
      points: 750,
      rarity: AchievementRarity.rare,
    ),
    'perfectionist': AchievementDefinition(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Maintain 100% success rate for 30 days',
      icon: Icons.auto_awesome,
      color: Colors.purple,
      rarity: AchievementRarity.Epic,
      points: 500,
      checkCondition: (habit) => 
        habit.successRate >= 100 && habit.currentStreak >= 30,
    ),
    
    // Points Achievements
    'first_thousand': AchievementDefinition(
      id: 'first_thousand',
      name: 'First Thousand',
      description: 'Earn 1,000 points',
      icon: Icons.savings,
      color: Colors.teal,
      points: 100,
      rarity: AchievementRarity.uncommon,
    ),
    'point_collector': AchievementDefinition(
      id: 'point_collector',
      name: 'Point Collector',
      description: 'Earn 5,000 points',
      icon: Icons.account_balance_wallet,
      color: Colors.indigo,
      points: 500,
      rarity: AchievementRarity.rare,
    ),
    'point_master': AchievementDefinition(
      id: 'point_master',
      name: 'Point Master',
      description: 'Earn 10,000 points',
      icon: Icons.monetization_on,
      color: Colors.amber,
      points: 1000,
      rarity: AchievementRarity.legendary,
    ),
    'legend': AchievementDefinition(
      id: 'legend',
      name: 'Legend',
      description: 'Earn 25,000 points',
      icon: Icons.auto_awesome,
      color: Colors.deepOrange,
      points: 2500,
      rarity: AchievementRarity.mythic,
    ),
    
    // Special Achievements
    'early_bird': AchievementDefinition(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a habit before 7 AM',
      icon: Icons.wb_sunny,
      color: Colors.orange,
      points: 200,
      rarity: AchievementRarity.uncommon,
    ),
    'night_owl': AchievementDefinition(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a habit after 10 PM',
      icon: Icons.nights_stay,
      color: Colors.indigo,
      points: 200,
      rarity: AchievementRarity.uncommon,
    ),
    'comeback_kid': AchievementDefinition(
      id: 'comeback_kid',
      name: 'Comeback Kid',
      description: 'Start a new streak after a 7+ day break',
      icon: Icons.refresh,
      color: Colors.green,
      points: 300,
      rarity: AchievementRarity.rare,
    ),
    
    // Bad/Joke Achievements (Red colored)
    'procrastinator': AchievementDefinition(
      id: 'procrastinator',
      name: 'Master Procrastinator',
      description: 'Skipped a habit 10 times in a row',
      icon: Icons.snooze,
      color: Colors.red,
      rarity: AchievementRarity.Common,
      points: -50,
      isBadAchievement: true,
      checkCondition: (habit) => _getConsecutiveSkips(habit) >= 10,
    ),
    'couch_potato': AchievementDefinition(
      id: 'couch_potato',
      name: 'Couch Potato Champion',
      description: 'Ignored all habits for a week straight',
      icon: Icons.weekend,
      color: Colors.red,
      rarity: AchievementRarity.Uncommon,
      points: -100,
      isBadAchievement: true,
      checkCondition: (habit) => _getDaysWithoutActivity(habit) >= 7,
    ),
    'excuse_master': AchievementDefinition(
      id: 'excuse_master',
      name: 'Excuse Master',
      description: 'Created 50 habits but completed none',
      icon: Icons.emoji_people,
      color: Colors.red,
      rarity: AchievementRarity.Rare,
      points: -200,
      isBadAchievement: true,
      checkCondition: (habit) => false, // This will be checked globally
    ),
    'digital_hermit': AchievementDefinition(
      id: 'digital_hermit',
      name: 'Digital Hermit',
      description: "Haven't opened the app in 30 days",
      icon: Icons.phone_disabled,
      color: Colors.red,
      rarity: AchievementRarity.Epic,
      points: -300,
      isBadAchievement: true,
      checkCondition: (habit) => false, // This will be checked globally
    ),
    'broken_promises': AchievementDefinition(
      id: 'broken_promises',
      name: 'Broken Promises',
      description: 'Reset your streak 20 times',
      icon: Icons.heart_broken,
      color: Colors.red,
      rarity: AchievementRarity.Uncommon,
      points: -150,
      isBadAchievement: true,
      checkCondition: (habit) => _getStreakResets(habit) >= 20,
    ),
    'habit_hoarder': AchievementDefinition(
      id: 'habit_hoarder',
      name: 'Habit Hoarder',
      description: 'Created 100 habits but only use 5',
      icon: Icons.inventory_2,
      color: Colors.red,
      rarity: AchievementRarity.Rare,
      points: -250,
      isBadAchievement: true,
      checkCondition: (habit) => false, // This will be checked globally
    ),
    'midnight_snacker': AchievementDefinition(
      id: 'midnight_snacker',
      name: 'Midnight Snacker',
      description: 'Failed your diet habit 30 times',
      icon: Icons.nightlight,
      color: Colors.red,
      rarity: AchievementRarity.Common,
      points: -75,
      isBadAchievement: true,
      checkCondition: (habit) => 
        habit.name.toLowerCase().contains('diet') && habit.negativeCount >= 30,
    ),
    'wishful_thinker': AchievementDefinition(
      id: 'wishful_thinker',
      name: 'Wishful Thinker',
      description: 'Set unrealistic targets and failed them all',
      icon: Icons.cloud,
      color: Colors.red,
      rarity: AchievementRarity.Uncommon,
      points: -125,
      isBadAchievement: true,
      checkCondition: (habit) => 
        habit.targetValue != null && habit.targetValue! > 10 && habit.successRate < 20,
    ),
    'notification_ignore': AchievementDefinition(
      id: 'notification_ignore',
      name: 'Notification Ninja',
      description: 'Ignored 100 habit reminders',
      icon: Icons.notifications_off,
      color: Colors.red,
      rarity: AchievementRarity.Rare,
      points: -200,
      isBadAchievement: true,
      checkCondition: (habit) => false, // This will be tracked separately
    ),
    'serial_quitter': AchievementDefinition(
      id: 'serial_quitter',
      name: 'Serial Quitter',
      description: 'Archived 25 habits without completing them',
      icon: Icons.exit_to_app,
      color: Colors.red,
      rarity: AchievementRarity.Epic,
      points: -400,
      isBadAchievement: true,
      checkCondition: (habit) => false, // This will be checked globally
    ),
  };
  
  // Check and award achievements for a habit
  static Future<List<AchievementEarned>> checkAndAwardAchievements(Habit habit) async {
    final newAchievements = <AchievementEarned>[];
    final achievementIds = habit.checkAchievements();
    
    for (final achievementText in achievementIds) {
      // Extract achievement ID from the text (remove emoji and "trophy" prefix)
      final achievementId = _extractAchievementId(achievementText);
      
      if (achievementDefinitions.containsKey(achievementId)) {
        final definition = achievementDefinitions[achievementId]!;
        final earned = AchievementEarned(
          definition: definition,
          earnedAt: DateTime.now(),
          habitName: habit.name,
        );
        
        newAchievements.add(earned);
        
        // Award points to habit
        final levelUpMessages = habit.addPoints(definition.points);
        
        // Show notification
        await NotificationService.showAchievementNotification(
          title: 'Achievement Unlocked! 🏆',
          body: '${definition.name}: ${definition.description}',
        );
        
        // Handle level ups
        for (final message in levelUpMessages) {
          if (message.contains('Level')) {
            final level = int.tryParse(message.replaceAll(RegExp(r'[^0-9]'), ''));
            if (level != null) {
              await NotificationService.showLevelUpNotification(habit, level);
            }
          }
        }
      }
    }
    
    // Save updated habit
    await StorageService.save(habit);
    
    return newAchievements;
  }
  
  static String _extractAchievementId(String achievementText) {
    // Remove emoji and extract the key part
    final cleaned = achievementText.replaceAll('🏆 ', '');
    
    // Map display names back to IDs
    final nameToId = {
      'First Week Warrior': 'first_week',
      'Month Master': 'first_month',
      '100-Day Centurion': 'centurion',
      'Year Warrior': 'year_warrior',
      'Getting Started': 'getting_started',
      'Half Century': 'half_century',
      'Century Club': 'century_club',
      'Dedication Master': 'dedication_master',
      'Consistency King': 'consistency_king',
      'Perfectionist': 'perfectionist',
      'First Thousand': 'first_thousand',
      'Point Collector': 'point_collector',
      'Point Master': 'point_master',
      'Legend': 'legend',
    };
    
    return nameToId[cleaned] ?? 'unknown';
  }
  
  // Show celebration effect
  static void showCelebrationEffect(BuildContext context, AchievementEarned achievement) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        achievement: achievement,
        onComplete: () => overlayEntry.remove(),
      ),
    );
    
    overlay.insert(overlayEntry);
  }
  
  // Get all achievements for a habit
  static List<AchievementEarned> getEarnedAchievements(Habit habit) {
    final earned = <AchievementEarned>[];
    
    for (final achievementId in habit.unlockedAchievements) {
      if (achievementDefinitions.containsKey(achievementId)) {
        earned.add(AchievementEarned(
          definition: achievementDefinitions[achievementId]!,
          earnedAt: DateTime.now(), // This would be stored properly in a real app
          habitName: habit.name,
        ));
      }
    }
    
    return earned;
  }
  
  // Get achievement progress
  static Map<String, double> getAchievementProgress(Habit habit) {
    final progress = <String, double>{};
    
    // Streak achievements
    progress['first_week'] = (habit.currentStreak / 7).clamp(0.0, 1.0);
    progress['first_month'] = (habit.currentStreak / 30).clamp(0.0, 1.0);
    progress['centurion'] = (habit.currentStreak / 100).clamp(0.0, 1.0);
    progress['year_warrior'] = (habit.currentStreak / 365).clamp(0.0, 1.0);
    
    // Entry count achievements
    progress['getting_started'] = (habit.entries.length / 10).clamp(0.0, 1.0);
    progress['half_century'] = (habit.entries.length / 50).clamp(0.0, 1.0);
    progress['century_club'] = (habit.entries.length / 100).clamp(0.0, 1.0);
    progress['dedication_master'] = (habit.entries.length / 500).clamp(0.0, 1.0);
    
    // Consistency achievements
    if (habit.entries.length >= 20) {
      progress['consistency_king'] = habit.successRate >= 80 ? 1.0 : (habit.successRate / 80);
    } else {
      progress['consistency_king'] = habit.entries.length / 20;
    }
    
    if (habit.entries.length >= 50) {
      progress['perfectionist'] = habit.successRate >= 95 ? 1.0 : (habit.successRate / 95);
    } else {
      progress['perfectionist'] = habit.entries.length / 50;
    }
    
    // Points achievements
    progress['first_thousand'] = (habit.totalPoints / 1000).clamp(0.0, 1.0);
    progress['point_collector'] = (habit.totalPoints / 5000).clamp(0.0, 1.0);
    progress['point_master'] = (habit.totalPoints / 10000).clamp(0.0, 1.0);
    progress['legend'] = (habit.totalPoints / 25000).clamp(0.0, 1.0);
    
    return progress;
  }
  
  // Helper methods for bad achievements
  static int _getConsecutiveSkips(Habit habit) {
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

  static int _getDaysWithoutActivity(Habit habit) {
    if (habit.entries.isEmpty) return 0;
    
    final lastEntry = habit.entries.reduce((a, b) => 
      a.date.isAfter(b.date) ? a : b);
    
    return DateTime.now().difference(lastEntry.date).inDays;
  }

  static int _getStreakResets(Habit habit) {
    // This would need to be tracked in the habit model
    // For now, we'll estimate based on entry patterns
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
}

// Data classes
class AchievementDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int points;
  final AchievementRarity rarity;
  final Function(Habit) checkCondition;
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

enum AchievementRarity {
  common,
  uncommon,
  rare,
  legendary,
  mythic,
  Epic,
  Common,
  Uncommon,
  Rare,
  Epic,
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
      case AchievementRarity.legendary:
        return Colors.purple;
      case AchievementRarity.mythic:
        return Colors.orange;
      case AchievementRarity.Epic:
        return Colors.purple;
      case AchievementRarity.Common:
        return Colors.red;
      case AchievementRarity.Uncommon:
        return Colors.red;
      case AchievementRarity.Rare:
        return Colors.red;
      case AchievementRarity.Epic:
        return Colors.red;
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
      case AchievementRarity.legendary:
        return 'Legendary';
      case AchievementRarity.mythic:
        return 'Mythic';
      case AchievementRarity.Epic:
        return 'Epic';
      case AchievementRarity.Common:
        return 'Common';
      case AchievementRarity.Uncommon:
        return 'Uncommon';
      case AchievementRarity.Rare:
        return 'Rare';
      case AchievementRarity.Epic:
        return 'Epic';
    }
  }
}

// Celebration overlay widget
class CelebrationOverlay extends StatefulWidget {
  final AchievementEarned achievement;
  final VoidCallback onComplete;
  
  const CelebrationOverlay({
    Key? key,
    required this.achievement,
    required this.onComplete,
  }) : super(key: key);
  
  @override
  _CelebrationOverlayState createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: Duration(seconds: 2),
    );
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    await Future.delayed(Duration(milliseconds: 100));
    _slideController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _scaleController.forward();
    _confettiController.play();
    
    // Auto-dismiss after 3 seconds
    await Future.delayed(Duration(seconds: 3));
    _dismiss();
  }
  
  void _dismiss() async {
    _confettiController.stop();
    await _slideController.reverse();
    widget.onComplete();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black54,
            ),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.5708, // Down
              particleDrag: 0.05,
              emissionFrequency: 0.3,
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: [
                widget.achievement.definition.color,
                widget.achievement.definition.rarity.color,
                Colors.yellow,
                Colors.red,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          
          // Achievement card
          Center(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, -1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.elasticOut,
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.elasticOut,
                )),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 300,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: widget.achievement.definition.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.achievement.definition.color,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            widget.achievement.definition.icon,
                            size: 40,
                            color: widget.achievement.definition.color,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.achievement.definition.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.achievement.definition.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.achievement.definition.rarity.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.achievement.definition.rarity.color,
                            ),
                          ),
                          child: Text(
                            widget.achievement.definition.rarity.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.achievement.definition.rarity.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '+${widget.achievement.definition.points} Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 