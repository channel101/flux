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
  final GlobalKey<State<CalendarView>> _calendarViewKey = GlobalKey<State<CalendarView>>();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5 tabs
    
    // Listen for tab changes to handle scrolling when calendar tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 1) { // Calendar tab
        _scrollToActiveDay();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _refreshHabit() {
    setState(() {});
  }
  
  void _showAddEntryDialog({DateTime? selectedDate, HabitEntry? existingEntry}) {
    final nextDay = widget.habit.getNextDayNumber();
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: widget.habit,
        dayNumber: existingEntry?.dayNumber ?? nextDay,
        selectedDate: selectedDate,
        onSave: (entry) async {
          if (existingEntry != null) {
            // Remove existing entry and add the updated one
            widget.habit.entries.remove(existingEntry);
          }
          widget.habit.entries.add(entry);
          await StorageService.save(widget.habit);
          Navigator.of(context).pop();
          _refreshHabit();
        },
      ),
    );
  }
  
  void _editEntry(HabitEntry entry) {
    _showAddEntryDialog(selectedDate: entry.date, existingEntry: entry);
  }
  
  void _scrollToActiveDay() {
    // First ensure we're on the right tab
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
      // We need to wait for the tab to change before scrolling
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollCalendarToSelectedDate();
      });
    } else {
      _scrollCalendarToSelectedDate();
    }
  }
  
  void _scrollCalendarToSelectedDate() {
    // Find the CalendarView widget using the key
    final calendarWidget = _calendarViewKey.currentWidget as CalendarView?;
    if (calendarWidget != null) {
      // Call the public method on the widget
      calendarWidget.scrollToSelectedDate();
    }
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
    final habitColor = widget.habit.color ?? Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.formattedName),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: 'Go to Today',
            onPressed: () {
              // Navigate to today's date in the calendar
              _navigateToDate(DateTime.now());
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Entry',
            onPressed: _showAddEntryDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // Edit habit functionality
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'display_mode':
                  _showToggleDisplayModeDialog();
                  break;
                case 'manage':
                  _showDeleteHabitDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Habit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.ios_share, size: 18),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'display_mode',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Change Display Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Manage Habit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              labelColor: habitColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: habitColor,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Calendar'),
                Tab(text: 'Dashboard'),
                Tab(text: 'History'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCalendarTab(),
                AnalyticsDashboard(habits: [widget.habit], showBackButton: false),
                _buildEntriesTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: Icon(Icons.add),
        backgroundColor: habitColor,
      ),
    );
  }

  void _navigateToDate(DateTime date) {
    // First switch to the calendar tab
    _tabController.animateTo(1);
    
    // Then set the selected date in the calendar
    // We need to wait for the tab to change before scrolling
    Future.delayed(Duration(milliseconds: 300), () {
      final calendarWidget = _calendarViewKey.currentWidget as CalendarView?;
      if (calendarWidget != null) {
        // Set the selected date in the calendar
        calendarWidget.setSelectedDate(date);
      }
    });
  }

  Widget _buildOverviewTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final habit = widget.habit;
    final habitColor = habit.color ?? Theme.of(context).colorScheme.primary;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card with key stats
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    habitColor.withOpacity(0.8),
                    habitColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          habit.icon ?? Icons.star,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.formattedName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getHabitTypeText(habit.type),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildStatCounter(
                        'Current Streak',
                        '${habit.currentStreak}',
                        'days',
                        Icons.local_fire_department,
                        Colors.white,
                      ),
                      _buildStatCounter(
                        'Entries',
                        '${habit.entries.length}',
                        'total',
                        Icons.event_note,
                        Colors.white,
                      ),
                      _buildStatCounter(
                        'Success Rate',
                        '${habit.successRate.toStringAsFixed(1)}',
                        '%',
                        Icons.trending_up,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Habit details section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: habitColor),
                      SizedBox(width: 8),
                      Text(
                        'Habit Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  
                  // Responsive grid layout for habit details
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildDetailItem('Frequency', _getFrequencyText(habit), habitColor),
                      if (habit.category != null)
                        _buildDetailItem('Category', habit.category!, habitColor),
                      if (habit.targetValue != null)
                        _buildDetailItem('Target', '${habit.targetValue} ${habit.getUnitDisplayName()}', habitColor),
                      _buildDetailItem('Started', '${habit.entries.isNotEmpty ? DateFormat('MMM d, yyyy').format(habit.entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b)) : "No entries"}', habitColor),
                      if (habit.isPaused)
                        _buildDetailItem('Status', 'Paused', Colors.orange),
                      if (habit.type == HabitType.FailBased && habit.hasEntries)
                        _buildDetailItem('Time Clean', habit.getTimeSinceLastFailure(), Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Last entries section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: habitColor),
                      SizedBox(width: 8),
                      Text(
                        'Recent Entries',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => _tabController.animateTo(3), // Navigate to History tab
                        child: Text('View All'),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  habit.entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No entries yet. Tap the + button to add one!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Column(
                          children: habit.entries
                              .take(3) // Show only the 3 most recent entries
                              .map((entry) => _buildRecentEntryItem(entry))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCounter(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$label ($unit)',
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, Color color) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentEntryItem(HabitEntry entry) {
    final isPositive = widget.habit.isPositiveDay(entry);
    final statusColor = entry.isSkipped ? Colors.orange : (isPositive ? Colors.green : Colors.red);
    final statusIcon = entry.isSkipped ? Icons.skip_next : (isPositive ? Icons.check_circle : Icons.cancel);
    
    return InkWell(
      onTap: () => _editEntry(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(entry.date),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(
                      entry.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.isSkipped
                    ? 'Skipped'
                    : widget.habit.type == HabitType.DoneBased
                        ? (isPositive ? 'Done' : 'Not Done')
                        : (entry.value != null
                            ? '${entry.value} ${widget.habit.getUnitDisplayName()}'
                            : '${entry.count} ${widget.habit.getUnitDisplayName()}'),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendarTab() {
    final habit = widget.habit;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on a day to view or add entries. Green indicates success, red indicates failure, and orange indicates skipped days.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: CalendarView(
              habit: habit,
              onRefresh: _refreshHabit,
              key: _calendarViewKey,
            ),
          ),
        ],
      ),
    );
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
                  Text('Add entries from the home screen', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
}