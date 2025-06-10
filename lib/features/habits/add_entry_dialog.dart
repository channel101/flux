// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/core/enums/app_enums.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/main.dart';
import 'package:intl/intl.dart';

class AddEntryDialog extends StatefulWidget {
  final Habit habit;
  final int dayNumber;
  final Function(HabitEntry) onSave;
  final DateTime? selectedDate;

  const AddEntryDialog({
    required this.habit, 
    required this.dayNumber, 
    required this.onSave, 
    this.selectedDate,
  });

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> with TickerProviderStateMixin {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _skipReasonController = TextEditingController();

  bool _isDone = false;
  bool _isSkipped = false;
  int _sliderValue = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    // Initialize with target value if available
    if (widget.habit.targetValue != null) {
      _valueController.text = widget.habit.targetValue!.toString();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    _skipReasonController.dispose();
    super.dispose();
  }

  String get _getMainTitle {
    if (_isSkipped) {
      if (widget.selectedDate != null) {
        final formatter = DateFormat('MMM d, yyyy');
        return 'Skipping ${formatter.format(widget.selectedDate!)}';
      }
      return 'Skipping Day ${widget.dayNumber}';
    }

    String baseTitle;
    if (widget.habit.unit != HabitUnit.Count && widget.habit.targetValue != null) {
      switch (widget.habit.type) {
        case HabitType.FailBased:
          baseTitle = 'Track Failure';
          break;
        case HabitType.SuccessBased:
          baseTitle = 'Track Progress';
          break;
        case HabitType.DoneBased:
          baseTitle = 'Mark as Done';
          break;
      }
    } else {
      switch (widget.habit.type) {
        case HabitType.FailBased:
          baseTitle = 'Track Failure';
          break;
        case HabitType.SuccessBased:
          baseTitle = 'Track Success';
          break;
        case HabitType.DoneBased:
          baseTitle = 'Mark Completion';
          break;
      }
    }

    // Add date if available
    if (widget.selectedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day);
      
      if (selectedDay.isAtSameMomentAs(today)) {
        return '$baseTitle for Today';
      } else {
        final formatter = DateFormat('MMM d, yyyy');
        return '$baseTitle for ${formatter.format(widget.selectedDate!)}';
      }
    }
    
    return baseTitle;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400, 
            maxHeight: MediaQuery.of(context).size.height * (isLandscape ? 0.9 : 0.8)
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkipSection(),
                      if (!_isSkipped) ...[
                        SizedBox(height: 20),
                        _buildSimplifiedContent(isSmallScreen),
                        if (widget.habit.targetValue != null) ...[
                          SizedBox(height: 16),
                          _buildTargetProgressIndicator(),
                        ],
                        SizedBox(height: 16),
                        _buildNotesSection(),
                      ] else ...[
                        SizedBox(height: 20),
                        _buildSkipReasonSection(),
                      ],
                      SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.habit.color?.withOpacity(0.8) ?? Theme.of(context).colorScheme.primary.withOpacity(0.8),
            widget.habit.color ?? Theme.of(context).colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(widget.habit.icon ?? Icons.star, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.habit.formattedName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(_getMainTitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isSkipped ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSkipped ? Colors.orange.withOpacity(0.3) : Colors.grey.withOpacity(0.2), width: 2),
      ),
      child: Row(
        children: [
          Icon(_isSkipped ? Icons.skip_next : Icons.schedule, color: _isSkipped ? Colors.orange : Colors.grey, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skip this day?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSkipped ? Colors.orange : null),
                ),
                SizedBox(height: 4),
                Text("Won't break your streak or affect statistics", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: _isSkipped,
            onChanged: (value) {
              setState(() {
                _isSkipped = value;
                if (value) {
                  _isDone = false;
                  _countController.clear();
                  _valueController.clear();
                  _notesController.clear();
                }
              });
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedContent(bool isSmallScreen) {
    if (widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count) {
      // Simple done/not done toggle
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isDone ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isDone ? Colors.green : Colors.red, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isDone = !_isDone),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isDone ? Icons.check_circle : Icons.cancel, color: _isDone ? Colors.green : Colors.red, size: 32),
                  SizedBox(width: 12),
                  Text(
                    _isDone ? 'Completed ✓' : 'Not Completed ✗',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDone ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.habit.unit == HabitUnit.Count) {
      // Count-based input with buttons
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many ${widget.habit.getUnitDisplayName()}?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button - hide on small screens
                if (!isSmallScreen)
                IconButton(
                  onPressed: () {
                    final currentValue = int.tryParse(_countController.text) ?? 0;
                    if (currentValue > 0) {
                      _countController.text = (currentValue - 1).toString();
                      setState(() {
                        _sliderValue = (currentValue - 1).clamp(0, 50);
                      });
                    }
                  },
                  icon: Icon(Icons.remove_circle, size: 32, color: Theme.of(context).colorScheme.primary),
                ),
                
                // Count display
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      suffixText: widget.habit.getUnitDisplayName(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? 0;
                      setState(() {
                        _sliderValue = intValue.clamp(0, 50);
                      });
                    },
                  ),
                ),
                
                // Plus button - hide on small screens
                if (!isSmallScreen)
                IconButton(
                  onPressed: () {
                    final currentValue = int.tryParse(_countController.text) ?? 0;
                    _countController.text = (currentValue + 1).toString();
                    setState(() {
                      _sliderValue = (currentValue + 1).clamp(0, 50);
                    });
                  },
                  icon: Icon(Icons.add_circle, size: 32, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Quick buttons - always show on small screens to replace +/- buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (isSmallScreen) ...[
                _buildQuickButton('-1', -1),
                _buildQuickButton('+1', 1),
              ],
              _buildQuickButton('+5', 5),
              _buildQuickButton('+10', 10),
              _buildQuickButton('Reset', -99),
            ],
          ),
        ],
      );
    } else if (widget.habit.unit == HabitUnit.Minutes) {
      // Time input
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration (minutes):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          
          // Enhanced time input with clock visualization
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Time input field
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus button - hide on small screens
                    if (!isSmallScreen)
                    IconButton(
                      onPressed: () {
                        final currentValue = double.tryParse(_valueController.text) ?? 0;
                        if (currentValue > 0) {
                          _valueController.text = (currentValue - 5).clamp(0, 300).toString();
                        }
                      },
                      icon: Icon(Icons.remove_circle, size: 32, color: Theme.of(context).colorScheme.primary),
                    ),
                    
                    // Time display
                    Expanded(
                      child: TextFormField(
                        controller: _valueController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          suffixText: 'min',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    
                    // Plus button - hide on small screens
                    if (!isSmallScreen)
                    IconButton(
                      onPressed: () {
                        final currentValue = double.tryParse(_valueController.text) ?? 0;
                        _valueController.text = (currentValue + 5).toString();
                      },
                      icon: Icon(Icons.add_circle, size: 32, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Clock visualization
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      _getTimeDisplay(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick time buttons - always show on small screens
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (isSmallScreen) ...[
                _buildQuickButton('-5 min', -5),
                _buildQuickButton('+5 min', 5),
              ],
              _buildQuickButton('15 min', 15),
              _buildQuickButton('30 min', 30),
              _buildQuickButton('60 min', 60),
            ],
          ),
        ],
      );
    } else {
      // Value-based input (for other units)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter ${widget.habit.getUnitDisplayName()}:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // Only show buttons on larger screens
                if (!isSmallScreen)
                IconButton(
                  onPressed: () {
                    final currentValue = double.tryParse(_valueController.text) ?? 0;
                    if (currentValue > 0) {
                      _valueController.text = (currentValue - 1).clamp(0, double.infinity).toString();
                    }
                  },
                  icon: Icon(Icons.remove_circle, size: 28, color: Theme.of(context).colorScheme.primary),
                ),
                
                Expanded(
                  child: TextFormField(
                    controller: _valueController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      suffixText: widget.habit.getUnitDisplayName(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                
                if (!isSmallScreen)
                IconButton(
                  onPressed: () {
                    final currentValue = double.tryParse(_valueController.text) ?? 0;
                    _valueController.text = (currentValue + 1).toString();
                  },
                  icon: Icon(Icons.add_circle, size: 28, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          
          // Show quick buttons for small screens
          if (isSmallScreen)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickButton('-1', -1),
                _buildQuickButton('+1', 1),
                _buildQuickButton('+5', 5),
              ],
            ),
          ),
        ],
      );
    }
  }

  String _getTimeDisplay() {
    final minutes = int.tryParse(_valueController.text) ?? 0;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours hr ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    } else {
      return '$minutes minutes';
    }
  }

  Widget _buildTargetProgressIndicator() {
    final targetValue = widget.habit.targetValue!;
    final currentValue = widget.habit.unit == HabitUnit.Count
        ? (int.tryParse(_countController.text) ?? 0).toDouble()
        : (double.tryParse(_valueController.text) ?? 0.0);

    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    final isOnTrack = widget.habit.type == HabitType.FailBased ? currentValue <= targetValue : currentValue >= targetValue;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnTrack
              ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
              : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnTrack ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: isOnTrack ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(8)),
                child: Icon(isOnTrack ? Icons.check_circle : Icons.warning, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Status',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getProgressText(isOnTrack, currentValue, targetValue),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isOnTrack ? Colors.green : Colors.orange, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(isOnTrack ? Colors.green : Colors.orange),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${currentValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} ${widget.habit.getUnitDisplayName()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_add, color: Theme.of(context).colorScheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: widget.habit.type == HabitType.FailBased ? 'What triggered this? Any insights...' : 'How did it go? Any thoughts...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipReasonSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Why are you skipping today?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _skipReasonController,
            decoration: InputDecoration(
              hintText: 'e.g., sick, traveling, planned rest day...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSkipped ? Colors.orange : (widget.habit.color ?? Theme.of(context).colorScheme.primary),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(_isSkipped ? 'Skip Day' : 'Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  String _getProgressText(bool isOnTrack, double current, double target) {
    switch (widget.habit.type) {
      case HabitType.FailBased:
        if (current <= target) {
          return 'Within limit ✓';
        } else {
          return 'Over limit by ${(current - target).toStringAsFixed(1)}';
        }
      case HabitType.SuccessBased:
        if (current >= target) {
          return 'Target reached! ✓';
        } else {
          return 'Need ${(target - current).toStringAsFixed(1)} more';
        }
      case HabitType.DoneBased:
        if (current >= target) {
          return 'Goal achieved! ✓';
        } else {
          return 'Progress towards goal';
        }
    }
  }

  Widget _buildQuickButton(String label, int value) {
    Color backgroundColor;
    Color textColor;
    
    if (value < 0) {
      if (value == -99) { // Reset button
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.black87;
      } else {
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
      }
    } else {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      textColor = Theme.of(context).colorScheme.primary;
    }
    
    return Container(
      constraints: BoxConstraints(minWidth: 60),
      child: ElevatedButton(
        onPressed: () {
          if (value == -99) {
            // Reset button - handle both count and value inputs
            if (widget.habit.unit == HabitUnit.Count) {
              _countController.text = '0';
              setState(() {
                _sliderValue = 0;
              });
            } else {
              _valueController.text = '0';
            }
          } else if (value < 0 && widget.habit.unit == HabitUnit.Minutes) {
            // Decrement time value
            final currentValue = int.tryParse(_valueController.text) ?? 0;
            final newValue = (currentValue + value).clamp(0, 300);
            _valueController.text = newValue.toString();
          } else if (value < 0) {
            // Decrement count value
            final currentValue = int.tryParse(_countController.text) ?? 0;
            final newValue = (currentValue + value).clamp(0, 50);
            _countController.text = newValue.toString();
            setState(() {
              _sliderValue = newValue;
            });
          } else if (widget.habit.unit == HabitUnit.Minutes) {
            // Set or add time value
            if (label.contains('+')) {
              // Add to current value
              final currentValue = int.tryParse(_valueController.text) ?? 0;
              _valueController.text = (currentValue + value).toString();
            } else {
              // Set to specific value
              _valueController.text = value.toString();
            }
          } else {
            // Add value button for count
            final currentValue = int.tryParse(_countController.text) ?? 0;
            final newValue = currentValue + value;
            _countController.text = newValue.toString();
            setState(() {
              _sliderValue = newValue.clamp(0, 50);
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: Size(50, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _saveEntry() {
    if (_isSkipped) {
      // Create skipped entry with reason
      final entry = HabitEntry(
        date: widget.selectedDate ?? DateTime.now(),
        count: 0,
        dayNumber: widget.dayNumber,
        isSkipped: true,
        notes: _skipReasonController.text.trim().isNotEmpty ? 'Skip reason: ${_skipReasonController.text.trim()}' : 'Skipped day',
      );
      widget.onSave(entry);
      return;
    }

    int count = 0;
    double? value;

    if (widget.habit.type == HabitType.DoneBased && widget.habit.unit == HabitUnit.Count) {
      count = _isDone ? 1 : 0;
    } else if (widget.habit.unit == HabitUnit.Count) {
      count = int.tryParse(_countController.text) ?? _sliderValue;
    } else {
      value = double.tryParse(_valueController.text);
      if (value != null) {
        count = value! > 0 ? 1 : 0; // Set count based on whether value was entered
      }
    }

    final entry = HabitEntry(
      date: widget.selectedDate ?? DateTime.now(),
      count: count,
      dayNumber: widget.dayNumber,
      value: value,
      unit: widget.habit.unit != HabitUnit.Count ? widget.habit.getUnitDisplayName() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      isSkipped: false,
    );

    widget.onSave(entry);
  }
}
