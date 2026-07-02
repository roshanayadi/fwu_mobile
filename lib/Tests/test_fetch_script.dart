import 'dart:io';
import 'dart:convert';

void main() async {
  try {
    HttpClient client = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    var request = await client.getUrl(
      Uri.parse("https://fwuexam.edu.np/notice.html"),
    );
    var response = await request.close();
    var body = await response.transform(utf8.decoder).join();

    RegExp linkExp = RegExp(
      r'<a[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>',
      caseSensitive: false,
    );
    var matches = linkExp.allMatches(body);

    int validCount = 0;
    for (var match in matches) {
      String text = match.group(2) ?? "";
      text = text.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (text.length > 20 && text.split(" ").length > 4) {
        validCount++;
        if (validCount >= 5) break;
      }
    }
    if (validCount == 0) {
    } else {}
  } catch (e) {}
}
