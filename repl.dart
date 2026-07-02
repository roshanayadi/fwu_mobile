import 'dart:io';

void main() {
  var d = File('f:/development/vote/newapp/fwu_mobile/lib/screens/details_screen.dart').readAsStringSync();
  var r = File('f:/development/vote/newapp/fwu_mobile/temp_replacement.txt').readAsStringSync();
  var s = d.indexOf('  Widget _buildResult(ExamResult result) {');
  var e = d.indexOf('  Widget _buildAvatar(');
  print('Start: \${s}, End: \${e}');
  if (s != -1 && e != -1) {
    File('f:/development/vote/newapp/fwu_mobile/lib/screens/details_screen.dart')
        .writeAsStringSync(d.substring(0, s) + r + '\n' + d.substring(e));
    print('Done!');
  } else {
    print('Not found');
  }
}

