import 'http_packets.dart';
import 'request.dart';

mixin HttpResponseMixin on HttpMetaPacketMixin, HttpPacketMixin {
  /// The HTTP status code for this response.
  int get statusCode;

  /// The reason phrase associated with the status code.
  String? get reasonPhrase;
}

/// A response is an http packet originating from a request.
abstract class HttpResponseBase
    with HttpMetaPacketMixin, HttpPacketMixin, HttpResponseMixin {
  const HttpResponseBase();

  HttpRequestBase get originalRequest;

  const factory HttpResponseBase.stream({
    required HttpRequestBase originalRequest,
    required Stream<List<int>> bodyBytesStream,
    required int statusCode,
    required String? reasonPhrase,
    required Map<String, String> headers,
    Map<String, dynamic> context,
  }) = StreamHttpResponse;
}

class StreamHttpResponse extends HttpResponseBase {
  const StreamHttpResponse({
    required this.bodyBytesStream,
    required this.originalRequest,
    required this.reasonPhrase,
    required this.statusCode,
    required this.headers,
    this.context = const {},
  });

  @override
  final Stream<List<int>> bodyBytesStream;

  @override
  final Map<String, dynamic> context;

  @override
  final Map<String, String> headers;

  @override
  final HttpRequestBase originalRequest;

  @override
  final String? reasonPhrase;

  @override
  final int statusCode;
}

// class MemoryHttpResponse extends HttpResponseBase implements MemoryHttpPacket {
//   const MemoryHttpResponse({
//     required this.bodyBytes,
//     required this.originalRequest,
//     required this.reasonPhrase,
//     required this.statusCode,
//     required this.headers,
//     this.context = const {},
//   });

//   @override
//   final List<int> bodyBytes;

//   @override
//   Stream<List<int>> get bodyBytesStream => Stream.value(bodyBytes);

//   @override
//   final Map<String, dynamic> context;

//   @override
//   final Map<String, String> headers;

//   @override
//   final HttpRequestBase originalRequest;

//   @override
//   final String? reasonPhrase;

//   @override
//   final int statusCode;
// }
