class TimeParser {
  TimeParser._();

  static double toHours(String? value) {
    if (value == null || value.trim().isEmpty) return 0;

    final normalized = value.trim();
    final colonMatch = RegExp(r'^(\d+)(?::(\d{1,2}))?$').firstMatch(normalized);
    if (colonMatch != null) {
      final hours = int.tryParse(colonMatch.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(colonMatch.group(2) ?? '0') ?? 0;
      return hours + (minutes.clamp(0, 59) / 60);
    }

    final numberValue = double.tryParse(normalized.replaceAll(',', '.'));
    return numberValue ?? 0;
  }

  static String formatHoursMinutes(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    return '$wholeHours:${minutes.toString().padLeft(2, '0')}';
  }

  static String formatDurationFromMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
