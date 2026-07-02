import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final ioClient = HttpClient()..badCertificateCallback = (cert, host, port) => true;
  
  try {
    final request = await ioClient.postUrl(Uri.parse('https://exam.fwu.edu.np/Result/Index'));
    
    // Set headers
    request.headers.set('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
    request.headers.set('X-Requested-With', 'XMLHttpRequest');
    
    // The exact exam ID and student ID from the user's test
    // Usually we need model[ExamScheduleId], model[SymbolNo], model[DateOfBirthBS]
    final bodyStr = 'model[ExamScheduleId]=35&model[SymbolNo]=8162022&model[DateOfBirthBS]=2060/04/16';
    
    request.add(utf8.encode(bodyStr));
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    print('Response Code: ${response.statusCode}');
    print('Body:\n$body');
  } catch(e) {
    print('Error: $e');
  }
}
