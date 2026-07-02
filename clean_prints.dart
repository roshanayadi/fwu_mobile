import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int totalPrintsRemoved = 0;

  for (final file in files) {
    final lines = await file.readAsLines();
    final newLines = <String>[];
    bool modified = false;
    bool inMultilinePrint = false;

    for (final line in lines) {
      final trimmed = line.trim();
      
      if (inMultilinePrint) {
        modified = true;
        if (trimmed.endsWith(');') || RegExp(r'\);\s*(//.*)?$').hasMatch(trimmed)) {
          inMultilinePrint = false;
        }
        totalPrintsRemoved++;
        continue;
      }

      if (trimmed.startsWith('print(') || trimmed.startsWith('debugPrint(')) {
        modified = true;
        totalPrintsRemoved++;
        // Check if it's a single line print
        if (trimmed.endsWith(');') || RegExp(r'\);\s*(//.*)?$').hasMatch(trimmed)) {
          // single line print, skipped
        } else {
          inMultilinePrint = true;
        }
        continue;
      }

      newLines.add(line);
    }

    if (modified) {
      await file.writeAsString(newLines.join('\n') + '\n');
      print('Cleaned ${file.path}');
    }
  }
  print('Total lines removed for security: $totalPrintsRemoved');
}
