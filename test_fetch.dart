import 'package:http/http.dart' as http;
void main() async {
  var r = await http.get(Uri.parse('https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1775814191-gsms.pdf'));
  print('Status: ${r.statusCode}');
  print('Body preview: ${r.body.length > 50 ? r.body.substring(0, 50) : r.body}');
}
