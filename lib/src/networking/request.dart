import 'dart:convert';
import 'dart:math';
import 'package:http_parser/http_parser.dart';
import 'http_packets.dart';

part 'request.multi_part.dart';

mixin HttpRequestMixin on HttpMetaPacketMixin, HttpPacketMixin {
  Uri get url;
  String get method;
}

/// A request, is an http packet directed to a url.
abstract class HttpRequestBase
    with HttpMetaPacketMixin, HttpPacketMixin, HttpRequestMixin {
  const HttpRequestBase();

  static const getMethod = 'GET';
  static const postMethod = 'POST';
  static const putMethod = 'PUT';
  static const patchMethod = 'PATCH';
  static const deleteMethod = 'DELETE';
  static const headMethod = 'HEAD';

  @override
  Uri get url;
  @override
  String get method;

  factory HttpRequestBase.memory({
    required Uri url,
    required String method,
    required List<int> bodyBytes,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  }) = MemoryHttpRequest;

  factory HttpRequestBase.stream({
    required Uri url,
    required String method,
    required Stream<List<int>> bodyBytesStream,
    int? contentLength,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  }) = StreamHttpRequest;

  static MultiPartHttpRequest multipart({
    required Uri url,
    required String method,
    required List<HttpPacketMixin> parts,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
    Random? random,
  }) =>
      MultiPartHttpRequest(
        method: method,
        url: url,
        context: context,
        headers: headers,
        parts: parts,
        random: random,
      );

  static MultiPartFormDataHttpRequest formData({
    required Uri url,
    required String method,
    Map<String, String>? fields,
    List<MultiPartFileHttpPacket>? files,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
    Random? random,
  }) =>
      MultiPartFormDataHttpRequest(
        url: url,
        method: method,
        context: context,
        fields: fields,
        files: files,
        headers: headers,
        random: random,
      );

  factory HttpRequestBase.empty({
    required Uri url,
    required String method,
    Map<String, String> headers,
    Map<String, dynamic> context,
  }) = EmptyHttpRequest;
}

base class StreamHttpRequest extends HttpRequestBase {
  @override
  final Stream<List<int>> bodyBytesStream;

  @override
  final Map<String, dynamic> context;

  @override
  final Map<String, String> headers;

  final int? _contentLength;
  @override
  int? get contentLength => _contentLength ?? super.contentLength;

  @override
  final Uri url;
  @override
  final String method;

  StreamHttpRequest({
    required this.bodyBytesStream,
    required this.url,
    required this.method,
    int? contentLength,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  })  : _contentLength = contentLength,
        headers = headers ?? {},
        context = context ?? {};
}

class MemoryHttpRequest extends HttpRequestBase {
  MemoryHttpRequest({
    required this.method,
    required this.url,
    required this.bodyBytes,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  })  : headers = headers ?? {},
        context = context ?? {};

  final List<int> bodyBytes;

  @override
  Stream<List<int>> get bodyBytesStream => Stream.value(bodyBytes);

  @override
  final Map<String, String> headers;

  @override
  final Uri url;
  @override
  final String method;

  @override
  final Map<String, dynamic> context;

  @override
  int? get contentLength => bodyBytes.length;
}

class EmptyHttpRequest extends HttpRequestBase {
  EmptyHttpRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  })  : headers = headers ?? {},
        context = context ?? {};

  @override
  Stream<List<int>> get bodyBytesStream => Stream.empty();

  @override
  final Map<String, String> headers;

  @override
  final Uri url;
  @override
  final String method;

  @override
  final Map<String, dynamic> context;
}
