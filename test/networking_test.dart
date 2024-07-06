import 'dart:convert';
import 'dart:math';

import 'package:openapi_infrastructure/openapi_infrastructure.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  group('Multipart', () {
    test(
      'creation',
      () async {
        final request = MultiPartHttpRequest(
          random: Random(1234),
          headers: {'hello': 'world', 'Content-Type': 'multipart/mixed'},
          parts: [
            HttpPacketMixin.memory(
              bodyBytes: utf8.encode('First part'),
              headers: {
                'Content-Type': 'text/plain',
              },
            ),
            HttpPacketMixin.memory(
              bodyBytes: utf8.encode('{"second": "part"}'),
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          ],
          method: HttpRequestBase.postMethod,
          url: Uri.https('example.com', '/path'),
        );

        final headers = request.headers;
        final bodyBytes =
            (await request.bodyBytesStream.toList()).flattened.toList();

        expect(headers, containsPair('hello', 'world'));
        expect(
          headers,
          containsPair('content-type', startsWith('multipart/mixed;')),
        );
        final decoded = utf8.decode(bodyBytes);
        expect(request.contentLength, decoded.length);
        expect(
          decoded,
          startsWith(
            '--dart-http-boundary-CTxFzmZ13GcHa-pjnbNNvh3CMGfl39.SX1nTDZ5qQxRRlMqKMMw\r\n',
          ),
        );
        expect(decoded, contains('Content-Type: text/plain'));
        expect(decoded, contains('First part'));
        expect(decoded, contains('Content-Type: application/json'));
        expect(decoded, contains('{"second": "part"}'));
        expect(
          decoded,
          endsWith(
            '--dart-http-boundary-CTxFzmZ13GcHa-pjnbNNvh3CMGfl39.SX1nTDZ5qQxRRlMqKMMw--\r\n',
          ),
        );
      },
    );
    group(
      'form-data',
      () {
        test('creation', () async {
          final file = XFile('test/test-file.txt');
          final request = MultiPartHttpRequest.formData(
            random: Random(1234),
            headers: {},
            method: HttpRequestBase.postMethod,
            url: Uri.https('example.com', '/path'),
          );
          request.fields['my-field'] = 'world';
          request.files.add(await createPartFromXFile('my-files', file));

          final body = await utf8.decodeStream(request.bodyBytesStream);
          final fileContent = await file.readAsString(encoding: utf8);
          expect(body, contains(fileContent));
        });
      },
    );
  });
}

Future<MultiPartFormDataFileHttpPacket> createPartFromXFile(
  String field,
  XFile file,
) async {
  return MultiPartFormDataFileHttpPacket(
    bodyBytesStream: file.openRead(),
    field: field,
    fileName: file.name,
    fileSize: await file.length(),
    mimeType: file.mimeType,
  );
}
