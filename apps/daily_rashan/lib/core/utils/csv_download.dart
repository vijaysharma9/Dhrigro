import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart' as platform;

Future<void> downloadCsv(String filename, String csv) async {
  if (kIsWeb) {
    await platform.platformDownloadCsv(filename, csv);
    return;
  }
  await Clipboard.setData(ClipboardData(text: csv));
}
