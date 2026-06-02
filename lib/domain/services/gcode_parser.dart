import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/calculator_models.dart';

class GCodeParser {
  GCodeMetrics? parse(String content, {double density = 1.24}) {
    return _parseContent(content, density);
  }

  static Future<GCodeMetrics?> parseAsync(
    String content, {
    double density = 1.24,
  }) {
    if (kIsWeb) {
      return Future.value(GCodeParser().parse(content, density: density));
    }
    return compute(_parseInIsolate, _ParseArgs(content, density));
  }

  String productNameFromFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'\.gcode$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .trim();
  }

  static GCodeMetrics? _parseInIsolate(_ParseArgs args) =>
      GCodeParser().parse(args.content, density: args.density);

  static GCodeMetrics? _parseContent(String content, double density) {
    var timeMinutes = 0.0;
    var meters = 0.0;

    final curaTime = RegExp(
      r';TIME:(\d+)',
      caseSensitive: false,
    ).firstMatch(content);
    final prusaTime = RegExp(
      r'; estimated printing time \(normal mode\) = (?:(\d+)h )?(?:(\d+)m )?(?:(\d+)s)?',
      caseSensitive: false,
    ).firstMatch(content);

    if (curaTime != null) {
      timeMinutes = int.parse(curaTime.group(1)!) / 60;
    } else if (prusaTime != null) {
      final hours = int.tryParse(prusaTime.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(prusaTime.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(prusaTime.group(3) ?? '0') ?? 0;
      timeMinutes = hours * 60 + minutes + seconds / 60;
    }

    final curaFilament = RegExp(
      r';Filament used: ([\d.]+)m',
      caseSensitive: false,
    ).firstMatch(content);
    final prusaFilament = RegExp(
      r'; filament used \[mm\] = ([\d.]+)',
      caseSensitive: false,
    ).firstMatch(content);

    if (curaFilament != null) {
      meters = double.parse(curaFilament.group(1)!);
    } else if (prusaFilament != null) {
      meters = double.parse(prusaFilament.group(1)!) / 1000;
    }

    final thumbnailBytes = _extractThumbnail(content);
    final gramsPerMeter = density * 3.0;
    final weight = (meters * gramsPerMeter).round();

    return GCodeMetrics(
      filamentType: 'PLA Premium',
      estimatedMeters: double.parse(meters.toStringAsFixed(2)),
      printTimeMinutes: timeMinutes.round(),
      weight: weight,
      thumbnailBytes: thumbnailBytes,
      density: density,
    );
  }

  static Uint8List? _extractThumbnail(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final startRegex = RegExp(
      r'^;\s*thumbnail(?:_jpg)?\s+begin',
      caseSensitive: false,
    );
    final endRegex = RegExp(
      r'^;\s*thumbnail(?:_jpg)?\s+end',
      caseSensitive: false,
    );

    var start = -1;
    for (var i = 0; i < lines.length; i++) {
      if (startRegex.hasMatch(lines[i])) {
        start = i + 1;
        break;
      }
    }

    if (start < 0) return null;

    final chunks = <String>[];
    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      if (endRegex.hasMatch(line)) break;
      final clean = line.replaceFirst(RegExp(r'^;\s?'), '').trim();
      if (clean.isNotEmpty) chunks.add(clean);
    }

    final base64Data = chunks.join().replaceAll(RegExp(r'\s+'), '');
    if (base64Data.isEmpty) return null;

    try {
      return Uint8List.fromList(base64.decode(base64Data));
    } catch (_) {
      return null;
    }
  }
}

class _ParseArgs {
  const _ParseArgs(this.content, this.density);
  final String content;
  final double density;
}
