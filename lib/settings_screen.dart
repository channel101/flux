// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flux/main.dart';
import 'package:flutter/material.dart';
import 'package:flux/settings_service.dart';
import 'package:flux/theme_selection_screen.dart';
import 'package:flux/debug_test_page.dart';
import 'package:flutter/foundation.dart';

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
                ListTile(
                  title: Text('Choose Theme'),
                  subtitle: Text('Select from 40+ available themes'),
                  leading: Icon(Icons.palette),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemeSelectionScreen(
                        onThemeChanged: (theme) {
                          // Theme change is handled in ThemeSelectionScreen
                        },
                      ),
                    ),
                  ),
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
                if (kDebugMode) ...[
                  Divider(),
                  _buildSection('🛠️ Debug'),
                  ListTile(
                    title: Text('Debug Test Page'),
                    subtitle: Text('Testing tools (Debug mode only)'),
                    leading: Icon(Icons.bug_report, color: Colors.red),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DebugTestPage()),
                    ),
                  ),
                ],
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
