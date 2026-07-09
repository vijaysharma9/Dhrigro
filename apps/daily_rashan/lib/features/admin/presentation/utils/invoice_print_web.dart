// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> platformPrintHtml(String content, {required String title}) async {
  final blob = html.Blob([content], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final opened = html.window.open(url, '_blank');
  if (opened is! html.Window) {
    html.Url.revokeObjectUrl(url);
    throw StateError('Pop-up blocked. Allow pop-ups to print invoices.');
  }

  // Allow layout to settle before opening the print dialog.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  opened.print();
  html.Url.revokeObjectUrl(url);
}
