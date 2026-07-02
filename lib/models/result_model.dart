/// Safe key-agnostic extraction from a JSON map.
/// Tries each key in [keys] (order = priority). Keys are normalized by
/// stripping non-alphanumeric characters before comparison.
String _ext(Map<String, dynamic>? json, List<String> keys, {String fallback = ''}) {
  if (json == null) return fallback;
  final normalized = <String, dynamic>{};
  json.forEach((k, v) {
    final nk = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    normalized[nk] = v;
  });

  for (var k in keys) {
    final nk = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.containsKey(nk) && normalized[nk] != null) {
      final val = normalized[nk].toString().trim();
      if (val.isNotEmpty && val != 'null') return val;
    }
  }
  return fallback;
}

class ExamSchedule {
  final String id;
  final String name;
  final String? academicYearId;

  ExamSchedule({required this.id, required this.name, this.academicYearId});

  factory ExamSchedule.fromJson(Map<String, dynamic> json) {
    return ExamSchedule(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      academicYearId: json['academicYearId']?.toString(),
    );
  }
}

class SubjectResult {
  final String subjectCode;
  final String subjectName;
  final String creditHour;
  final String thMarks;
  final String prMarks;
  final String finalGrade;
  final String gradeValue;
  final String gradePoint;
  final String remark;

  SubjectResult({
    required this.subjectCode,
    required this.subjectName,
    required this.creditHour,
    required this.thMarks,
    required this.prMarks,
    required this.finalGrade,
    required this.gradeValue,
    required this.gradePoint,
    required this.remark,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subjectCode: _ext(json, ['SubjectCode', 'CourseCode', 'Code'], fallback: '-'),
      subjectName: _ext(json, ['SubjectName', 'CourseName', 'Title'], fallback: '-'),
      creditHour: _ext(json, ['CreditHour', 'CreditHours', 'CH'], fallback: '-'),
      thMarks: _ext(json, ['THOG', 'THGrade', 'THOM', 'TH', 'TheoryOM', 'Theory', 'ThMarks', 'ThObtained'], fallback: '-'),
      prMarks: _ext(json, ['PROG', 'PRGrade', 'PROM', 'IROM', 'PR', 'PracticalOM', 'Practical', 'PrMarks', 'PrObtained'], fallback: '-'),
      finalGrade: _ext(json, ['TotalOG', 'FinalGrade', 'Grade'], fallback: '-'),
      gradeValue: _ext(json, ['TotalGP', 'GradeVal', 'GPA'], fallback: '-'),
      gradePoint: _ext(json, ['GradeValue', 'GradePoint', 'TotalGrade'], fallback: '-'),
      remark: _ext(json, ['Remarks', 'Remark', 'Status'], fallback: '-'),
    );
  }
}

class ExamResult {
  final String studentName;
  final String symbolNo;
  final String gpa;
  final String resultStatus;
  final String? studentPhoto;
  
  final String? registrationNo;
  final String? campusName;
  final String? facultyName;
  final String? level;
  final String? semester;
  final String? examYear;
  final String? programName;
  final String? examType;
  final String? examCenter;

  final String? totalCreditHour;
  final String? totalGradePoint;

  final List<SubjectResult> subjects;
  final Map<String, dynamic> rawJson;
  final String? examScheduleId;

  ExamResult({
    required this.studentName,
    required this.symbolNo,
    required this.gpa,
    required this.resultStatus,
    this.studentPhoto,
    this.registrationNo,
    this.campusName,
    this.facultyName,
    this.level,
    this.semester,
    this.examYear,
    this.programName,
    this.examType,
    this.examCenter,
    this.totalCreditHour,
    this.totalGradePoint,
    required this.subjects,
    required this.rawJson,
    this.examScheduleId,
  });

  factory ExamResult.fromFwuJson(Map<String, dynamic> json, {String? examId}) {
    final header = json['Header'] ?? json;

    // Directly grab the subject details list
    final List<dynamic> details = (json['MarksRecord'] ?? json['Details'] ?? json['Subjects'] ?? json['Marks'] ?? json['SubjectResults']) is List 
      ? (json['MarksRecord'] ?? json['Details'] ?? json['Subjects'] ?? json['Marks'] ?? json['SubjectResults']) 
      : [];

    String? yearPart;
    if (header['Year'] != null && header['Part'] != null) {
      yearPart = '${header['Year']}/${header['Part']}';
    } else {
      yearPart = _ext(header, ['SemesterName', 'Semester']);
      if (yearPart.isEmpty) yearPart = null;
    }

    return ExamResult(
      studentName: _ext(header, ['StudentName', 'Name']),
      symbolNo: _ext(header, ['SymbolNo', 'RollNo', 'SymbolNumber']),
      gpa: _ext(header, ['GPA', 'CGPA', 'SGPA', 'TotalGradePoint'], fallback: '-'),
      resultStatus: _ext(header, ['ResultStatus', 'Result']),
      studentPhoto: _ext(header, ['Photo', 'StudentPhoto', 'PhotoPath']).isEmpty ? null : _ext(header, ['Photo', 'StudentPhoto', 'PhotoPath']),
      registrationNo: _ext(header, ['RegistrationNo', 'RegdNo', 'RegistrationNumber']),
      campusName: _ext(header, ['CampusName', 'SchoolName', 'Campus']),
      facultyName: _ext(header, ['FacultyName', 'Faculty']),
      level: _ext(header, ['Level', 'LevelName']),
      semester: yearPart,
      examYear: _ext(header, ['AcademicYearName', 'ExamYear', 'Year']),
      programName: _ext(header, ['ProgramName', 'Program']),
      examType: _ext(header, ['ExamType', 'ExamTypeName']),
      examCenter: _ext(header, ['ExamCenter']),
      totalCreditHour: _ext(header, ['TotalCreditHour']),
      totalGradePoint: _ext(header, ['TotalGradePoint']),
      subjects: details.map((d) => SubjectResult.fromJson(d as Map<String, dynamic>)).toList(),
      rawJson: json,
      examScheduleId: examId,
    );
  }
}
