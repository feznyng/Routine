class Util {
  static String camelToSnake(String input) {
    if (input.isEmpty) return input;
    
    // Start with the first character
    StringBuffer result = StringBuffer(input[0].toLowerCase());
    
    // Process remaining characters
    for (int i = 1; i < input.length; i++) {
      String char = input[i];
      
      // If uppercase letter found, add underscore before it
      if (char == char.toUpperCase()) {
        result.write('_');
        result.write(char.toLowerCase());
      } else {
        result.write(char);
      }
    }
    
    return result.toString();
  }

  static String snakeToCamel(String input) {
    if (input.isEmpty) return input;
    
    // Split the string by underscores
    List<String> words = input.split('_');
    
    // Convert first word to lowercase
    String result = words[0].toLowerCase();
    
    // Capitalize first letter of remaining words and add them
    for (int i = 1; i < words.length; i++) {
      String word = words[i];
      if (word.isNotEmpty) {
        result += word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
    }
    
    return result;
  }

  static bool isBeforeToday(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateTime.isBefore(today);
  }
}