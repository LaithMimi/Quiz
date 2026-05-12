import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// DEV ONLY: accepts any SSL certificate on native platforms
http.Client createUnsafeClient() {
  final httpClient = HttpClient();
  httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(httpClient);
}
