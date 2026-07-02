import 'dart:io';
import 'package:html/parser.dart' show parse;

void main() {
  final html = File('notices_dl.html').readAsStringSync();
  final d = parse(html);
  
  // Try table rows first
  final trs = d.querySelectorAll('tr');
  if (trs.length > 5) {
    print('Found Table Rows: ${trs.length}');
    for (var i = 1; i < 4; i++) {
        final row = trs[i];
        final tds = row.querySelectorAll('td');
        if (tds.length >= 3) {
            final title = tds[tds.length - 2].text.trim();
            final link = tds[tds.length - 1].querySelector('a')?.attributes['href'];
            print('Row: $title -> $link');
        } else {
             print('Row format unknown: ${row.text.replaceAll('\n',' ').trim().substring(0, row.text.length > 100 ? 100 : row.text.length)}');
        }
    }
    return;
  }
}
