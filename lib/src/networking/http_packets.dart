///A meta packet describes just headers.
mixin HttpMetaPacketMixin {
  Map<String, String> get headers;
  Map<String, dynamic> get context;

  /// Estimated content length of the request.
  /// The default implementation gets this value from the Content-Length header.
  int? get contentLength {
    final contentLenHeader = headers['Content-Length'];
    if (contentLenHeader == null) {
      return null;
    }
    return int.tryParse(contentLenHeader);
  }

  /// Gets the [headers] and appends [contentLength] to it if available.
  ///
  /// Note that this will override any Content-Length header that might have
  /// previously existed.
  Map<String, String> get headersWithContentLength {
    final contentLength = this.contentLength;
    return {
      ...headers,
      if (contentLength != null) 'Content-Length': contentLength.toString(),
    };
  }
}

/// An http packet is:
/// 1. Headers
/// 2. Body
///
/// You can create an arbitrary packet from [HttpPacketMixin.memory] or
/// [HttpPacketMixin.stream] static methods.
mixin HttpPacketMixin on HttpMetaPacketMixin {
  Stream<List<int>> get bodyBytesStream;

  static MemoryHttpPacket memory({
    required List<int> bodyBytes,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  }) {
    return MemoryHttpPacket(
      bodyBytes: bodyBytes,
      headers: headers,
      context: context,
    );
  }

  static StreamHttpPacket stream({
    required Stream<List<int>> bodyBytesStream,
    int? contentLength,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  }) {
    return StreamHttpPacket(
      bodyBytesStream: bodyBytesStream,
      headers: headers,
      context: context,
      contentLength: contentLength,
    );
  }

  static EmptyHttpPacket empty({
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  }) {
    return EmptyHttpPacket(
      context: context,
      headers: headers,
    );
  }
}

class MemoryHttpPacket with HttpMetaPacketMixin, HttpPacketMixin {
  final List<int> bodyBytes;
  @override
  final Map<String, dynamic> context;
  @override
  final Map<String, String> headers;

  MemoryHttpPacket({
    required this.bodyBytes,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  })  : context = context ?? {},
        headers = headers ?? {};

  @override
  Stream<List<int>> get bodyBytesStream => Stream.value(bodyBytes);

  @override
  int? get contentLength => bodyBytes.length;
}

base class StreamHttpPacket with HttpMetaPacketMixin, HttpPacketMixin {
  @override
  final Map<String, dynamic> context;
  @override
  final Map<String, String> headers;

  final int? _contentLength;
  @override
  int? get contentLength => _contentLength ?? super.contentLength;

  StreamHttpPacket({
    int? contentLength,
    required this.bodyBytesStream,
    Map<String, String>? headers,
    Map<String, dynamic>? context,
  })  : _contentLength = contentLength,
        headers = headers ?? {},
        context = context ?? {};

  @override
  final Stream<List<int>> bodyBytesStream;
}

class EmptyHttpPacket with HttpMetaPacketMixin, HttpPacketMixin {
  EmptyHttpPacket({
    Map<String, dynamic>? context,
    Map<String, String>? headers,
  })  : context = context ?? {},
        headers = headers ?? {};

  @override
  Stream<List<int>> get bodyBytesStream => Stream.empty();

  @override
  final Map<String, dynamic> context;

  @override
  final Map<String, String> headers;
}
