class ChatHelper {
  static String formatTime(DateTime dateTime) {
    int hour = dateTime.hour;

    final int minute = dateTime.minute;

    final String period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} '
        '$period';
  }

  static bool isValidMessage(String text) {
    return text.trim().isNotEmpty;
  }

  static String cleanMessage(String text) {
    return text.trim();
  }
}