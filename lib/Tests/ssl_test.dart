import 'dart:io';

Future<void> main() async {
  final urls = [
    'https://fwuexam.edu.np/notice.html',
    'https://www.fwu.edu.np/notice.html',
    'https://exam.fwu.edu.np'
  ];

  for (var url in urls) {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
      final response = await request.close();
    } catch (e) {
    }
  }
}
