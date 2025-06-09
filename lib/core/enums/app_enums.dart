// lib/app_enums.dart

enum HabitType { FailBased, SuccessBased, DoneBased }
enum ReportDisplay { Rate, Streak }

// Enums for enhanced features
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

// Add a utility function to format PascalCase or camelCase to spaced text
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