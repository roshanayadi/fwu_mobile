import 'dart:convert';

/// Extracts a JSON object from an HTML <script> var declaration using
/// balanced-brace matching.
///
/// Looks for patterns like `var data = {...}`, `let model = {...}`, etc.
/// Returns the parsed [Map<String, dynamic>] or `null` if not found / unparseable.
Map<String, dynamic>? extractJsonVar(String html, String varName) {
  final patterns = [
    'var $varName = {',
    'var $varName={',
    'let $varName = {',
    'const $varName = {',
  ];
  for (final pat in patterns) {
    final idx = html.indexOf(pat);
    if (idx == -1) continue;
    final start = html.indexOf('{', idx);
    if (start == -1) continue;
    int depth = 0;
    for (int i = start; i < html.length; i++) {
      if (html[i] == '{') {
        depth++;
      } else if (html[i] == '}') {
        depth--;
        if (depth == 0) {
          try {
            final jsonStr = html.substring(start, i + 1);
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }
      }
    }
  }
  return null;
}
