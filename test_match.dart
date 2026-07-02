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
  print('Fetching generic exam list from Result portal...');
  
  final uri = Uri.parse('https://exam.fwu.edu.np/Result');
  final response = await _createResultClient().get(
    uri,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }
  );
  
  if (response.statusCode != 200) {
    print('Failed to load. Status: ${response.statusCode}');
    return;
  }
  
  final html = response.body;
  final modelMatch = RegExp(r'var\s+model\s*=\s*(\{[\s\S]*?\});').firstMatch(html);
  
  List<String> exams = [];
  if (modelMatch != null && modelMatch.group(1) != null) {
      final model = jsonDecode(modelMatch.group(1)!);
      final List<dynamic> examList = model['ExamSchedules'] ?? [];
      exams = examList.map((e) => e['Description'].toString().trim()).toList();
  }
  
  print('Found ${exams.length} exams in Result portal.');
  if (exams.isEmpty) return;
  
  // Let's print out some exams
  print('\n[Top Published Exams]');
  for(int i=0; i<15 && i<exams.length; i++) {
     print("- ${exams[i]}");
  }

  // Simulate user's admit card from the form_model test
  final simulatedAdmitCards = [
    "BBA 8th Semester Exam", 
    "BSC CSIT 6th Semester",
    "Bachelor of Arts 1st Year",
    "BBMS 6th Sem",
    "B.B.A. 4th Semester Exam"
  ];
  
  print('\n[Simulating AI Fuzzy Match]');
  for (var registeredName in simulatedAdmitCards) {
     final cleanRegName = registeredName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
     print('\nTesting Admit Card: \n-> "$registeredName" (clean: $cleanRegName)');
     
     String? matched;
     for (var pubName in exams) {
        final cleanPubName = pubName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        
        if (cleanPubName == cleanRegName || 
            cleanPubName.contains(cleanRegName) || 
            cleanRegName.contains(cleanPubName)) {
           matched = pubName;
           break;
        }
     }
     
     if (matched != null) {
        print('✅ MATCH FOUND! "$matched"');
     } else {
        print('❌ NO MATCH FOUND.');
     }
  }
}
