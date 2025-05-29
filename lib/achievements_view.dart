import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flux/achievements_system.dart';
import 'package:flux/habit.dart';
import 'package:flux/storage_service.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({Key? key}) : super(key: key);
  
  @override
  _AchievementsViewState createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> {
  List<Habit> _habits = [];
  Set<String> _globalUnlockedAchievements = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }
  
  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    
    final habits = await StorageService.loadAll();
    final globalUnlocked = <String>{};
    
    // Collect all unlocked achievements across all habits
    for (final habit in habits) {
      globalUnlocked.addAll(habit.unlockedAchievements);
    }
    
    setState(() {
      _habits = habits;
      _globalUnlockedAchievements = globalUnlocked;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _buildAchievementsGrid(),
    );
  }
  
  Widget _buildAchievementsGrid() {
    final achievementCategories = _categorizeAchievements();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _buildSummaryCard(),
          SizedBox(height: 24),
          
          // Achievement categories
          ...achievementCategories.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(category.key),
                SizedBox(height: 12),
                _buildCategoryGrid(category.value),
                SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final totalAchievements = AchievementsSystem.achievementDefinitions.length;
    final unlockedCount = _globalUnlockedAchievements.length;
    final progress = totalAchievements > 0 ? unlockedCount / totalAchievements : 0.0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$unlockedCount / $totalAchievements unlocked',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryHeader(String category) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          category,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryGrid(List<AchievementDefinition> achievements) {
    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: Duration(milliseconds: 600),
            columnCount: 2,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildAchievementCard(achievements[index]),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAchievementCard(AchievementDefinition achievement) {
    final isUnlocked = _globalUnlockedAchievements.contains(achievement.id);
    
    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement, isUnlocked),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    achievement.rarity.color.withOpacity(0.1),
                    achievement.color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked 
                ? achievement.rarity.color.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: achievement.rarity.color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked 
                      ? achievement.color
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                isUnlocked ? achievement.icon : Icons.help_outline,
                size: 30,
                color: isUnlocked 
                    ? achievement.color
                    : Colors.grey,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Achievement name
            Text(
              isUnlocked ? achievement.name : '????',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isUnlocked 
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 4),
            
            // Rarity badge
            if (isUnlocked) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: achievement.rarity.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: achievement.rarity.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  achievement.rarity.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: achievement.rarity.color,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 8),
            
            // Points
            if (isUnlocked) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${achievement.points}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showAchievementDetails(AchievementDefinition achievement, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      achievement.rarity.color.withOpacity(0.1),
                      achievement.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? achievement.color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked 
                        ? achievement.color
                        : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Icon(
                  isUnlocked ? achievement.icon : Icons.lock,
                  size: 50,
                  color: isUnlocked 
                      ? achievement.color
                      : Colors.grey,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Achievement name
              Text(
                isUnlocked ? achievement.name : 'Locked Achievement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked 
                      ? Theme.of(context).textTheme.headlineSmall?.color
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 12),
              
              // Rarity
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? achievement.rarity.color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnlocked 
                        ? achievement.rarity.color
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  isUnlocked ? achievement.rarity.name : 'Unknown Rarity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? achievement.rarity.color
                        : Colors.grey,
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                isUnlocked 
                    ? achievement.description
                    : 'Complete more habits to unlock this achievement and discover its requirements!',
                style: TextStyle(
                  fontSize: 16,
                  color: isUnlocked 
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (isUnlocked) ...[
                SizedBox(height: 20),
                
                // Points reward
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '${achievement.points} Points Earned',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked 
                      ? achievement.color
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Map<String, List<AchievementDefinition>> _categorizeAchievements() {
    final categories = <String, List<AchievementDefinition>>{};
    final badAchievements = <AchievementDefinition>[];
    
    for (final achievement in AchievementsSystem.achievementDefinitions.values) {
      // Separate bad achievements
      if (achievement.points < 0) {
        badAchievements.add(achievement);
        continue;
      }
      
      String category;
      
      // Categorize based on achievement ID patterns
      if (achievement.id.contains('week') || achievement.id.contains('month') || 
          achievement.id.contains('centurion') || achievement.id.contains('year')) {
        category = 'Streak Masters';
      } else if (achievement.id.contains('started') || achievement.id.contains('century') || 
                 achievement.id.contains('dedication')) {
        category = 'Entry Milestones';
      } else if (achievement.id.contains('consistency') || achievement.id.contains('perfectionist')) {
        category = 'Consistency Champions';
      } else if (achievement.id.contains('point') || achievement.id.contains('thousand') || 
                 achievement.id.contains('legend')) {
        category = 'Point Collectors';
      } else {
        category = 'Special Achievements';
      }
      
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(achievement);
    }
    
    // Add bad achievements as a separate category
    if (badAchievements.isNotEmpty) {
      categories['🚫 Bad Ones'] = badAchievements;
    }
    
    // Sort achievements within each category by rarity
    for (final categoryAchievements in categories.values) {
      categoryAchievements.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
    }
    
    return categories;
  }
} 