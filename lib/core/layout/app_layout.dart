import 'package:flutter/material.dart';

class AppLayout {
  AppLayout._();

  static const double maxContentWidth = 1440;
  static const double pagePadding = 16;

  static int fieldColumns(double width) {
    if (width >= 960) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  static Widget responsiveFields({
    required double maxWidth,
    required List<Widget> fields,
    double spacing = 10,
  }) {
    final columns = fieldColumns(maxWidth);
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < fields.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < fields.length - 1 ? spacing : 0),
              child: fields[i],
            ),
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += columns) {
      final chunk = fields.sublist(i, i + columns > fields.length ? fields.length : i + columns);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: j < columns - 1 ? spacing : 0,
                    bottom: i + columns < fields.length ? spacing : 0,
                  ),
                  child: j < chunk.length ? chunk[j] : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  static Widget pageContainer({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}
