class StudentInfo {
  final String fullName;
  final String gender;
  final String dob;
  final String ethnicity;
  final String contact;
  final String email;
  final String academicYear;
  final String registrationNo;
  final String faculty;
  final String college;
  final String address;
  final String bloodGroup;
  final String nationality;
  final String religion;
  final String category;
  final String? photo;
  final String? signature;

  StudentInfo({
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.ethnicity,
    required this.contact,
    required this.email,
    required this.academicYear,
    required this.registrationNo,
    required this.faculty,
    required this.college,
    required this.address,
    required this.bloodGroup,
    required this.nationality,
    required this.religion,
    required this.category,
    this.photo,
    this.signature,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      fullName: json['fullName'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      ethnicity: json['ethnicity'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      academicYear: json['academicYear'] ?? '',
      registrationNo: json['registrationNo'] ?? '',
      faculty: json['faculty'] ?? '',
      college: json['college'] ?? '',
      address: json['address'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      nationality: json['nationality'] ?? '',
      religion: json['religion'] ?? '',
      category: json['category'] ?? '',
      photo: json['photo'],
      signature: json['signature'],
    );
  }
}
