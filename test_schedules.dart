import 'dart:convert';
import 'dart:io';

void main() async {
  var c = HttpClient()..badCertificateCallback = (c,h,p)=>true;
  try {
    var req = await c.getUrl(Uri.parse('https://exam.fwu.edu.np/Result'));
    var res = await req.close();
    var html = await res.transform(utf8.decoder).join();
    var m = RegExp(r'var\s+model\s*=\s*(\{[\s\S]*?\});').firstMatch(html);
    if(m!=null) {
      print(m.group(1));
    } else {
      print('Not found');
    }
  } catch(e) {
    print(e);
  } finally {
    c.close();
  }
}
