import 'dart:io';
import 'package:html/parser.dart' show parse;

void main() {
  final html = File('notices_dl.html').readAsStringSync();
  final d = parse(html);
  
  // Find all anchors
  final links = d.querySelectorAll('a');
  for (var a in links) {
    if (a.attributes['href']?.contains('upload') ?? false) {
      print('Notice: ${a.text.trim()} -> ${a.attributes['href']}');
      
      // Let's find its parent to see how it's structured
      var p = a.parent?.parent;
      if (p != null) {
          print('Parent text: ${p.text.replaceAll('\n',' ').trim().substring(0, p.text.length > 100 ? 100 : p.text.length)}');
      }
    }
  }
}
