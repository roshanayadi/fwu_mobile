class ExamSchedule {
  final int examScheduleId;
  final int studentAdmissionId;
  final String examScheduleName;
  final String? levelName;
  final String? programName;
  final String? year;
  final String? part;
  final bool isExamActive;
  final bool isExamRegistered;
  final bool isVerified;
  final bool isPaymentComplete;
  final bool admitCardDownloadEnabled;
  final int? examRegistrationId;
  final String? examRollNo;
  final double amount;

  ExamSchedule({
    required this.examScheduleId,
    required this.studentAdmissionId,
    required this.examScheduleName,
    this.levelName,
    this.programName,
    this.year,
    this.part,
    this.isExamActive = false,
    this.isExamRegistered = false,
    this.isVerified = false,
    this.isPaymentComplete = false,
    this.admitCardDownloadEnabled = false,
    this.examRegistrationId,
    this.examRollNo,
    this.amount = 0,
  });

  factory ExamSchedule.fromJson(Map<String, dynamic> json) {
    return ExamSchedule(
      examScheduleId: json['ExamScheduleId'] ?? 0,
      studentAdmissionId: json['StudentAdmissionId'] ?? 0,
      examScheduleName: json['ExamScheduleName'] ?? '',
      levelName: json['LevelName'],
      programName: json['ProgramName'],
      year: json['Year']?.toString(),
      part: json['Part']?.toString(),
      isExamActive: json['IsExamActive'] == true,
      isExamRegistered: json['IsExamRegistered'] == true,
      isVerified: json['IsVerified'] == true,
      isPaymentComplete: json['IsPaymentComplete'] == true,
      admitCardDownloadEnabled: json['AdmitCardDownloadEnabled'] == true,
      examRegistrationId: json['ExamRegistrationId'],
      examRollNo: json['ExamRollNo']?.toString(),
      amount: (json['Amount'] ?? 0).toDouble(),
    );
  }

  String get status {
    if (isVerified) return 'Verified';
    if (isExamRegistered) return 'Registered';
    if (isExamActive) return 'Open';
    return 'Closed';
  }

  bool get canFillForm => isExamActive && !isExamRegistered;
  bool get canViewForm => isExamRegistered;
}

class FormSubject {
  final String subjectName;
  final bool hasTheory;
  final bool hasPractical;
  bool isTheorySelected;
  bool isPracticalSelected;

  FormSubject({
    required this.subjectName,
    this.hasTheory = false,
    this.hasPractical = false,
    this.isTheorySelected = false,
    this.isPracticalSelected = false,
  });

  factory FormSubject.fromJson(Map<String, dynamic> json) {
    return FormSubject(
      subjectName: json['SubjectName'] ?? '',
      hasTheory: json['HasTheory'] == true,
      hasPractical: json['HasPractical'] == true,
      isTheorySelected: json['IsTheorySelected'] == true,
      isPracticalSelected: json['IsPracticalSelected'] == true,
    );
  }
}

class SubjectType {
  final String? subjectTypeName;
  final List<FormSubject> subjects;

  SubjectType({this.subjectTypeName, required this.subjects});

  factory SubjectType.fromJson(Map<String, dynamic> json) {
    return SubjectType(
      subjectTypeName: json['SubjectTypeName'],
      subjects: (json['Subjects'] as List? ?? [])
          .map((s) => FormSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectGroup {
  final String? subjectGroupName;
  final List<SubjectType> subjectTypes;

  SubjectGroup({this.subjectGroupName, required this.subjectTypes});

  factory SubjectGroup.fromJson(Map<String, dynamic> json) {
    return SubjectGroup(
      subjectGroupName: json['SubjectGroupName'],
      subjectTypes: (json['SubjectTypes'] as List? ?? [])
          .map((t) => SubjectType.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExamFormData {
  final Map<String, dynamic> rawModel;
  final List<SubjectGroup> subjectGroups;
  final bool isRegular;
  final int? examScheduleId;
  final int? examRegistrationId;
  final String? examScheduleName;
  final String? studentName;
  final String? programName;
  final String pageType; // 'examForm', 'payment', 'expired'
  final String? message;

  // Payment fields
  final double paymentAmount;
  final double ratePerSubject;
  final bool isSeparatePaymentForPractical;
  bool isPaid; // mutable — updated after payment success
  final Map<String, dynamic> moduleSettings;
  int practicalSubjectsCount;

  double get totalAmount => paymentAmount + (isSeparatePaymentForPractical ? practicalSubjectsCount * ratePerSubject : 0);

  ExamFormData({
    required this.rawModel,
    required this.subjectGroups,
    this.isRegular = true,
    this.examScheduleId,
    this.examRegistrationId,
    this.examScheduleName,
    this.studentName,
    this.programName,
    this.pageType = 'examForm',
    this.message,
    this.paymentAmount = 0,
    this.ratePerSubject = 0,
    this.isSeparatePaymentForPractical = false,
    this.isPaid = false,
    this.moduleSettings = const {},
    this.practicalSubjectsCount = 0,
  });
}
