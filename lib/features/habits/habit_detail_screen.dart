// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/main.dart';
import 'package:flutter/material.dart';
import 'package:flux/features/habits/add_entry_dialog.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/features/calendar/calendar_view.dart';
import 'package:flux/features/analytics/analytics_dashboard.dart';
import 'package:flux/core/services/data_service.dart';
import 'package:flux/core/services/reports_service.dart';
import 'package:intl/intl.dart';

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
    _tabController = TabController(length: 5, vsync: this); // Increased to 5 tabs
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
        onSave: (entry) async {
          widget.habit.entries.add(entry);
          await StorageService.save(widget.habit);
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Habit Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.code, color: Colors.blue),
              title: Text('Export as JSON'),
              subtitle: Text('Complete data including all entries and metadata'),
              onTap: () async {
                try {
                  final jsonData = await DataService.exportHabitToJson(widget.habit);
                  final filename = '${widget.habit.name}_export_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
                  await DataService.shareData(jsonData, filename, 'application/json');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Data exported successfully!')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.green),
              title: Text('Generate Report'),
              subtitle: Text('Detailed summary report for this habit'),
              onTap: () async {
                try {
                  final report = await DataService.generateSummaryReport([widget.habit]);
                  final filename = '${widget.habit.name}_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.txt';
                  await DataService.shareData(report, filename, 'text/plain');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report generated successfully!')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report generation failed: $e')),
                  );
                }
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
            if (!widget.habit.isPaused) ListTile(
              leading: Icon(Icons.pause_circle, color: Colors.orange),
              title: Text('Pause Habit'),
              subtitle: Text('Temporarily stop tracking without affecting streaks'),
              onTap: () async {
                widget.habit.isPaused = true;
                widget.habit.pauseStartDate = DateTime.now();
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                _refreshHabit();
              },
            ),
            if (widget.habit.isPaused) ListTile(
              leading: Icon(Icons.play_circle, color: Colors.green),
              title: Text('Resume Habit'),
              subtitle: Text('Continue tracking this habit'),
              onTap: () async {
                widget.habit.isPaused = false;
                widget.habit.pauseEndDate = DateTime.now();
                await StorageService.save(widget.habit);
                Navigator.pop(context);
                _refreshHabit();
              },
            ),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.history), text: 'Entries'),
            Tab(icon: Icon(Icons.assessment), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showDeleteHabitDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCalendarTab(),
          _buildAnalyticsTab(),
          _buildEntriesTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Entry',
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHabitInfoCard(),
          SizedBox(height: 16),
          _buildStatsGrid(),
          SizedBox(height: 16),
          if (widget.habit.type == HabitType.FailBased) _buildTimeSinceLastFailure(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: CalendarView(
        habit: widget.habit,
        onRefresh: _refreshHabit,
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return AnalyticsDashboard(habits: [widget.habit], showBackButton: false,);
  }

  Widget _buildEntriesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entry History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (widget.habit.entries.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No entries yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the + button to add your first entry', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            ..._buildEntriesList(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildReportsCards(),
        ],
      ),
    );
  }

  Widget _buildReportsCards() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    return Column(
      children: [
        // Current month report
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(Icons.calendar_month, color: Colors.blue),
            ),
            title: Text('${DateFormat('MMMM yyyy').format(now)} Report'),
            subtitle: Text('Monthly summary and trends'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final monthReport = ReportsService.generateMonthlyReport([widget.habit], currentYear, currentMonth);
              _showMonthlyReportDialog(monthReport);
            },
          ),
        ),
        SizedBox(height: 8),
        
        // Year in review
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(Icons.auto_awesome, color: Colors.green),
            ),
            title: Text('$currentYear Year in Review'),
            subtitle: Text('Your habit journey this year'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final yearReview = ReportsService.generateYearInReview([widget.habit], currentYear);
              _showYearInReviewDialog(yearReview);
            },
          ),
        ),
        SizedBox(height: 8),
        
        // Weekly report
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Icon(Icons.view_week, color: Colors.orange),
            ),
            title: Text('This Week Report'),
            subtitle: Text('Recent 7-day performance'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              final weekReport = ReportsService.generateWeeklyReport([widget.habit], weekStart);
              _showWeeklyReportDialog(weekReport);
            },
          ),
        ),
      ],
    );
  }

  void _showMonthlyReportDialog(MonthlyReportData report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${report.monthName} ${report.year} Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Entries: ${report.totalEntries}'),
              Text('Average Success Rate: ${report.averageSuccessRate.toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              if (report.trends.isNotEmpty) ...[
                Text('Trends:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...report.trends.map((trend) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${trend.title}: ${trend.description}'),
                )),
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

  void _showYearInReviewDialog(YearInReviewData review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${review.year} Year in Review'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Entries: ${review.totalEntries}'),
              Text('Days Tracked: ${review.totalDaysTracked}'),
              Text('Success Rate: ${review.overallSuccessRate.toStringAsFixed(1)}%'),
              Text('Longest Streak: ${review.longestStreak} days'),
              SizedBox(height: 16),
              if (review.milestones.isNotEmpty) ...[
                Text('Milestones:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...review.milestones.take(3).map((milestone) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${milestone.title} (${DateFormat('MMM d').format(milestone.date)})'),
                )),
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

  void _showWeeklyReportDialog(WeeklyReportData report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weekly Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Period: ${DateFormat('MMM d').format(report.weekStart)} - ${DateFormat('MMM d').format(report.weekEnd)}'),
              Text('Total Entries: ${report.totalEntries}'),
              Text('Average Success Rate: ${report.averageSuccessRate.toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              if (report.bestDay != null) 
                Text('Best Day: ${DateFormat('EEEE').format(report.bestDay!.date)} (${report.bestDay!.successRate.toStringAsFixed(1)}%)'),
              if (report.worstDay != null) 
                Text('Challenging Day: ${DateFormat('EEEE').format(report.worstDay!.date)} (${report.worstDay!.successRate.toStringAsFixed(1)}%)'),
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

  Widget _buildHabitInfoCard() {
    final habit = widget.habit;
    final entries = habit.entries;
    
    final days = entries.length;
    final positiveDays = habit.positiveCount;
    final negativeDays = days - positiveDays;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Type', _getHabitTypeText(habit.type)),
            _buildInfoRow('Frequency', _getFrequencyText(habit)),
            if (habit.category != null)
              _buildInfoRow('Category', habit.category!),
            if (habit.targetValue != null)
              _buildInfoRow('Target', '${habit.targetValue} ${habit.getUnitDisplayName()}'),
            if (habit.isPaused)
              _buildInfoRow('Status', 'Paused', color: Colors.orange),
            if (habit.type == HabitType.FailBased && habit.hasEntries)
              _buildInfoRow('Time Clean', habit.getTimeSinceLastFailure(), color: Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    final habit = widget.habit;
    final entries = habit.entries;
    
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
    
    return Column(
      children: [
        _buildStatItem('Total Days Tracked', days.toString()),
        _buildStatItem('Total Count Sum', '$totalCount'),
        _buildStatItem('Average Count per Day', '${avgPerDay.toStringAsFixed(2)}'),
        if (maxCount > 0)
          _buildStatItem('Highest Count ($maxCount) on Day(s)', maxDays.join(', ')),
      ],
    );
  }
  
  Widget _buildTimeSinceLastFailure() {
    final habit = widget.habit;
    final timeSinceLastFailure = habit.getTimeSinceLastFailure();
    
    return _buildInfoRow('Time Since Last Failure', timeSinceLastFailure, color: Colors.green);
  }
  
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
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
  
  String _getHabitTypeText(HabitType type) {
    switch (type) {
      case HabitType.FailBased:
        return 'Avoid (Failure-based)';
      case HabitType.SuccessBased:
        return 'Achieve (Success-based)';
      case HabitType.DoneBased:
        return 'Check (Done-based)';
    }
  }
  
  String _getFrequencyText(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.Daily:
        return 'Daily';
      case HabitFrequency.Weekdays:
        return 'Weekdays (Mon-Fri)';
      case HabitFrequency.Weekends:
        return 'Weekends (Sat-Sun)';
      case HabitFrequency.CustomDays:
        final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final selectedDays = habit.customDays.map((i) => dayNames[i]).join(', ');
        return 'Custom Days ($selectedDays)';
      case HabitFrequency.XTimesPerWeek:
        return '${habit.targetFrequency ?? 'X'} times per week';
      case HabitFrequency.XTimesPerMonth:
        return '${habit.targetFrequency ?? 'X'} times per month';
    }
  }

  List<Widget> _buildEntriesList() {
    final entries = widget.habit.entries;
    
    // Sort entries by day number in descending order
    final sortedEntries = [...entries]..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    
    return sortedEntries.map((entry) {
      final isPositive = widget.habit.isPositiveDay(entry);
      
      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: entry.isSkipped 
                ? Colors.orange.withOpacity(0.2)
                : isPositive 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.red.withOpacity(0.2),
            foregroundColor: entry.isSkipped 
                ? Colors.orange
                : isPositive 
                    ? Colors.green 
                    : Colors.red,
            child: Icon(entry.isSkipped 
                ? Icons.skip_next
                : isPositive 
                    ? Icons.check 
                    : Icons.close),
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
        ),
      );
    }).toList();
  }

  String _getEntryDescription(HabitEntry entry) {
    if (entry.isSkipped) {
      return 'Skipped day';
    }
    
    String description;
    switch (widget.habit.type) {
      case HabitType.FailBased:
        if (entry.value != null) {
          description = entry.count == 0 
              ? 'Success (0 ${widget.habit.getUnitDisplayName()})' 
              : '${entry.value} ${entry.unit ?? widget.habit.getUnitDisplayName()}';
        } else {
          description = entry.count == 0 
              ? 'Success (0 failures)' 
              : '${entry.count} failure(s)';
        }
        break;
      case HabitType.SuccessBased:
        if (entry.value != null) {
          description = entry.count > 0 
              ? '${entry.value} ${entry.unit ?? widget.habit.getUnitDisplayName()}' 
              : 'Failed (0 ${widget.habit.getUnitDisplayName()})';
        } else {
          description = entry.count > 0 
              ? '${entry.count} success(es)' 
              : 'Failed (0 successes)';
        }
        break;
      case HabitType.DoneBased:
        if (entry.value != null) {
          description = entry.count > 0 
              ? 'Completed (${entry.value} ${entry.unit ?? widget.habit.getUnitDisplayName()})' 
              : 'Not completed';
        } else {
          description = entry.count > 0 ? 'Completed' : 'Not completed';
        }
        break;
    }
    
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      description += '\nNote: ${entry.notes}';
    }
    
    return description;
  }
}