import 'dart:convert';
import 'dart:io';

void main() async {
  print('Fetching Marksheet...');
  HttpClient client = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

  try {
    // 2079 exam year, 25556 exam roll, 3 semester, maybe?
    var request = await client.postUrl(Uri.parse('https://exam.fwu.edu.np/Result/Marksheet'));
    request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');

    // Trying some dummy data that might return result
    String body = 'ExamYear=2079&ExamRollNo=25556&SemesterId=3';
    request.write(body);

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    print('Status Code: ${response.statusCode}');
    print('Response Body: $responseBody');
  } catch (e) {
    print('Error: \$e');
  } finally {
    client.close();
  }
}
