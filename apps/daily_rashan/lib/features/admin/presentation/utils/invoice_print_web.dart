// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> platformPrintHtml(String content, {required String title}) async {
  final printWindow = html.window.open('', '_blank');
  if (printWindow == null) {
    throw StateError('Pop-up blocked. Allow pop-ups to print invoices.');
  }

  printWindow.document!.write(content);
  printWindow.document!.title = title;
  printWindow.document!.close();

  // Allow layout to settle before opening the print dialog.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  printWindow.print();
}
