// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> platformPrintHtml(String content, {required String title}) async {
  final opened = html.window.open('', '_blank');
  if (opened is! html.Window) {
    throw StateError('Pop-up blocked. Allow pop-ups to print invoices.');
  }

  opened.document!.write(content);
  opened.document!.title = title;
  opened.document!.close();

  // Allow layout to settle before opening the print dialog.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  opened.print();
}
