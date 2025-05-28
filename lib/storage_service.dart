// lib/main.dart

import 'dart:convert';
import 'dart:io';
import 'package:flux/habit.dart';
import 'package:flux/habit_entry.dart';
import 'package:flux/main.dart';
import 'package:path_provider/path_provider.dart';

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
  
  static Future<void> updateEntry(Habit habit, HabitEntry oldEntry, HabitEntry newEntry) async {
    final index = habit.entries.indexWhere((e) => e.dayNumber == oldEntry.dayNumber);
    if (index != -1) {
      habit.entries[index] = newEntry;
      await save(habit);
    }
  }
  
  static Future<void> deleteEntry(Habit habit, HabitEntry entry) async {
    habit.entries.removeWhere((e) => e.dayNumber == entry.dayNumber);
    await save(habit);
  }
}
