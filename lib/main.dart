// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flux/habit.dart';
import 'package:flux/home_screen.dart';
import 'package:flux/settings_service.dart';

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.formattedName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (habit.isDueToday()) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Due',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                  if (habit.type == HabitType.FailBased && habit.hasEntries) ...[
                    Text(
                      habit.getTimeSinceLastFailure(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: habit.color ?? Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${habit.successRate.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: habit.color ?? Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
        return 'Failures: ${habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble())).toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.SuccessBased:
        return 'Successes: ${habit.entries.fold(0.0, (sum, e) => sum + (e.value ?? e.count.toDouble())).toStringAsFixed(1)} ${habit.getUnitDisplayName()}';
      case HabitType.DoneBased:
        return 'Completed ${habit.entries.fold(0, (sum, e) => sum + e.count)} time(s)';
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
