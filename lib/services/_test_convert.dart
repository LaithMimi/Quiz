import 'dart:convert';
void testConvert() {
  // Test json.dart exports
  json.encode({'a': 1});
  // Test utf.dart exports  
  utf8.encode('hello');
  // Test base64.dart exports
  base64.encode([1, 2, 3]);
}
