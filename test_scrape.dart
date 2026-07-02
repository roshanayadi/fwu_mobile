import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final ioClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;
  
  try {
    final request = await ioClient.getUrl(Uri.parse('https://exam.fwu.edu.np/Result'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    File('emis_result.html').writeAsStringSync(body);
    print('Saved to emis_result.html');
  } catch(e) {
    print('Error: $e');
  }
}
