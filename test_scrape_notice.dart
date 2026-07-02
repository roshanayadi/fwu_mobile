import 'dart:io';
import 'dart:convert';

void main() async {
  final url = 'https://fwuexam.edu.np/notice.html';
  final ioClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;
  final request = await ioClient.getUrl(Uri.parse(url));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  File('notices_dl.html').writeAsStringSync(body);
}
