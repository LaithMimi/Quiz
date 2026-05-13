import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentService {
  // Let the user pick a file and extract the text from it
  // Returns null if the user cancels or the file cannot be read
  static Future<String?> pickAndExtractText() async {
    // Open the file picker and only allow PDF and text files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
      withData: true,
    );

    // Return null if the user cancelled
    if (result == null) {
      return null;
    }

    if (result.files.isEmpty) {
      return null;
    }

    PlatformFile file = result.files.first;

    // Return null if the file has no data
    if (file.bytes == null) {
      return null;
    }

    String extension = file.extension?.toLowerCase() ?? '';

    // Use the right reader depending on the file type
    if (extension == 'pdf') {
      return _extractPdfText(file.bytes!);
    } else {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }
  }

  // Extract plain text from a PDF file
  static String _extractPdfText(Uint8List bytes) {
    PdfDocument document = PdfDocument(inputBytes: bytes);
    PdfTextExtractor extractor = PdfTextExtractor(document);
    String text = extractor.extractText();

    // Free the memory used by the PDF document
    document.dispose();

    return text;
  }
}
