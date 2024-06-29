// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http_parser/http_parser.dart';
import 'package:openapi_infrastructure/openapi_infrastructure.dart';
import 'package:test/test.dart';

class MyNetworkingClient extends NetworkingClientBase {
  @override
  Future<HttpResponseBase> sendRequest(HttpRequestBase request) {
    // TODO: implement networking client using package:http or package:dio
    // you also got access to [request.context] if you want additional
    // customization.
    throw UnimplementedError();
  }
}

void main() async {
  final client = MyNetworkingClient();
  final endpoint = Uri.https('example.com', '/endpoint');
  //create a request
  final empty = HttpRequestBase.empty(
    url: endpoint,
    method: HttpRequestBase.getMethod,
  );
  final post = HttpRequestBase.memory(
    url: endpoint,
    method: HttpRequestBase.postMethod,
    bodyBytes: utf8.encode('hello world'),
    headers: {
      'content-type':
          MediaType('text', 'plain', {'charset': 'utf8'}).toString(),
    },
  );
  final postStream = HttpRequestBase.stream(
    url: endpoint,
    method: HttpRequestBase.postMethod,
    bodyBytesStream: Stream.value([1, 2, 3]),
    headers: {
      'content-type': MediaType('application', 'octet-stream').toString(),
    },
  );

  //you can also create arbitrary multipart requests
  final multipart = HttpRequestBase.multipart(
    url: endpoint,
    method: 'POST',
    parts: [
      // HttpPacketMixin.empty()
      //
      HttpPacketMixin.memory(
        bodyBytes: utf8.encode('hello world part'),
        headers: {
          'content-type':
              MediaType('text', 'plain', {'charset': 'utf8'}).toString(),
        },
      ),
      HttpPacketMixin.stream(
        bodyBytesStream: Stream.fromIterable([
          [1, 2, 3],
          [4, 5],
        ]),
        contentLength: 5,
        headers: {
          'content-type': MediaType('application', 'octet-stream').toString(),
        },
      ),
    ],
  );
  // you can also mutate the multipart request
  multipart.parts.add(HttpPacketMixin.empty());
  multipart.parts.add(HttpPacketMixin.stream(
    bodyBytesStream: Stream.value([1, 2, 3]),
  ));

  //you can also create multipart/form-data requests
  final file = XFile('test/test-file.txt');
  final formData = HttpRequestBase.formData(
    url: endpoint,
    method: HttpRequestBase.postMethod,
    fields: {
      'name': 'my name',
    },
    files: [
      MultiPartFormDataFileHttpPacket(
        field: 'files',
        fileName: file.name,
        fileSize: await file.length(),
        mimeType: file.mimeType,
        bodyBytesStream: file.openRead(),
      ),
    ],
  );
  // you can also mutate the formData request
  formData.fields['other-name'] = 'my other name';
  formData.files.add(MultiPartFormDataFileHttpPacket(
    field: 'files',
    fileName: 'whatever.bin',
    fileSize: 7,
    mimeType: 'application/octet-stream',
    bodyBytesStream: Stream.fromIterable(
      [
        [1, 2, 3],
        [4, 5, 6, 7],
      ],
    ),
  ));

  // send the request
  final response = await client.sendRequest(formData);
  //access the response
  prints(response.headers);
  final responseBodyAsString = utf8.decodeStream(response.bodyBytesStream);
}
