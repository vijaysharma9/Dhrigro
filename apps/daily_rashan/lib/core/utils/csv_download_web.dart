// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> platformDownloadCsv(String filename, String csv) async {
  final bytes = html.Blob([csv], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}
