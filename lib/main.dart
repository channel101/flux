// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flux/habit.dart';
import 'package:flux/home_screen.dart';
import 'package:flux/settings_service.dart';
import 'package:flux/notification_service.dart';
import 'package:flux/widget_service.dart';
import 'package:flux/theme_service.dart';
import 'package:flux/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await NotificationService.initialize();
  await WidgetService.initialize();
  
  // Check if first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;
  
  // Load theme settings
  final isDarkMode = await SettingsService.isDarkMode();
  final selectedTheme = await ThemeService.getCurrentTheme();
  
  runApp(HabitTrackerApp(
    isDarkMode: isDarkMode,
    selectedTheme: selectedTheme,
    isFirstLaunch: isFirstLaunch,
  ));
}

class HabitTrackerApp extends StatefulWidget {
  final bool isDarkMode;
  final String selectedTheme;
  final bool isFirstLaunch;
  
  HabitTrackerApp({
    required this.isDarkMode,
    required this.selectedTheme,
    required this.isFirstLaunch,
  });

  @override
  _HabitTrackerAppState createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late bool _isDarkMode;
  late String _selectedTheme;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _selectedTheme = widget.selectedTheme;
  }
  
  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      SettingsService.setDarkMode(_isDarkMode);
    });
  }

  void changeTheme(String themeName) {
    setState(() {
      _selectedTheme = themeName;
      ThemeService.setCurrentTheme(themeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeService.createTheme(
      themeName: _selectedTheme,
      isDarkMode: false,
    );
    final darkTheme = ThemeService.createTheme(
      themeName: _selectedTheme,
      isDarkMode: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: widget.isFirstLaunch 
          ? OnboardingScreen(
              onComplete: (themePreference) {
                if (themePreference != null) {
                  changeTheme(themePreference);
                }
                _completeOnboarding();
              },
            )
          : HomeScreen(
              toggleTheme: toggleTheme,
              isDarkMode: _isDarkMode,
              changeTheme: changeTheme,
            ),
    );
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    
    setState(() {
      // Navigate to main app
    });
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          toggleTheme: toggleTheme,
          isDarkMode: _isDarkMode,
          changeTheme: changeTheme,
        ),
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDisplaySettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildBasicCard(context);
        }
        
        final settings = snapshot.data!;
        return _buildConfigurableCard(context, settings);
      },
    );
  }
  
  Future<Map<String, dynamic>> _getDisplaySettings() async {
    return {
      'showIcons': await SettingsService.getShowHabitIcons(),
      'showSuccessRate': await SettingsService.getShowSuccessRate(),
      'showCurrentStreak': await SettingsService.getShowCurrentStreak(),
      'compactMode': await SettingsService.getCompactMode(),
    };
  }
  
  Widget _buildBasicCard(BuildContext context) {
    return _buildConfigurableCard(context, {
      'showIcons': true,
      'showSuccessRate': true,
      'showCurrentStreak': true,
      'compactMode': false,
    });
  }
  
  Widget _buildConfigurableCard(BuildContext context, Map<String, dynamic> settings) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400 || settings['compactMode'] == true;
    final showIcons = settings['showIcons'] == true;
    final showSuccessRate = settings['showSuccessRate'] == true;
    final showCurrentStreak = settings['showCurrentStreak'] == true;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  if (showIcons) ...[
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6 : 12),
                      decoration: BoxDecoration(
                        color: habit.color?.withOpacity(0.1) ?? 
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        habit.icon ?? Icons.star,
                        color: habit.color ?? Theme.of(context).colorScheme.primary,
                        size: isCompact ? 20 : 28,
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.formattedName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 13 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (habit.isDueToday()) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 6 : 8, 
                                  vertical: isCompact ? 2 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Due',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 9 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (habit.category != null) ...[
                          SizedBox(height: 2),
                          Text(
                            habit.category!,
                            style: TextStyle(
                              fontSize: isCompact ? 9 : 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (habit.type == HabitType.FailBased && habit.hasEntries) ...[
                        Text(
                          habit.getTimeSinceLastFailure(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: habit.color ?? Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 13 : 16,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ] else if (showSuccessRate) ...[
                        Text(
                          '${habit.successRate.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: habit.color ?? Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 14 : 20,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                      if (showCurrentStreak) ...[
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up, 
                              size: isCompact ? 10 : 14, 
                              color: Colors.grey
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${habit.currentStreak} day${habit.currentStreak != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isCompact ? 9 : 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    habit.notes!,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12, 
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (!isCompact) ...[
                SizedBox(height: 8),
                Text(
                  _getHabitStatusText(habit),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _getHabitStatusText(Habit habit) {
    switch (habit.type) {
      case HabitType.FailBased:
        final total = habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
        return 'Failures: ${total.toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.SuccessBased:
        final total = habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble()));
        return 'Successes: ${total.toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.DoneBased:
        final total = habit.entries.fold(0, (sum, e) => sum + e.count);
        return 'Completed $total time${total != 1 ? 's' : ''}';
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

// New enums for enhanced features
enum HabitFrequency { 
  Daily, 
  Weekdays, 
  Weekends, 
  CustomDays, 
  XTimesPerWeek, 
  XTimesPerMonth 
}

enum HabitUnit {
  Count,
  Minutes,
  Hours,
  Pages,
  Kilometers,
  Miles,
  Grams,
  Pounds,
  Dollars,
  Custom
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
