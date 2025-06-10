import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/features/habits/add_entry_dialog.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:flux/main.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  final Habit habit;
  final Function() onRefresh;
  
  // Static reference to the current instance for access from widget
  static CalendarView? instance;
  
  const CalendarView({
    Key? key,
    required this.habit,
    required this.onRefresh,
  }) : super(key: key);
  
  // Public method to scroll to selected date
  void scrollToSelectedDate() {
    // Find the current state and call its method
    final state = _CalendarViewState.instance;
    if (state != null) {
      state.scrollToSelectedDate();
    }
  }
  
  // Public method to set a specific date and scroll to it
  void setSelectedDate(DateTime date) {
    final state = _CalendarViewState.instance;
    if (state != null) {
      state.setSelectedDate(date);
    }
  }
  
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  // Static reference to the current instance for access from widget
  static _CalendarViewState? instance;
  
  late final ValueNotifier<List<HabitEntry>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<HabitEntry>> _events = {};
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    instance = this;
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _processHabitEntries();
    
    // Fix: Add a delay before scrolling to ensure calendar is built
    Future.delayed(Duration(milliseconds: 200), () {
      scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    _selectedEvents.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _processHabitEntries() {
    Map<DateTime, List<HabitEntry>> events = {};
    
    for (var entry in widget.habit.entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (events[date] != null) {
        events[date]!.add(entry);
      } else {
        events[date] = [entry];
      }
    }
    
    setState(() {
      _events = events;
    });
  }

  List<HabitEntry> _getEventsForDay(DateTime day) {
    // Normalize the date to avoid time issues
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Color _getColorForDay(DateTime day) {
    final entries = _getEventsForDay(day);
    if (entries.isEmpty) {
      // Check if this day should have an entry based on frequency
      if (_shouldHaveEntry(day)) {
        return Colors.red.withOpacity(0.3); // Missed day
      }
      return Colors.transparent; // No entry expected
    }
    
    final entry = entries.first;
    if (entry.isSkipped) {
      return Colors.orange.withOpacity(0.4); // Skipped
    }
    
    if (widget.habit.isPositiveDay(entry)) {
      return Colors.green.withOpacity(0.6); // Success
    } else {
      return Colors.red.withOpacity(0.6); // Failure
    }
  }

  bool _shouldHaveEntry(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    
    // Don't mark future days as missed
    if (checkDay.isAfter(today)) return false;
    
    // Don't mark days before habit creation as missed
    if (widget.habit.entries.isNotEmpty) {
      final firstEntryDate = widget.habit.entries
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (checkDay.isBefore(firstEntryDate)) return false;
    }
    
    // Check if habit was due on this day based on frequency
    switch (widget.habit.frequency) {
      case HabitFrequency.Daily:
        return true;
      case HabitFrequency.Weekdays:
        return day.weekday <= 5; // Monday = 1, Friday = 5
      case HabitFrequency.Weekends:
        return day.weekday > 5; // Saturday = 6, Sunday = 7
      case HabitFrequency.CustomDays:
        final dayIndex = day.weekday % 7; // Convert to 0=Sunday format
        return widget.habit.customDays.contains(dayIndex);
      case HabitFrequency.XTimesPerWeek:
      case HabitFrequency.XTimesPerMonth:
        // For frequency-based habits, don't mark individual days as missed
        return false;
    }
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _showAddEntryForDay(DateTime day) {
    // Calculate day number based on first entry date or use current logic
    int dayNumber = 1;
    if (widget.habit.entries.isNotEmpty) {
      final firstEntryDate = widget.habit.entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      dayNumber = day.difference(DateTime(firstEntryDate.year, firstEntryDate.month, firstEntryDate.day)).inDays + 1;
      if (dayNumber <= 0) dayNumber = widget.habit.getNextDayNumber();
    }

    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: widget.habit,
        dayNumber: dayNumber,
        selectedDate: day,
        onSave: (entry) async {
          // Set the correct date for the entry
          entry.date = day;
          widget.habit.entries.add(entry);
          await StorageService.save(widget.habit);
          Navigator.of(context).pop();
          _processHabitEntries();
          widget.onRefresh();
        },
      ),
    );
  }

  // Method to scroll to selected date
  void scrollToSelectedDate() {
    if (_selectedDay != null) {
      setState(() {
        _focusedDay = _selectedDay!;
        _calendarFormat = CalendarFormat.month; // Ensure month view to see the date
      });
    }
  }

  // Method to set a specific date and scroll to it
  void setSelectedDate(DateTime date) {
    setState(() {
      _selectedDay = date;
      _focusedDay = date;
      _selectedEvents.value = _getEventsForDay(date);
    });
    
    // Add a small delay to ensure the state is updated
    Future.delayed(Duration(milliseconds: 100), scrollToSelectedDate);
  }

  void _editEntry(HabitEntry entry) {
    // Calculate day number based on first entry date
    int dayNumber = entry.dayNumber;
    
    showDialog(
      context: context,
      builder: (context) => AddEntryDialog(
        habit: widget.habit,
        dayNumber: dayNumber,
        selectedDate: entry.date,
        onSave: (newEntry) async {
          // Remove existing entry and add the updated one
          widget.habit.entries.remove(entry);
          widget.habit.entries.add(newEntry);
          await StorageService.save(widget.habit);
          Navigator.of(context).pop();
          _processHabitEntries();
          widget.onRefresh();
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          _buildLegend(),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TableCalendar<HabitEntry>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay!, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                headerVisible: false, // Hide the default header since we have our own
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[600]),
                  defaultTextStyle: TextStyle(fontWeight: FontWeight.w500),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, false, _selectedDay != null && isSameDay(_selectedDay!, day));
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, true, _selectedDay != null && isSameDay(_selectedDay!, day));
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, false, true);
                  },
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildSelectedDayInfo(),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final color = _getColorForDay(day);
    final entries = _getEventsForDay(day);
    
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isToday 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : isSelected 
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : null,
                fontSize: 14,
              ),
            ),
            if (entries.isNotEmpty)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.green.withOpacity(0.6), 'Success'),
                _buildLegendItem(Colors.red.withOpacity(0.6), 'Failure'),
                _buildLegendItem(Colors.orange.withOpacity(0.4), 'Skipped'),
                _buildLegendItem(Colors.red.withOpacity(0.3), 'Missed'),
                _buildLegendItem(Colors.grey.withOpacity(0.1), 'No Entry'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSelectedDayInfo() {
    return ValueListenableBuilder<List<HabitEntry>>(
      valueListenable: _selectedEvents,
      builder: (context, entries, _) {
        if (entries.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.event_note, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    _selectedDay == null ? 'Select a day' : 'No entries for ${DateFormat.yMMMd().format(_selectedDay!)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  if (_selectedDay != null) ...[
                    Text(
                      'Tap the button below to add an entry',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEntryForDay(_selectedDay!),
                      icon: Icon(Icons.add),
                      label: Text('Add Entry'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Entries for ${DateFormat.yMMMd().format(_selectedDay!)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      tooltip: 'Add Entry',
                      onPressed: () => _showAddEntryForDay(_selectedDay!),
                    ),
                  ],
                ),
                Divider(),
                ...entries.map((entry) => _buildEntryItem(entry)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryItem(HabitEntry entry) {
    final isPositive = widget.habit.isPositiveDay(entry);
    final statusColor = entry.isSkipped ? Colors.orange : (isPositive ? Colors.green : Colors.red);
    
    String statusText;
    if (entry.isSkipped) {
      statusText = 'Skipped';
    } else if (widget.habit.type == HabitType.DoneBased) {
      statusText = isPositive ? 'Completed' : 'Not Completed';
    } else {
      if (widget.habit.targetValue != null) {
        final value = entry.value ?? entry.count.toDouble();
        final target = widget.habit.targetValue!;
        final percentage = (value / target * 100).toStringAsFixed(0);
        statusText = '${entry.value ?? entry.count} ${widget.habit.getUnitDisplayName()} ($percentage%)';
      } else {
        statusText = '${entry.value ?? entry.count} ${widget.habit.getUnitDisplayName()}';
      }
    }
    
    return InkWell(
      onTap: () => _editEntry(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Icon(
                  entry.isSkipped ? Icons.skip_next :
                  (isPositive ? Icons.check_circle : Icons.cancel),
                  color: statusColor,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(
                      entry.notes!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              color: Colors.grey[600],
              onPressed: () => _editEntry(entry),
            ),
          ],
        ),
      ),
    );
  }
} 