// lib/main.dart

class HabitEntry {
  DateTime date;
  int dayNumber;
  int count;
  
  // New fields for enhanced functionality
  double? value; // For quantifiable entries (e.g., 30 minutes, 5.5 km)
  String? unit; // Unit of measurement
  String? notes; // Notes for the entry (especially for failures)
  bool isSkipped; // Whether this day was skipped
  
  HabitEntry({
    required DateTime date, 
    required this.count, 
    required this.dayNumber,
    this.value,
    this.unit,
    this.notes,
    this.isSkipped = false,
  }) : date = DateTime(date.year, date.month, date.day);
  
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'dayNumber': dayNumber,
        'value': value,
        'unit': unit,
        'notes': notes,
        'isSkipped': isSkipped,
      };
      
  static HabitEntry fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.parse(json['date']);
    // Normalize date to remove time component
    final normalizedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    
    return HabitEntry(
      date: normalizedDate,
      count: json['count'],
      dayNumber: json['dayNumber'] ?? 0,
      value: json['value']?.toDouble(),
      unit: json['unit'],
      notes: json['notes'],
      isSkipped: json['isSkipped'] ?? false,
    );
  }
  
  // Compare dates without considering time
  bool isSameDate(DateTime other) {
    return date.year == other.year && 
           date.month == other.month && 
           date.day == other.day;
  }
}
