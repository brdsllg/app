import 'package:app/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote update information is parsed correctly', () {
    final info = RemoteVersionInfo.fromJson({
      'version': '1.2.3',
      'buildNumber': 7,
      'releaseNotes': 'Test release',
      'downloadUrl': 'https://example.com/update.apk',
    });

    expect(info.version, '1.2.3');
    expect(info.buildNumber, 7);
    expect(info.releaseNotes, 'Test release');
    expect(info.downloadUrl, 'https://example.com/update.apk');
  });
}
