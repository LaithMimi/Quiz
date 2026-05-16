import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentService {
  static Future<String?> pickAndExtractText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
      withData: true,
    );

    //return null if the user cancelled
    if (result == null || result.files.isEmpty) {
      return null;
    }

    PlatformFile file = result.files.first;

    //return null if the file has no data
    if (file.bytes == null) return null;

    String extension = file.extension?.toLowerCase() ?? '';

    if (extension == 'pdf') {
      return _extractPdfText(file.bytes!);
    } else {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }
  }

  static String _extractPdfText(Uint8List bytes) {
    PdfDocument document = PdfDocument(inputBytes: bytes);
    PdfTextExtractor extractor = PdfTextExtractor(document);
    String text = extractor.extractText();
    document.dispose(); // free PDF memory
    return text;
  }
}
