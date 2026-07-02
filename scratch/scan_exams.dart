import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client _createResultClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => host.contains('fwu.edu.np');
  return IOClient(ioClient);
}

Future<void> main() async {
  final uri = Uri.parse('https://exam.fwu.edu.np/Result');
  final response = await _createResultClient().get(
    uri,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }
  );
  
  if (response.statusCode != 200) return;
  
  final html = response.body;
  final modelMatch = RegExp(r'var\s+model\s*=\s*(\{[\s\S]*?\});').firstMatch(html);
  
  if (modelMatch != null && modelMatch.group(1) != null) {
      final model = jsonDecode(modelMatch.group(1)!);
      final List<dynamic> examList = model['ExamSchedules'] ?? [];
      for (var e in examList) {
        print(e['Description']);
      }
  }
}
