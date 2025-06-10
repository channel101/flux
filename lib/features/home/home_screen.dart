// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/features/habits/add_habit_sheet.dart';
import 'package:flux/main.dart';
import 'package:flux/features/settings/settings_screen.dart';
import 'package:flux/features/analytics/analytics_dashboard.dart';
import 'package:flux/core/services/data_service.dart';
import 'package:flux/core/services/reports_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flux/features/habits/add_entry_dialog.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/features/habits/habit_detail_screen.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/features/home/home_screen.dart';
import 'package:flux/core/services/settings_service.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flux/features/habits/quick_entry_widget.dart';
import 'package:flux/features/habits/bulk_edit_screen.dart';
import 'package:flux/core/services/widget_service.dart';
import 'package:flux/features/achievements/achievements_view.dart';
import 'package:flux/features/backup_and_import/backup_import_screen.dart';
import 'package:flux/features/gamification/points_screen.dart';
import 'package:flux/core/enums/app_enums.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final Function(String)? changeTheme;
  
  HomeScreen({
    required this.toggleTheme, 
    required this.isDarkMode,
    this.changeTheme,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Habit> _archivedHabits = [];
  List<Habit> _filteredHabits = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  int _totalPositiveDays = 0;
  int _totalNegativeDays = 0;
  double _overallSuccessRate = 0;
  int _totalEntries = 0;
  int _bestCurrentStreak = 0;
  String _bestStreakHabit = '';
  bool _showArchived = false;
  String? _selectedCategory;
  List<String> _categories = [];
  DateTime _selectedDate = DateTime.now();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _isLoading = true;
    _loadHabits();
    
    // Scroll to current date in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final centerIndex = 14; // Today's index in the date list
        _scrollController.animateTo(
          centerIndex * 65.0 - MediaQuery.of(context).size.width / 2 + 32.5,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final all = await StorageService.loadAll();
    
    // Filter active and archived habits
    final active = all.where((h) => !h.isArchived).toList();
    final archived = all.where((h) => h.isArchived).toList();
    
    // Extract categories
    final categories = active
        .where((h) => h.category != null)
        .map((h) => h.category!)
        .toSet()
        .toList()
        ..sort();
    
    // Apply category filter
    final filtered = _selectedCategory == null 
        ? active 
        : active.where((h) => h.category == _selectedCategory).toList();
    
    // Calculate overall metrics (using filtered habits)
    int totalPositive = 0;
    int totalNegative = 0;
    int totalEntries = 0;
    int bestStreak = 0;
    String bestStreakHabit = '';
    
    for (var habit in filtered) {
      totalPositive += habit.positiveCount;
      totalNegative += habit.negativeCount;
      totalEntries += habit.entries.length;
      
      if (habit.currentStreak > bestStreak) {
        bestStreak = habit.currentStreak;
        bestStreakHabit = habit.formattedName;
      }
    }
    
    setState(() {
      _habits = all;
      _activeHabits = active;
      _archivedHabits = archived;
      _filteredHabits = filtered;
      _categories = categories;
      _totalPositiveDays = totalPositive;
      _totalNegativeDays = totalNegative;
      _totalEntries = totalEntries;
      
      int totalDays = totalPositive + totalNegative;
      _overallSuccessRate = totalDays > 0 ? (totalPositive / totalDays) * 100 : 0;
      
      _bestCurrentStreak = bestStreak;
      _bestStreakHabit = bestStreakHabit;
      _isLoading = false;
    });
    
    // Update home widgets
    await WidgetService.updateHomeWidgets();
  }

  void _showAddHabit() {
    // Get existing categories
    final existingCategories = _activeHabits
        .where((h) => h.category != null)
        .map((h) => h.category!)
        .toSet()
        .toList()
        ..sort();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(
        existingCategories: existingCategories,
        onSave: (h) async {
          if (h.name.isEmpty) return;
          await StorageService.save(h);
          Navigator.pop(context);
          _loadHabits();
        }
      ),
    );
  }
  
  void _openSettings() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => SettingsScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ))
    ).then((_) => _loadHabits());
  }
  
  void _toggleArchiveView() {
    setState(() {
      _showArchived = !_showArchived;
    });
  }
  
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Categories'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            ),
            ..._categories.map((category) => ListTile(
              title: Text(category),
              leading: Radio<String?>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadHabits();
                  Navigator.pop(context);
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyticsDashboard(habits: _filteredHabits),
      ),
    );
  }

  void _openBackupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupImportScreen(),
      ),
    );
  }

  void _openPointsScreen() {
    // Points screen functionality commented out
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointsScreen(),
      ),
    );
    */
  }

  void _showYearInReview() {
    final currentYear = DateTime.now().year;
    final yearReview = ReportsService.generateYearInReview(_filteredHabits, currentYear);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$currentYear Year in Review'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (yearReview.totalHabits == 0) ...[
                Text('No data available for $currentYear'),
                SizedBox(height: 16),
                Text('Start tracking habits to see your year in review!'),
              ] else ...[
                Text('🎯 Total Habits: ${yearReview.totalHabits}'),
                Text('📅 Total Entries: ${yearReview.totalEntries}'),
                Text('📊 Success Rate: ${yearReview.overallSuccessRate.toStringAsFixed(1)}%'),
                Text('🔥 Longest Streak: ${yearReview.longestStreak} days'),
                SizedBox(height: 16),
                if (yearReview.milestones.isNotEmpty) ...[
                  Text('🏆 Key Milestones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.milestones.take(3).map((milestone) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${milestone.title}'),
                  )),
                ],
                if (yearReview.insights.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('💡 Insights:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...yearReview.insights.take(3).map((insight) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${insight.title}: ${insight.description}'),
                  )),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openBulkEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkEditScreen(habits: _habits),
      ),
    ).then((_) => _loadHabits());
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showArchived ? 'Archived Habits' : 'Flux', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            if (!_showArchived && _selectedCategory != null && _selectedIndex == 1)
              Text(
                'Category: $_selectedCategory',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showArchived 
              ? _buildArchivedList()
              : _buildScreens()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
      floatingActionButton: !_showArchived && _selectedIndex < 2 ? FloatingActionButton(
        onPressed: _showAddHabit,
        child: Icon(Icons.add),
      ) : null,
    );
  }
  
  List<Widget> _buildAppBarActions() {
    if (_showArchived) {
      return [
        IconButton(
          icon: Icon(Icons.inventory_2_outlined),
          onPressed: _toggleArchiveView,
          tooltip: 'Show Active Habits',
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ];
    }
    
    if (_selectedIndex == 0) {
      // Home screen actions
      return [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ];
    } else if (_selectedIndex == 1) {
      // Habits screen actions
      return [
        if (_categories.isNotEmpty)
          IconButton(
            icon: Icon(_selectedCategory != null ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: _showCategoryFilter,
            tooltip: 'Filter by Category',
          ),
        IconButton(
          icon: Icon(_showArchived ? Icons.inventory_2_outlined : Icons.archive),
          onPressed: _toggleArchiveView,
          tooltip: _showArchived ? 'Show Active Habits' : 'Show Archived',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'bulk_edit':
                _openBulkEdit();
                break;
              case 'backup':
                _openBackupScreen();
                break;
              case 'year_review':
                _showYearInReview();
                break;
              case 'achievements':
                _openAchievements();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'bulk_edit',
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 18),
                  SizedBox(width: 8),
                  Text('Bulk Edit'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup, size: 18),
                  SizedBox(width: 8),
                  Text('Backup & Import'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'year_review',
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18),
                  SizedBox(width: 8),
                  Text('Year in Review'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'achievements',
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 18),
                  SizedBox(width: 8),
                  Text('Achievements'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ];
    } else {
      // Analytics screen actions
      return [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: _openSettings,
        ),
      ];
    }
  }
  
  List<Widget> _buildScreens() {
    return [
      _buildHomeScreen(),
      _buildHabitsScreen(),
      AnalyticsDashboard(habits: _activeHabits),
    ];
  }
  
  Widget _buildHomeScreen() {
    if (_habits.isEmpty) {
      return _buildEmpty();
    }
    
    // Get habits for the selected date
    final selectedDateHabits = _getHabitsForDate(_selectedDate);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImprovedDateSelector(),
          SizedBox(height: 16),
          _buildEnhancedQuickEntry(selectedDateHabits),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildDashboardSummary(),
        ],
      ),
    );
  }
  
  List<Habit> _getHabitsForDate(DateTime date) {
    // For today, show habits that are due today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay.isAtSameMomentAs(today)) {
      return _filteredHabits.where((h) => h.isDueToday()).toList();
    }
    
    // For past dates, show habits that had entries on that date
    // For future dates, show habits based on their frequency
    return _filteredHabits.where((habit) {
      if (selectedDay.isBefore(today)) {
        // Past date - check if there was an entry
        return habit.entries.any((entry) {
          final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate.isAtSameMomentAs(selectedDay);
        });
      } else {
        // Future date - check if habit would be due based on frequency
        switch (habit.frequency) {
          case HabitFrequency.Daily:
            return true;
          case HabitFrequency.Weekdays:
            return selectedDay.weekday <= 5; // Monday = 1, Friday = 5
          case HabitFrequency.Weekends:
            return selectedDay.weekday > 5; // Saturday = 6, Sunday = 7
          case HabitFrequency.CustomDays:
            final dayIndex = selectedDay.weekday % 7; // Convert to 0=Sunday format
            return habit.customDays.contains(dayIndex);
          case HabitFrequency.XTimesPerWeek:
          case HabitFrequency.XTimesPerMonth:
            // These are harder to predict for future dates
            return true;
        }
      }
    }).toList();
  }
  
  Widget _buildImprovedDateSelector() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(30, (index) {
      final date = today.add(Duration(days: index - 14)); // 2 weeks before and after today
      return date;
    });
    
    final currentIndex = dates.indexWhere((date) => 
      date.year == _selectedDate.year && 
      date.month == _selectedDate.month && 
      date.day == _selectedDate.day
    );
    
    return Container(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Quick Entry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = date.year == _selectedDate.year && 
                    date.month == _selectedDate.month && 
                    date.day == _selectedDate.day;
                
                final isToday = date.year == today.year && 
                    date.month == today.month && 
                    date.day == today.day;
                
                final isWeekend = date.weekday == DateTime.saturday || 
                    date.weekday == DateTime.sunday;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    
                    // Scroll to the selected date
                    _scrollController.animateTo(
                      index * 65.0 - MediaQuery.of(context).size.width / 2 + 32.5,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 65,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isWeekend
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday && !isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isSelected
                                ? Colors.transparent
                                : Colors.grey.withOpacity(0.3),
                        width: isToday && !isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date)[0], // First letter of day name
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isWeekend
                                    ? Colors.red
                                    : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87,
                          ),
                        ),
                        if (isToday && !isSelected)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoHabitsForDate() {
    final isToday = _selectedDate.year == DateTime.now().year && 
                    _selectedDate.month == DateTime.now().month && 
                    _selectedDate.day == DateTime.now().day;
                    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isToday ? Icons.check_circle : Icons.event_busy,
              size: 48,
              color: isToday ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              isToday 
                ? 'No habits scheduled for today' 
                : 'No habits for ${DateFormat('MMMM d').format(_selectedDate)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              isToday
                ? 'Enjoy your free day or add new habits'
                : _selectedDate.isAfter(DateTime.now())
                    ? 'Plan ahead by adding habits'
                    : 'No habit entries found for this date',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHabitsScreen() {
    if (_filteredHabits.isEmpty) {
      return _buildEmpty();
    }
    
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _filteredHabits.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final habit = _filteredHabits[i];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }

  Widget _buildArchivedList() {
    if (_archivedHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No archived habits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Archived habits will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            TextButton.icon(
              onPressed: _toggleArchiveView,
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Active Habits'),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _archivedHabits.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final habit = _archivedHabits[i];
        return HabitListItem(
          habit: habit,
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))
            );
            _loadHabits();
          },
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_circle_outline, size: 72, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No habits yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Start tracking your habits to build better routines',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddHabit,
          icon: Icon(Icons.add),
          label: Text('Create Habit'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );

  Widget _buildEnhancedQuickEntry(List<Habit> habitsForDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = selectedDay.isAtSameMomentAs(today);
    
    // For past dates, show habits that had entries on that date
    // For today and future dates, show habits based on their frequency
    if (habitsForDate.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                isToday ? Icons.check_circle : Icons.event_busy,
                size: 48,
                color: isToday ? Colors.green : Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                isToday 
                  ? 'No habits scheduled for today' 
                  : 'No habits for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                isToday
                  ? 'Enjoy your free day or add new habits'
                  : _selectedDate.isAfter(now)
                      ? 'Plan ahead by adding habits'
                      : 'No habit entries found for this date',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Count completed habits for the selected date
    final completedHabits = habitsForDate.where((habit) {
      return habit.entries.any((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate.isAtSameMomentAs(selectedDay) && habit.isPositiveDay(entry);
      });
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with progress info
        Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.track_changes, 
                size: 16, 
                color: Theme.of(context).colorScheme.primary
              ),
              SizedBox(width: 6),
              Text(
                '${completedHabits.length}/${habitsForDate.length} completed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Quick entry list
        ...habitsForDate.map((habit) => _buildQuickEntryItem(habit, selectedDay)),
      ],
    );
  }
  
  Widget _buildQuickEntryItem(Habit habit, DateTime selectedDate) {
    // Check if this habit has a positive entry for the selected date
    final isCompleted = habit.entries.any((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDate.isAtSameMomentAs(selectedDate) && habit.isPositiveDay(entry);
    });
    
    // Find the existing entry for the selected date if any
    final existingEntry = habit.entries.firstWhere(
      (entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate.isAtSameMomentAs(selectedDate);
      },
      orElse: () => HabitEntry(date: DateTime.now(), dayNumber: 0, count: 0),
    );
    
    final hasExistingEntry = existingEntry.dayNumber > 0;
    
    // Check if we're looking at today or a different date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.isAtSameMomentAs(today);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => hasExistingEntry ? _editEntryForDate(habit, existingEntry, selectedDate) : _showAddEntryForDate(habit, selectedDate),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Habit icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.color?.withOpacity(0.1) ?? 
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    habit.icon ?? Icons.star,
                    color: habit.color ?? Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // Habit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.schedule,
                          size: 14,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isCompleted 
                              ? 'Completed ${isToday ? "today" : "on this day"}' 
                              : isToday 
                                  ? 'Due today' 
                                  : selectedDate.isAfter(today) 
                                      ? 'Upcoming' 
                                      : 'Missed',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted ? Colors.green : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action button
              if (isCompleted)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.green),
                )
              else
                ElevatedButton(
                  onPressed: () => _showAddEntryForDate(habit, selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: habit.color ?? Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size(0, 40),
                  ),
                  child: Text('Log'),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _editEntryForDate(Habit habit, HabitEntry entry, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: habit,
        dayNumber: entry.dayNumber,
        selectedDate: date,
        onSave: (newEntry) async {
          // Remove the old entry and add the new one
          habit.entries.remove(entry);
          habit.entries.add(newEntry);
          await StorageService.save(habit);
          Navigator.of(context).pop();
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }
  
  void _showAddEntryForDate(Habit habit, DateTime date) {
    // Calculate the day number based on existing entries
    final nextDay = habit.getNextDayNumber();
    
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: habit,
        dayNumber: nextDay,
        selectedDate: date,
        onSave: (entry) async {
          habit.entries.add(entry);
          await StorageService.save(habit);
          Navigator.of(context).pop();
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }

  Widget _buildDashboardSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.checklist,
                  title: 'Total Habits',
                  value: '${_activeHabits.length}',
                  color: Colors.blue,
                ),
                _buildStatCard(
                  icon: Icons.celebration,
                  title: 'Success Rate',
                  value: '${_overallSuccessRate.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Best Streak',
                  value: '$_bestCurrentStreak',
                  color: Colors.orange,
                ),
              ],
            ),
            if (_bestCurrentStreak > 0 && _bestStreakHabit.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current best streak: $_bestCurrentStreak days with "$_bestStreakHabit"',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
