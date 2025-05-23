// lib/main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsService {
  static const String THEME_KEY = 'theme_mode';
  static const String DEFAULT_HABIT_TYPE_KEY = 'default_habit_type';
  static const String DEFAULT_DISPLAY_MODE_KEY = 'default_display_mode';
  
  // Theme settings
  static Future<bool> setDarkMode(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(THEME_KEY, isDark);
  }
  
  static Future<bool> isDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_KEY) ?? true; // Default to dark mode
  }
  
  // Default habit type
  static Future<bool> setDefaultHabitType(HabitType type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_HABIT_TYPE_KEY, type.index);
  }
  
  static Future<HabitType> getDefaultHabitType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_HABIT_TYPE_KEY) ?? HabitType.SuccessBased.index;
    return HabitType.values[index];
  }
  
  // Default display mode
  static Future<bool> setDefaultDisplayMode(ReportDisplay mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_DISPLAY_MODE_KEY, mode.index);
  }
  
  static Future<ReportDisplay> getDefaultDisplayMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_DISPLAY_MODE_KEY) ?? ReportDisplay.Rate.index;
    return ReportDisplay.values[index];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDarkMode = await SettingsService.isDarkMode();
  runApp(HabitTrackerApp(isDarkMode: isDarkMode));
}

class HabitTrackerApp extends StatefulWidget {
  final bool isDarkMode;
  HabitTrackerApp({required this.isDarkMode});

  @override
  _HabitTrackerAppState createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late bool _isDarkMode;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }
  
  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      SettingsService.setDarkMode(_isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1DB954),
          brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1DB954).withOpacity(0.3),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1DB954), width: 2),
          ),
        ),
      ),
      home: HomeScreen(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  HomeScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Habit> _habits = [];
  List<Habit> _activeHabits = [];
  List<Habit> _archivedHabits = [];
  late TabController _tabController;
  bool _isLoading = true;
  int _totalPositiveDays = 0;
  int _totalNegativeDays = 0;
  double _overallSuccessRate = 0;
  int _totalEntries = 0;
  int _bestCurrentStreak = 0;
  String _bestStreakHabit = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHabits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final all = await StorageService.loadAll();
    
    // Filter active and archived habits
    final active = all.where((h) => !h.isArchived).toList();
    final archived = all.where((h) => h.isArchived).toList();
    
    // Calculate overall metrics (using active habits only)
    int totalPositive = 0;
    int totalNegative = 0;
    int totalEntries = 0;
    int bestStreak = 0;
    String bestStreakHabit = '';
    
    for (var habit in active) {
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
      _totalPositiveDays = totalPositive;
      _totalNegativeDays = totalNegative;
      _totalEntries = totalEntries;
      
      int totalDays = totalPositive + totalNegative;
      _overallSuccessRate = totalDays > 0 ? (totalPositive / totalDays) * 100 : 0;
      
      _bestCurrentStreak = bestStreak;
      _bestStreakHabit = bestStreakHabit;
      _isLoading = false;
    });
  }

  void _showAddHabit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(onSave: (h) async {
        if (h.name.isEmpty) return;
        await StorageService.save(h);
        Navigator.pop(context);
        _loadHabits();
      }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showArchived ? 'Archived Habits' : 'Flux', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inventory_2_outlined : Icons.archive),
            onPressed: _toggleArchiveView,
            tooltip: _showArchived ? 'Show Active Habits' : 'Show Archived',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: !_showArchived ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Habits'),
            Tab(text: 'Dashboard'),
          ],
        ) : null,
      ),
      floatingActionButton: !_showArchived ? FloatingActionButton(
        onPressed: _showAddHabit,
        child: Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showArchived 
              ? _buildArchivedList()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _activeHabits.isEmpty ? _buildEmpty() : _buildHabitsList(_activeHabits),
                    _buildDashboard(),
                  ],
                ),
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

  Widget _buildHabitsList(List<Habit> habits) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: habits.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (_, i) {
        final habit = habits[i];
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
  
  Widget _buildDashboard() {
    if (_habits.isEmpty) {
      return Center(
        child: Text(
          'Add habits to see your statistics',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overall Progress'),
          SizedBox(height: 12),
          _buildMetricsCards(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Success Rate by Habit'),
          SizedBox(height: 12),
          _buildSuccessRateChart(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Habit Streaks'),
          SizedBox(height: 12),
          _buildStreaksList(),
          SizedBox(height: 24),
          
          _buildSectionTitle('Recent Entries'),
          SizedBox(height: 12),
          _buildRecentEntries(),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  Widget _buildMetricsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Success Rate',
                value: '${_overallSuccessRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Entries',
                value: '$_totalEntries',
                icon: Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Positive Days',
                value: '$_totalPositiveDays',
                icon: Icons.thumb_up_alt_outlined,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Negative Days',
                value: '$_totalNegativeDays',
                icon: Icons.thumb_down_alt_outlined,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_bestCurrentStreak > 0)
          _buildMetricCard(
            title: 'Best Current Streak',
            value: '$_bestCurrentStreak days - $_bestStreakHabit',
            icon: Icons.local_fire_department,
            color: Colors.orange,
            isWide: true,
          ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isWide ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessRateChart() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    return Container(
      height: 220,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() < _habits.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _habits[value.toInt()].name.length > 6
                                ? _habits[value.toInt()].name.substring(0, 6) + '...'
                                : _habits[value.toInt()].name,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              barGroups: List.generate(_habits.length, (index) {
                final habit = _habits[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: habit.successRate,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStreaksList() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    // Sort habits by current streak
    final sortedHabits = [..._habits]..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    
    return Card(
      elevation: 2, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: sortedHabits.length > 5 ? 5 : sortedHabits.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final habit = sortedHabits[index];
          return Row(
            children: [
              Icon(
                habit.icon ?? Icons.star,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: habit.currentStreak > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${habit.currentStreak} days',
                  style: TextStyle(
                    color: habit.currentStreak > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildRecentEntries() {
    if (_habits.isEmpty) {
      return SizedBox();
    }
    
    // Collect all entries from all habits
    List<MapEntry<Habit, HabitEntry>> allEntries = [];
    
    for (var habit in _habits) {
      for (var entry in habit.entries) {
        allEntries.add(MapEntry(habit, entry));
      }
    }
    
    // Sort by date (newest first)
    allEntries.sort((a, b) => b.value.date.compareTo(a.value.date));
    
    // Take only the 5 most recent
    final recentEntries = allEntries.take(5).toList();
    
    if (recentEntries.isEmpty) {
      return Center(child: Text('No entries yet'));
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: recentEntries.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final habit = recentEntries[index].key;
          final entry = recentEntries[index].value;
          final isPositive = habit.isPositiveDay(entry);
          
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPositive 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.check : Icons.close,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(entry.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                'Day ${entry.dayNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HabitListItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  
  const HabitListItem({required this.habit, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: habit.color?.withOpacity(0.1) ?? 
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  habit.icon ?? Icons.star,
                  color: habit.color ?? Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.formattedName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        habit.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      _getHabitStatusText(habit),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${habit.successRate.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: habit.color ?? Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak} day streak',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getHabitStatusText(Habit habit) {
    switch (habit.type) {
      case HabitType.FailBased:
        return 'Failures: ${habit.entries.fold(0, (sum, e) => sum + e.count)}';
      case HabitType.SuccessBased:
        return 'Successes: ${habit.entries.fold(0, (sum, e) => sum + e.count)}';
      case HabitType.DoneBased:
        return 'Completed ${habit.entries.fold(0, (sum, e) => sum + e.count)} time(s)';
    }
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  
  SettingsScreen({required this.toggleTheme, required this.isDarkMode});
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HabitType _defaultHabitType;
  late ReportDisplay _defaultDisplayMode;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _defaultHabitType = await SettingsService.getDefaultHabitType();
    _defaultDisplayMode = await SettingsService.getDefaultDisplayMode();
    setState(() => _loading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildSection('Theme'),
                SwitchListTile(
                  title: Text('Dark Mode'),
                  subtitle: Text('Toggle dark/light theme'),
                  value: widget.isDarkMode,
                  onChanged: (_) => widget.toggleTheme(),
                  secondary: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                ),
                Divider(),
                _buildSection('Default Settings'),
                ListTile(
                  title: Text('Default Habit Type'),
                  subtitle: Text(_defaultHabitType.toString().split('.').last),
                  leading: Icon(Icons.category),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showHabitTypeSelector,
                ),
                ListTile(
                  title: Text('Default Display Mode'),
                  subtitle: Text(_defaultDisplayMode.toString().split('.').last),
                  leading: Icon(Icons.bar_chart),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showDisplayModeSelector,
                ),
                Divider(),
                _buildSection('About'),
                ListTile(
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                  leading: Icon(Icons.info_outline),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  void _showHabitTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Habit Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitType.values.map((type) {
            return RadioListTile<HabitType>(
              title: Text(type.toString().split('.').last),
              value: type,
              groupValue: _defaultHabitType,
              onChanged: (HabitType? value) {
                if (value != null) {
                  setState(() => _defaultHabitType = value);
                  SettingsService.setDefaultHabitType(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showDisplayModeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Display Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReportDisplay.values.map((mode) {
            return RadioListTile<ReportDisplay>(
              title: Text(mode.toString().split('.').last),
              value: mode,
              groupValue: _defaultDisplayMode,
              onChanged: (ReportDisplay? value) {
                if (value != null) {
                  setState(() => _defaultDisplayMode = value);
                  SettingsService.setDefaultDisplayMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// Add Habit Bottom Sheet
class AddHabitSheet extends StatefulWidget {
  final Function(Habit) onSave;
  AddHabitSheet({required this.onSave});
  @override _AddHabitSheetState createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  HabitType _type = HabitType.DoneBased;
  IconData _icon = Icons.star;
  Color _color = Color(0xFF1DB954); // Default green color
  final _icons = [
    Icons.star, Icons.fitness_center, Icons.book, Icons.brush, 
    Icons.run_circle, Icons.water_drop, Icons.food_bank, Icons.bed,
    Icons.emoji_emotions, Icons.self_improvement, Icons.music_note, 
    Icons.code, Icons.sports_basketball, Icons.smoking_rooms, 
    Icons.local_drink, Icons.monitor, Icons.health_and_safety,
    Icons.directions_run, Icons.dark_mode, Icons.light_mode,
    Icons.pets, Icons.nature, Icons.volunteer_activism, Icons.school,
    Icons.alarm, Icons.piano, Icons.savings, Icons.attach_money
  ];
  
  final List<Color> _colorOptions = [
    Color(0xFF1DB954), // Green (default)
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red 
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue-Grey
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF4CAF50), // Light Green
    Color(0xFF673AB7), // Deep Purple
    Color(0xFFFF5722), // Deep Orange
  ];
  
  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }
  
  Future<void> _loadDefaults() async {
    _type = await SettingsService.getDefaultHabitType();
    setState(() {});
  }

  @override Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Create New Habit', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            _buildTextField(),
            SizedBox(height: 16),
            _buildNotesField(),
            SizedBox(height: 24),
            Text(
              'Habit Type', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            _buildHabitTypeSelector(),
            SizedBox(height: 24),
            Text(
              'Icon', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            _buildIconSelector(),
            SizedBox(height: 24),
            Text(
              'Color', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            _buildColorSelector(),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Create Habit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        hintText: 'Habit name',
        labelText: 'Name',
        prefixIcon: Icon(Icons.edit),
        filled: true,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 16),
    );
  }
  
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesCtrl,
      decoration: InputDecoration(
        hintText: 'Optional description or notes',
        labelText: 'Notes',
        prefixIcon: Icon(Icons.note),
        filled: true,
      ),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 14),
      maxLines: 2,
      onFieldSubmitted: (_) => _createHabit(),
    );
  }
  
  Widget _buildHabitTypeSelector() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: HabitType.values.map((type) {
          final isSelected = _type == type;
          final text = type.toString().split('.').last;
          String typeLabel;
          
          switch (type) {
            case HabitType.FailBased:
              typeLabel = 'Avoid';
              break;
            case HabitType.SuccessBased:
              typeLabel = 'Achieve';
              break;
            case HabitType.DoneBased:
              typeLabel = 'Check';
              break;
          }
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = type),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildIconSelector() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = _icon == icon;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _icon = icon),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2) 
                    : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildColorSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          final isSelected = _color.value == color.value;
          
          return GestureDetector(
            onTap: () => setState(() => _color = color),
            child: Container(
              width: 48,
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: isSelected ? 8 : 0,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: isSelected 
                ? Icon(Icons.check, color: Colors.white)
                : null,
            ),
          );
        },
      ),
    );
  }
  
  void _createHabit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    
    widget.onSave(Habit(
      name: name,
      type: _type,
      icon: _icon,
      color: _color,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    ));
  }
}

// Detail, Models & Storage
class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  HabitDetailScreen({required this.habit});
  
  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _refreshHabit() {
    setState(() {});
  }
  
  void _showAddEntryDialog() {
    final nextDay = widget.habit.getNextDayNumber();
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: widget.habit,
        dayNumber: nextDay,
        onSave: (count) async {
          await StorageService.addEntry(widget.habit, count);
          Navigator.of(context).pop();
          _refreshHabit();
        },
      ),
    );
  }
  
  void _showToggleDisplayModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Display Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReportDisplay.values.map((mode) {
            return RadioListTile<ReportDisplay>(
              title: Text(mode.toString().split('.').last),
              value: mode,
              groupValue: widget.habit.displayMode,
              onChanged: (value) async {
                if (value != null) {
                  widget.habit.displayMode = value;
                  await StorageService.save(widget.habit);
                  Navigator.pop(context);
                  _refreshHabit();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do with "${widget.habit.formattedName}"?'),
            SizedBox(height: 16),
            if (!widget.habit.isArchived) ListTile(
              leading: Icon(Icons.archive, color: Colors.amber),
              title: Text('Archive Habit'),
              subtitle: Text('Hide it from the main list but keep the data'),
              onTap: () async {
                widget.habit.isArchived = true;
                await StorageService.save(widget.habit);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
            ),
            if (widget.habit.isArchived) ListTile(
              leading: Icon(Icons.unarchive, color: Colors.green),
              title: Text('Restore Habit'),
              subtitle: Text('Bring it back to the active list'),
              onTap: () async {
                widget.habit.isArchived = false;
                await StorageService.save(widget.habit);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Delete Permanently'),
              subtitle: Text('This cannot be undone'),
              onTap: () {
                _confirmDelete();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete "${widget.habit.formattedName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await StorageService.delete(widget.habit);
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close manage dialog
              Navigator.pop(context); // Go back to home
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.formattedName),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _showToggleDisplayModeDialog,
            tooltip: 'Change display mode',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteHabitDialog,
            tooltip: 'Delete habit',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Report'),
            Tab(text: 'Entries'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: Icon(Icons.add),
        tooltip: 'Add entry',
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildReportTab(),
          _buildEntriesTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    final habit = widget.habit;
    final entries = habit.entries;
    
    final days = entries.length;
    final positiveDays = habit.positiveCount;
    final negativeDays = days - positiveDays;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            title: 'Current Status',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Days', days.toString()),
                    _buildStatItem('Success Rate', '${habit.successRate.toStringAsFixed(1)}%'),
                    _buildStatItem('Current Streak', '${habit.currentStreak}'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          if (days > 0) ...[
            // _buildStatCard(
            //   title: 'Progress',
            //   child: SizedBox(
            //     height: 200,
            //     child: BarChart(
            //       BarChartData(
            //         alignment: BarChartAlignment.spaceAround,
            //         maxY: 100,
            //         titlesData: FlTitlesData(
            //           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            //           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            //           bottomTitles: AxisTitles(
            //             sideTitles: SideTitles(
            //               showTitles: false,
            //             ),
            //           ),
            //           leftTitles: AxisTitles(
            //             sideTitles: SideTitles(
            //               showTitles: true,
            //               getTitlesWidget: (value, meta) {
            //                 return Text(
            //                   '${value.toInt()}%',
            //                   style: TextStyle(fontSize: 10),
            //                 );
            //               },
            //               reservedSize: 30,
            //             ),
            //           ),
            //         ),
            //       ),
            //       borderData: FlBorderData(show: false),
            //       barGroups: [
            //         BarChartGroupData(
            //           x: 0,
            //           barRods: [
            //             BarChartRodData(
            //               toY: positiveDays.toDouble(),
            //               color: Colors.green,
            //               width: 22,
            //               borderRadius: BorderRadius.only(
            //                 topLeft: Radius.circular(6),
            //                 topRight: Radius.circular(6),
            //               ),
            //             ),
            //           ],
            //         ),
            //         BarChartGroupData(
            //           x: 1,
            //           barRods: [
            //             BarChartRodData(
            //               toY: negativeDays.toDouble(),
            //               color: Colors.red.shade300,
            //               width: 22,
            //               borderRadius: BorderRadius.only(
            //                 topLeft: Radius.circular(6),
            //                 topRight: Radius.circular(6),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Positive Days',
                    child: Center(
                      child: Text(
                        '$positiveDays',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Negative Days',
                    child: Center(
                      child: Text(
                        '$negativeDays',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Add your first entry to see statistics',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportTab() {
    final habit = widget.habit;
    final entries = habit.entries;
    
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet'),
      );
    }
    
    final days = entries.length;
    final totalCount = entries.fold(0, (sum, e) => sum + e.count);
    final positiveDays = habit.positiveCount;
    final negativeDays = days - positiveDays;
    final posRate = days > 0 ? (positiveDays / days) * 100 : 0;
    final negRate = days > 0 ? (negativeDays / days) * 100 : 0;
    
    final avgPerDay = days > 0 ? totalCount / days : 0;
    final avgPositive = positiveDays > 0
        ? entries
            .where((e) => habit.isPositiveDay(e))
            .fold(0, (sum, e) => sum + e.count) / positiveDays
        : 0;
    
    final maxCount = entries.isEmpty ? 0 : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final maxDays = entries.where((e) => e.count == maxCount).map((e) => e.dayNumber).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: 'Detailed Report',
            items: [
              DetailItem(label: 'Total Days Tracked', value: '$days'),
              DetailItem(label: 'Total Count Sum', value: '$totalCount'),
              DetailItem(label: 'Average Count per Day', value: '${avgPerDay.toStringAsFixed(2)}'),
              if (maxCount > 0)
                DetailItem(
                  label: 'Highest Count ($maxCount) on Day(s)',
                  value: maxDays.join(', '),
                ),
            ],
          ),
          SizedBox(height: 16),
          _buildDetailSection(
            title: 'Success Metrics',
            items: [
              DetailItem(label: 'Positive Days', value: '$positiveDays (${posRate.toStringAsFixed(2)}%)'),
              DetailItem(label: 'Negative Days', value: '$negativeDays (${negRate.toStringAsFixed(2)}%)'),
              DetailItem(label: 'Average on Positive Days', value: '${avgPositive.toStringAsFixed(2)}'),
            ],
          ),
          SizedBox(height: 16),
          _buildDetailSection(
            title: 'Streak Information',
            items: [
              DetailItem(label: 'Current Positive Streak', value: '${habit.currentStreak} days'),
              DetailItem(label: 'Best Positive Streak', value: '${habit.bestStreak} days'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection({required String title, required List<DetailItem> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Divider(height: 24),
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEntriesTab() {
    final entries = widget.habit.entries;
    
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet'),
      );
    }
    
    // Sort entries by day number in descending order
    final sortedEntries = [...entries]..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final isPositive = widget.habit.isPositiveDay(entry);
        
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            foregroundColor: isPositive ? Colors.green : Colors.red,
            child: Icon(isPositive ? Icons.check : Icons.close),
          ),
          title: Text(
            'Day ${entry.dayNumber}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(entry.date),
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(_getEntryDescription(entry)),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Entry'),
                  content: Text('Are you sure you want to delete this entry?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await StorageService.deleteEntry(widget.habit, entry);
                _refreshHabit();
              }
            },
          ),
        );
      },
    );
  }
  
  String _getEntryDescription(HabitEntry entry) {
    switch (widget.habit.type) {
      case HabitType.FailBased:
        return entry.count == 0 
            ? 'Success (0 failures)' 
            : '${entry.count} failure(s)';
      case HabitType.SuccessBased:
        return entry.count > 0 
            ? '${entry.count} success(es)' 
            : 'Failed (0 successes)';
      case HabitType.DoneBased:
        return entry.count > 0 ? 'Completed' : 'Not completed';
    }
  }
}

class DetailItem {
  final String label;
  final String value;
  
  DetailItem({required this.label, required this.value});
}

enum HabitType { FailBased, SuccessBased, DoneBased }
enum ReportDisplay { Rate, Streak }

class HabitEntry {
  DateTime date;
  int dayNumber;
  int count;
  
  HabitEntry({required this.date, required this.count, required this.dayNumber});
  
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'dayNumber': dayNumber,
      };
      
  static HabitEntry fromJson(Map<String, dynamic> json) => HabitEntry(
        date: DateTime.parse(json['date']),
        count: json['count'],
        dayNumber: json['dayNumber'] ?? 0,
      );
}

class Habit {
  String name;
  HabitType type;
  ReportDisplay displayMode;
  IconData? icon;
  List<HabitEntry> entries;
  Color? color;
  bool isArchived;
  String? notes;
  int reminderHour;
  int reminderMinute;
  bool hasReminder;
  
  Habit({
    required this.name, 
    this.type = HabitType.SuccessBased,
    this.displayMode = ReportDisplay.Rate, 
    this.icon, 
    this.color,
    this.isArchived = false,
    this.notes,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.hasReminder = false,
    List<HabitEntry>? entries
  }) : entries = entries ?? [];
  
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.index,
        'displayMode': displayMode.index,
        'icon': icon?.codePoint,
        'color': color?.value,
        'isArchived': isArchived,
        'notes': notes,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'hasReminder': hasReminder,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
      
  static Habit fromJson(Map<String, dynamic> json) => Habit(
        name: json['name'],
        type: HabitType.values[json['type'] ?? 1],
        displayMode: ReportDisplay.values[json['displayMode'] ?? 0],
        icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
        color: json['color'] != null ? Color(json['color']) : null,
        isArchived: json['isArchived'] ?? false,
        notes: json['notes'],
        reminderHour: json['reminderHour'] ?? 20,
        reminderMinute: json['reminderMinute'] ?? 0,
        hasReminder: json['hasReminder'] ?? false,
        entries: (json['entries'] as List?)
            ?.map((e) => HabitEntry.fromJson(e))
            .toList() ?? [],
      );
      
  int getNextDayNumber() {
    return entries.isEmpty ? 1 : entries.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
  }
  
  bool isPositiveDay(HabitEntry entry) {
    switch (type) {
      case HabitType.FailBased:
        return entry.count == 0;
      case HabitType.SuccessBased:
      case HabitType.DoneBased:
        return entry.count > 0;
    }
  }
  
  int get positiveCount => entries.where((e) => isPositiveDay(e)).length;
  int get negativeCount => entries.length - positiveCount;
  double get successRate => entries.isEmpty ? 0 : (positiveCount / entries.length) * 100;
  
  // Calculate streaks
  int get currentStreak {
    int streak = 0;
    if (entries.isEmpty) return 0;
    
    var sortedEntries = [...entries]..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  int get bestStreak {
    if (entries.isEmpty) return 0;
    
    int currentBest = 0;
    int current = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    
    for (var entry in sortedEntries) {
      if (isPositiveDay(entry)) {
        current++;
        if (current > currentBest) {
          currentBest = current;
        }
      } else {
        current = 0;
      }
    }
    
    return currentBest;
  }
  
  // Add extra utility methods
  
  String get formattedName {
    return formatPascalCase(name);
  }
  
  bool get hasEntries => entries.isNotEmpty;
  
  // Negative streak
  int get longestNegativeStreak {
    if (entries.isEmpty) return 0;
    
    int currentNegative = 0;
    int maxNegative = 0;
    
    var sortedEntries = [...entries]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    
    for (var entry in sortedEntries) {
      if (!isPositiveDay(entry)) {
        currentNegative++;
        if (currentNegative > maxNegative) {
          maxNegative = currentNegative;
        }
      } else {
        currentNegative = 0;
      }
    }
    
    return maxNegative;
  }
}

// Add a global utility function to format PascalCase or camelCase to spaced text
String formatPascalCase(String text) {
  if (text.isEmpty) return text;
  
  // Handle case where the text is already formatted with spaces
  if (text.contains(' ')) return text;
  
  // Add a space before each capital letter, but not the first one
  final formattedText = text.replaceAllMapped(
    RegExp(r'(?<=[a-z])[A-Z]'),
    (match) => ' ${match.group(0)}',
  );
  
  // Capitalize the first letter
  if (formattedText.isNotEmpty) {
    return formattedText[0].toUpperCase() + formattedText.substring(1);
  }
  
  return formattedText;
}

class StorageService {
  static Future<Directory> _dataDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final data = Directory('${dir.path}/habits');
    if (!await data.exists()) await data.create();
    return data;
  }

  static Future<List<Habit>> loadAll() async {
    final dir = await _dataDir();
    try {
      final files = dir.listSync();
      return files
          .whereType<File>()
          .map((f) => Habit.fromJson(jsonDecode(f.readAsStringSync())))
          .toList();
    } catch (e) {
      print('Error loading habits: $e');
      return [];
    }
  }

  static Future<void> save(Habit habit) async {
    final dir = await _dataDir();
    final file = File('${dir.path}/${habit.name}.json');
    await file.writeAsString(jsonEncode(habit.toJson()));
  }

  static Future<void> delete(Habit habit) async {
    final dir = await _dataDir();
    final file = File('${dir.path}/${habit.name}.json');
    if (await file.exists()) await file.delete();
  }
  
  static Future<void> addEntry(Habit habit, int count) async {
    final nextDayNumber = habit.getNextDayNumber();
    habit.entries.add(HabitEntry(
      date: DateTime.now(),
      count: count,
      dayNumber: nextDayNumber,
    ));
    await save(habit);
  }
  
  static Future<void> updateEntry(Habit habit, HabitEntry entry, int count) async {
    final index = habit.entries.indexWhere((e) => e.dayNumber == entry.dayNumber);
    if (index != -1) {
      habit.entries[index].count = count;
      await save(habit);
    }
  }
  
  static Future<void> deleteEntry(Habit habit, HabitEntry entry) async {
    habit.entries.removeWhere((e) => e.dayNumber == entry.dayNumber);
    await save(habit);
  }
}

class AddEntryDialog extends StatefulWidget {
  final Habit habit;
  final int dayNumber;
  final Function(int) onSave;

  const AddEntryDialog({
    required this.habit,
    required this.dayNumber,
    required this.onSave,
  });

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final TextEditingController _countController = TextEditingController();
  bool _isDone = false;
  int _sliderValue = 0;
  
  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  String get _getEntryTypeText {
    switch (widget.habit.type) {
      case HabitType.FailBased:
        return 'Failure Count';
      case HabitType.SuccessBased:
        return 'Success Count';
      case HabitType.DoneBased:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.habit.icon ?? Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Entry for ${widget.habit.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Day ${widget.dayNumber}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Text(
              _getEntryTypeText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            if (widget.habit.type == HabitType.DoneBased) ...[
              _buildDoneTypeInput(),
            ] else ...[
              _buildCountTypeInput(),
            ],
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Entry',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDoneTypeInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Did you complete this habit today?',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Switch(
                value: _isDone,
                onChanged: (value) {
                  setState(() {
                    _isDone = value;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isDone 
                ? Colors.green.withOpacity(0.2) 
                : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _isDone ? 'Completed ✓' : 'Not Completed ✗',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDone ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCountTypeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter count',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(
                    widget.habit.type == HabitType.FailBased
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    int? count = int.tryParse(value);
                    if (count != null) {
                      setState(() {
                        _sliderValue = count.clamp(0, 20);
                      });
                    }
                  }
                },
              ),
              SizedBox(height: 16),
              Text(
                'Or use slider:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Slider(
                value: _sliderValue.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: _sliderValue.toString(),
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value.round();
                    _countController.text = _sliderValue.toString();
                  });
                },
              ),
              Text(
                widget.habit.type == HabitType.FailBased
                    ? 'Count: $_sliderValue (0 means success)'
                    : 'Count: $_sliderValue (0 means failure)',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _saveEntry() {
    int count;
    
    if (widget.habit.type == HabitType.DoneBased) {
      count = _isDone ? 1 : 0;
    } else {
      if (_countController.text.isEmpty) {
        count = _sliderValue;
      } else {
        count = int.tryParse(_countController.text) ?? _sliderValue;
      }
    }
    
    widget.onSave(count);
  }
}
