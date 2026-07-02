import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pdf_viewer_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen>
    with TickerProviderStateMixin {
  static const _primary = Color(0xFF0F6E56);
  static const _accent = Color(0xFFEF9F27);
  static const _bg = Color(0xFFF1F5F9);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, Map<String, dynamic>> _categoryMeta = {
    'All':             {'icon': Icons.apps_rounded,              'color': const Color(0xFF475569)},
    'B.Ed.':           {'icon': Icons.school_rounded,             'color': const Color(0xFF0F6E56)},
    'P.B.Ed':          {'icon': Icons.menu_book_rounded,          'color': const Color(0xFF7C3AED)},
    'M.Ed.':           {'icon': Icons.auto_stories_rounded,       'color': const Color(0xFF1D4ED8)},
    'M.Phil./Ph.D.':   {'icon': Icons.workspace_premium_rounded,  'color': const Color(0xFFBE123C)},
    'M.Phil(Nepali)':  {'icon': Icons.translate_rounded,          'color': const Color(0xFFC2410C)},
    'M.Phil(TESOL)':   {'icon': Icons.language_rounded,           'color': const Color(0xFF0891B2)},
    'M.Phil(CPL)':     {'icon': Icons.psychology_rounded,         'color': const Color(0xFF6D28D9)},
    'B.TVTE':          {'icon': Icons.engineering_rounded,        'color': const Color(0xFF16A34A)},
    'General':         {'icon': Icons.description_rounded,        'color': const Color(0xFF64748B)},
  };

  static const List<Map<String, String>> _allSyllabuses = [
    // B.TVTE Program
    {'title': 'Curriculum of BTVTE First Semester, 2026',                           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1775814191-gsms.pdf',            'category': 'B.TVTE'},
    {'title': 'B.TVTE Procedure 2082',                                               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1770971525_dean_office.pdf',    'category': 'B.TVTE'},
    // B.Ed. 8th Sem
    {'title': 'B.Ed. 8th Semester Nepali Education Revised Syllabus 2082',          'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773643515_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 7th Sem
    {'title': 'B.Ed. 7th Semester Nepali Ed. Minor Revised course 2082',            'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773643604_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester Diversity in Education',                          'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535629_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester CSIT Revised Syllabus 2082',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535530_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester Health Education Revised Syllabus 2082',         'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535486_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester English Education Revised Syllabus 2082',        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535455_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester Mathematics Education Revised Syllabus 2082',    'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535415_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'B.Ed. 7th Semester Nepali Education Revised Syllabus 2082',         'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773535366_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 6th Sem
    {'title': 'CSIT in Education (367, 368, 369) 6th Semester',                    'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911497_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education (367, 368, 369) 6th Semester',        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911412_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Mathematics Education (367, 368, 369) 6th Semester',                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911315_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Education (367, 368, 369) 6th semester',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911217_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Education (367, 368, 369) 6th semester',                    'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911136_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Educational Development in Nepal (6th semester)',                    'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756910900_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Academic Calendar for 6th Semester, from 2082-05-18 (Fall)',        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756911807_dean_office.docx',   'category': 'B.Ed.'},
    {'title': 'Updated Grading System for Bachelor and Master level of FWU 2081',  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1756716470_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 5th Sem
    {'title': 'CSIT in Education Revised (5th Semester) 2081',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1740305986_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education Revised (5th Semester) 2081',         'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1740305909_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Mandatory courses (5th Semester - 352, 353) 2081',                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1742188261_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Math Education Revised (5th Semester) 2081',                        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1740305649_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Education Revised (5th Semester) 2081',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1740305483_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Education Revised (5th Semester) 2081',                      'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1743664365_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 4th Sem
    {'title': 'Mathematics Education (code 243, 244, 245) 4th sem 2081',           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1751525548_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'CSIT Education (code 243, 244, 245) 4th sem 2081',                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735401585_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education (code 243, 244, 245) 4th sem 2081',   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735401831_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Education (code 243, 244, 245) 4th sem 2081',                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735401625_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Education (code 243, 244, 245) 4th sem 2081',               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735401882_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Com. Professional Subjects (Code 243 and 244) 4th Sem. 2081',       'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1723177624_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 3rd Sem
    {'title': 'Professional Subjects (3rd semester) III',                           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1718645643_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Course Structure of BEd 3rd semester',                              'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1718645276_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education (3rd Semester) III',                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707504464_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Education (3rd Semester) III',                               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707504499_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Maths (3rd Semester) III',                                          'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707504582_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'CSIT (3rd Semester) III',                                           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707504614_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Education (3rd Semester) III',                              'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707504673_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'C. English (Third Semester) III',                                   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1707505679_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 2nd Sem
    {'title': 'CSIT in Education (CS. Ed. 121, 122 & 123) 2nd Sem',               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140733_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education (HP. Ed. 121 & 122) 2nd Sem',        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140622_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Major Mathematics Education (Math.Ed. 121 & 122) 2nd sem',         'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140673_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'ऐच्छिक नेपाली (Nep. Ed. 121 & 122) 2nd sem',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140249_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Major English (Eng. Ed. 121 & 122) 2nd sem',                       'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140394_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Developmental Psychology (Ed.Psy. 121) 2nd sem',                   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140462_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'अनिवार्य नेपाली २ (C.Nep. 120) 2nd sem',                         'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748141410_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Study Skills in English II (C. Eng.120) 2nd sem.',                 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140516_dean_office.pdf',    'category': 'B.Ed.'},
    // B.Ed. 1st Sem
    {'title': 'Population Education (Courses 111 and 112) 1st sem',               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1676189589_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'CSIT in Education (courses 111 and 112) 1st sem',                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1685279956_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health and Physical Education (Courses 111 and 112) 1st sem',      'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1685280003_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Mathematics Education (Courses 111 and 112) 1st sem',              'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1685280071_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Education (Courses 111 and 112) 1st sem',                   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1685280119_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Education (courses 111 and 112) 1st sem',                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1685280216_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Core courses (C.Eng. 110, C. Nep. 110 and Ed. 111) of 1st semester', 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1708687262_dean_office.pdf', 'category': 'B.Ed.'},
    // B.Ed. Cycles
    {'title': 'CSIT In Education Cycle',                                           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735399163_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Health Education Course Cycle',                                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1773909051_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Math Cycle',                                                        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1751961143_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'English Edu. Cycle',                                                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735399311_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Nepali Course Cycle',                                               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735399263_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Population Education Courses Cycle',                                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1735640267_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Seminar Guideline for Population 2079',                             'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1724311654_dean_office.pdf',    'category': 'B.Ed.'},
    {'title': 'Population Education II semester',                                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1748140923_dean_office.pdf',    'category': 'B.Ed.'},
    // P.B.Ed
    {'title': 'Professional Bachelor of Education (PBEd) 1st sem. COURSES',       'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1750224246_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Compulsory Subjects (421, 422 & 423) for 2nd Semester',            'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754075371_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'English Education (424 & 425) for PBEd 2nd Semester',              'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754817770_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Mathematics Education (424 & 425) for 2nd Semester',               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754075930_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Nepali Education (424 & 425) for PBEd 2nd Semester',               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754076554_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Science Education (424 & 425) for PBEd 2nd Semester',              'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754075648_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Social Science Education (424 & 425) for PBEd 2nd Semester',       'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754076273_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Business Studies Education (424 & 425) for PBEd 2nd semester',     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754075518_dean_office.pdf',    'category': 'P.B.Ed'},
    {'title': 'Health and Physical Education (425) for 2nd Sem (Social Group)',   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1754076431_dean_office.pdf',    'category': 'P.B.Ed'},
    // M.Ed.
    {'title': 'Thesis Writing Guideline In Nepali',                                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1724318057_dean_office.pdf',    'category': 'M.Ed.'},
    {'title': 'Thesis Writing Guideline 2079 (R) in English',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1724317963_dean_office.pdf',    'category': 'M.Ed.'},
    // M.Phil./Ph.D.
    {'title': 'Guidelines for M.Phil/PhD: Thesis Structure and Format, 2022 in Nepali', 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1720072469_dean_office.pdf', 'category': 'M.Phil./Ph.D.'},
    {'title': 'Guidelines for MPhil/PhD: Thesis Structure and Format, 2022',      'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1720072380_dean_office.pdf',    'category': 'M.Phil./Ph.D.'},
    // M.Phil (Nepali)
    {'title': 'Course Structure of MPhil in Nepali Edu',                          'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706414077_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    {'title': 'Syllabus of MPhil in Nepali Edu 2nd sem',                          'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706414000_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    {'title': 'साहित्यका विधा सिद्धान्त र शिक्षण (६१२) प्रथम सत्र',            'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397957_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    {'title': 'रस सिद्धान्त (६१३) प्रथम सत्र',                                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690398016_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    {'title': 'प्राज्ञिक लेखन (६११) प्रथम सत्र',                                'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397734_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    {'title': 'भाषा, साहित्य र दर्शन (६१२) प्रथम सत्र',                        'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397608_dean_office.pdf',    'category': 'M.Phil(Nepali)'},
    // M.Phil (TESOL)
    {'title': 'Course Structure of MPhil TESOL',                                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706413900_dean_office.pdf',    'category': 'M.Phil(TESOL)'},
    {'title': 'Syllabus of MPhil in TESOL 2nd sem',                               'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706413844_dean_office.pdf',    'category': 'M.Phil(TESOL)'},
    {'title': 'English Language Pedagogies and Practices (Eng/TESOL 614) 1st Sem','url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397303_dean_office.pdf',    'category': 'M.Phil(TESOL)'},
    // M.Phil (CPL)
    {'title': 'Syllabus of MPhil in CPL 2nd sem',                                 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706413762_dean_office.pdf',    'category': 'M.Phil(CPL)'},
    {'title': 'Course Structure of MPhil in CPL',                                 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1706413663_dean_office.pdf',    'category': 'M.Phil(CPL)'},
    {'title': 'Curriculum and Testing: Theory and Practices (CPL 614) 1st sem',   'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397424_dean_office.pdf',    'category': 'M.Phil(CPL)'},
    {'title': 'Advanced Academic Writing (CPL/TESOL/Eng. 613) 1st Sem',           'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690397108_dean_office.pdf',    'category': 'M.Phil(CPL)'},
    {'title': 'Advanced Research Methodology (CPL Ed./TESOL/ENG 612) 1st sem',    'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690396923_dean_office.pdf',    'category': 'M.Phil(CPL)'},
    {'title': 'Eastern and Western Philosophical Traditions (CPL Ed./TESOL/ENG 611) 1st Sem', 'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1690396784_dean_office.pdf', 'category': 'M.Phil(CPL)'},
    // General
    {'title': 'Blended Learning Guidelines 2082',                                  'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1770973931_dean_office.pdf',    'category': 'General'},
    {'title': 'Practical Procedure 2082 (For B.Ed. & M.Ed.)',                     'url': 'https://facultyeducation.fwu.edu.np/assets/uploads/syllabus/syllabus-1767518937_dean_office.pdf',    'category': 'General'},
  ];

  final List<String> _tabCategories = [
    'All', 'B.Ed.', 'P.B.Ed', 'M.Ed.', 'M.Phil./Ph.D.',
    'M.Phil(Nepali)', 'M.Phil(TESOL)', 'M.Phil(CPL)', 'B.TVTE', 'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCategories.length, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _catColor(String cat) =>
      (_categoryMeta[cat]?['color'] as Color?) ?? const Color(0xFF475569);
  IconData _catIcon(String cat) =>
      (_categoryMeta[cat]?['icon'] as IconData?) ?? Icons.description_rounded;

  List<Map<String, String>> _getFiltered(String category) {
    final base = category == 'All'
        ? _allSyllabuses
        : _allSyllabuses.where((s) => s['category'] == category).toList();
    if (_searchQuery.isEmpty) return base;
    return base.where((s) => s['title']!.toLowerCase().contains(_searchQuery)).toList();
  }

  void _openViewer(Map<String, String> item) {
    final cat = item['category']!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url: item['url']!,
          title: item['title']!,
          category: cat,
          categoryColor: _catColor(cat),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabCategories.map((cat) => _buildTabContent(cat)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool collapsed) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4D3C), Color(0xFF0F6E56), Color(0xFF1B9677)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Academic Syllabuses',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Faculty of Education • Far Western University',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_allSyllabuses.length} PDFs',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: collapsed
          ? Text('Academic Syllabuses',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white))
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search syllabuses...',
          hintStyle: GoogleFonts.outfit(color: _textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _textSecondary, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _primary,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _tabCategories.map((cat) {
          final count = cat == 'All'
              ? _allSyllabuses.length
              : _allSyllabuses.where((s) => s['category'] == cat).length;
          final color = _catColor(cat);
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_catIcon(cat), size: 13),
                const SizedBox(width: 5),
                Text(cat),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(String category) {
    final items = _getFiltered(category);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: _textSecondary.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('No syllabuses found',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w600, color: _textSecondary)),
            Text('Try a different search term',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: _textSecondary.withOpacity(0.65))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildCard(items[index]),
    );
  }

  Widget _buildCard(Map<String, String> item) {
    final cat = item['category']!;
    final color = _catColor(cat);
    final catIcon = _catIcon(cat);
    final isPdf = !item['url']!.endsWith('.docx');
    final fileType = isPdf ? 'PDF' : 'DOCX';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openViewer(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header banner ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catIcon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            'Faculty of Education • FWU',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // File type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPdf ? Colors.red.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                            size: 12,
                            color: isPdf ? Colors.red.shade600 : Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fileType,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isPdf ? Colors.red.shade600 : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Title ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Text(
                  item['title']!,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.45,
                  ),
                ),
              ),

              // ── Action row ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Row(
                  children: [
                    // View button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'View',
                        color: _primary,
                        filled: true,
                        onTap: () => _openViewer(item),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Download button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        color: color,
                        filled: false,
                        onTap: () => _openViewerAndDownload(item),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openViewerAndDownload(Map<String, String> item) {
    final cat = item['category']!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url: item['url']!,
          title: item['title']!,
          category: cat,
          categoryColor: _catColor(cat),
          autoDownload: true,
        ),
      ),
    );
  }
}

// ── Reusable action button ───────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
