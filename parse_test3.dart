import 'dart:io';
import 'package:html/parser.dart' show parse;

void main() {
  final html = File('notices_dl.html').readAsStringSync();
  final document = parse(html);
  
  var modals = document.querySelectorAll('.modal-body');
  print('Found ${modals.length} modals');
  
  for (var i = 0; i < 5 && i < modals.length; i++) {
    var modal = modals[i];
    var a = modal.querySelector('a');
    if (a != null && a.attributes['href'] != null) {
      var titleEl = modal.querySelector('.notice-card-title');
      var dateEl = modal.querySelector('p.fw-medium');
      
      if (titleEl != null) {
        String titleStr = titleEl.text.trim();
        String linkStr = a.attributes['href']!;
        String dateStr = dateEl != null ? dateEl.text.trim() : "";
        
        print('--NOTICE--');
        print('Title: $titleStr');
        print('Date: $dateStr');
        print('Link: $linkStr');
      }
    }
  }
}
