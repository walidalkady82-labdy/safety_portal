import 'dart:io';

void main() {
  final csvFile = File('assets/local/lang.csv');
  final libDir = Directory('lib');

  if (!csvFile.existsSync()) {
    print('❌ Error: CSV not found at ${csvFile.path}');
    return;
  }

  // 1. Load CSV Keys
  final lines = csvFile.readAsLinesSync();
  final Set<String> csvKeys = lines.skip(1)
      .map((line) => line.split(';')[0].trim())
      .where((k) => k.isNotEmpty)
      .toSet();

  // 2. Optimized Regex for single and double quotes
  // Pattern 1: Matches 'key'.t() or "key".t()
  final tRegex = RegExp(r'["' + "'" + r']([^"' + "'" + r']*)["' + "'" + r']\.t\(\)');
  
  // Pattern 2: Matches Text('content') or Text("content") NOT followed by .t()
  final hardcodedRegex = RegExp(r'Text\((["' + "'])" + r"(.*?)\1(?!\.t\(\))\)");

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  print('=' * 50);
  print('       HSE-PORTAL AUDIT: HARD-CODED CHECK');
  print('=' * 50);

  for (var file in files) {
    final content = file.readAsStringSync();
    final relativePath = file.path.replaceFirst(Directory.current.path, '');

    // Check for keys missing in CSV
    for (var match in tRegex.allMatches(content)) {
      final key = match.group(1)!;
      if (!csvKeys.contains(key)) {
        print('🚩 ERROR: Key "$key" used as .t() but MISSING in CSV!');
        print('   File: $relativePath\n');
      }
    }

    // Check for actual Hard-coded text
    for (var match in hardcodedRegex.allMatches(content)) {
      final text = match.group(2)!; // Capture group 2 is the actual text
      
      // Filter out empty strings, whitespace, or technical icons like ':'
      if (text.trim().isNotEmpty && text != ':' && text != '-') {
        print('💡 WARNING: Hard-coded string "$text" found without .t()');
        print('   File: $relativePath\n');
      }
    }
  }
}