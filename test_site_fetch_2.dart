import 'dart:io';
import 'dart:convert';
import 'package:html/parser.dart' show parse;

void main() async {
  try {
    HttpClient client = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    var request = await client.getUrl(Uri.parse("https://fwuexam.edu.np/notice.html"));
    var response = await request.close();
    var body = await response.transform(utf8.decoder).join();
    
    var document = parse(body);
    var rows = document.querySelectorAll('tr');
    
    int valid = 0;
    for (var row in rows) {
      if (row.children.isNotEmpty) {
        var a = row.querySelector('a');
        if (a != null) {
          print("Title: \${row.children[1].text.trim().replaceAll('\n', ' ')}");
          print("Link: \${a.attributes['href']}");
          print("Date: \${row.children[2].text.trim()}");
          print("---");
          valid++;
          if (valid > 4) break;
        }
      }
    }
  } catch (e) {print("Error: $e");}
}