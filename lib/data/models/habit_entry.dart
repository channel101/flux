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
    required this.date, 
    required this.count, 
    required this.dayNumber,
    this.value,
    this.unit,
    this.notes,
    this.isSkipped = false,
  });
  
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'count': count,
        'dayNumber': dayNumber,
        'value': value,
        'unit': unit,
        'notes': notes,
        'isSkipped': isSkipped,
      };
      
  static HabitEntry fromJson(Map<String, dynamic> json) => HabitEntry(
        date: DateTime.parse(json['date']),
        count: json['count'],
        dayNumber: json['dayNumber'] ?? 0,
        value: json['value']?.toDouble(),
        unit: json['unit'],
        notes: json['notes'],
        isSkipped: json['isSkipped'] ?? false,
      );
}
