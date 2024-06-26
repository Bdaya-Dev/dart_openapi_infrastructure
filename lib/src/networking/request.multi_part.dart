part of 'request.dart';

mixin MultiPartHttpRequestMixin on HttpRequestMixin {
  List<HttpPacketMixin> get parts;
}

/// Serializes a multipart request body.
class MultiPartBodySerializer {
  MultiPartBodySerializer({
    String? boundary,
    List<HttpPacketMixin>? parts,
    Random? random,
  })  : parts = parts ?? [],
        random = random ??= Random(),
        boundary = boundary ?? getRandomBoundaryString(random);

  final String boundary;
  final Random random;

  final List<HttpPacketMixin> parts;

  static const int _boundaryLength = 70;

  static List<HttpPacketMixin> getFormDataParts({
    Map<String, String>? fields,
    List<MultiPartFormDataFileHttpPacket>? files,
  }) {
    return [
      ...?fields?.entries.map(
        (e) => MultiPartFormDataFieldHttpPacket(
            field: e.key, value: e.value, context: {}),
      ),
      ...?files,
    ];
  }

  Stream<List<int>> get bodyBytesStream async* {
    const line = [13, 10]; // \r\n
    final separator = utf8.encode('--$boundary\r\n');
    final close = utf8.encode('--$boundary--\r\n');

    for (final part in parts) {
      yield separator;
      yield utf8.encode(_headerForPart(part));
      yield* part.bodyBytesStream;
      yield line;
    }
    yield close;
  }

  int? get contentLength {
    var length = 0;
    for (var part in parts) {
      final partLen = part.contentLength;
      if (partLen == null) {
        return null;
      }
      length += '--'.length +
          boundary.length +
          '\r\n'.length +
          utf8.encode(_headerForPart(part)).length +
          partLen +
          '\r\n'.length;
    }

    return length + '--'.length + _boundaryLength + '--\r\n'.length;
  }

  /// Returns the header string for a part.
  ///
  /// The return value is guaranteed to contain only ASCII characters.
  String _headerForPart(HttpPacketMixin part) {
    var header =
        part.headers.entries.map((e) => '${e.key}: ${e.value}').join('\r\n');
    return '$header\r\n\r\n';
  }

  /// The total length of the multipart boundaries used when building the
  /// request body.
  ///
  /// According to http://tools.ietf.org/html/rfc1341.html, this can't be longer
  /// than 70.
  static String getRandomBoundaryString(Random random) {
    var prefix = 'dart-http-boundary-';
    var list = List<int>.generate(
        _boundaryLength - prefix.length,
        (index) =>
            _boundaryCharacters[random.nextInt(_boundaryCharacters.length)],
        growable: false);
    return '$prefix${String.fromCharCodes(list)}';
  }
}

// Mostly taken from https://github.com/dart-lang/http/blob/8c325b9ca33d878a86d69c5048a8e6e18379663c/pkgs/http/lib/src/multipart_request.dart
base class MultiPartHttpRequest extends HttpRequestBase
    with MultiPartHttpRequestMixin {
  MultiPartHttpRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    List<HttpPacketMixin>? parts,
    Map<String, dynamic>? context,
    Random? random,
  })  : _originalHeaders = headers ?? {},
        random = random ?? Random(),
        parts = parts ?? [],
        context = context ?? {};

  static MultiPartFormDataHttpRequest formData({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<MultiPartFormDataFileHttpPacket>? files,
    Map<String, dynamic>? context,
    Random? random,
  }) =>
      MultiPartFormDataHttpRequest(
        headers: headers,
        method: method,
        url: url,
        context: context,
        fields: fields,
        files: files,
        random: random,
      );

  final Random random;

  @override
  final Map<String, dynamic> context;

  @override
  final String method;

  @override
  final Uri url;

  final Map<String, String> _originalHeaders;
  CaseInsensitiveMap<String>? _processedHeaders;
  late MediaType _contentType;

  MultiPartBodySerializer? serializer;

  CaseInsensitiveMap<String> _processHeaders() {
    final res = CaseInsensitiveMap.from(_originalHeaders);
    final originalContentType = res[_kContentType] ?? 'multipart/mixed';
    var contentTypeParsed = MediaType.parse(originalContentType);
    if (!contentTypeParsed.parameters.containsKey(_kBoundary)) {
      //if no boundary is provided, use it.
      contentTypeParsed = contentTypeParsed.change(parameters: {
        ...contentTypeParsed.parameters,
        _kBoundary: MultiPartBodySerializer.getRandomBoundaryString(random),
      });
    }
    _contentType = contentTypeParsed;
    serializer = MultiPartBodySerializer(
      parts: parts,
      random: random,
      boundary: contentTypeParsed.parameters[_kBoundary],
    );

    res[_kContentType] = _contentType.toString();

    return res;
  }

  @override
  Map<String, String> get headers {
    return _processedHeaders ?? _processHeaders();
  }

  @override
  final List<HttpPacketMixin> parts;

  @override
  @nonVirtual
  Stream<List<int>> get bodyBytesStream {
    //process headers
    final _ = headers;
    //get result content type.
    return serializer?.bodyBytesStream ?? Stream.empty();
  }

  @override
  @nonVirtual
  int? get contentLength {
    //super.contentLength will also call _processHeaders
    final superContentLength = super.contentLength;
    if (superContentLength != null) {
      //user wants to override content length via headers.
      return superContentLength;
    }
    return serializer?.contentLength;
  }

  static const _kBoundary = 'boundary';
  static const _kContentType = 'content-type';
}

mixin _MultiPartFieldMixin {
  String get field;
}

class MultiPartFormDataFieldHttpPacket
    with HttpMetaPacketMixin, HttpPacketMixin, _MultiPartFieldMixin {
  const MultiPartFormDataFieldHttpPacket({
    required this.context,
    required this.field,
    required this.value,
  });

  @override
  Stream<List<int>> get bodyBytesStream => Stream.value(utf8.encode(value));

  @override
  final Map<String, dynamic> context;

  @override
  final String field;
  final String value;

  @override
  Map<String, String> get headers => {
        'content-disposition': 'form-data; name="${_browserEncode(field)}"',
        if (!isPlainAscii(value)) ...{
          'Content-Type': 'text/plain; charset=utf-8',
          'content-transfer-encoding': 'binary'
        },
      };
}

base class MultiPartFormDataFileHttpPacket extends StreamHttpPacket
    with HttpPacketMixin, _MultiPartFieldMixin {
  MultiPartFormDataFileHttpPacket({
    required this.field,
    required super.bodyBytesStream,
    super.context,
    String? mimeType,
    int? fileSize,
    String? fileName,
  }) : super(
          headers: {
            'Content-Type': mimeType ?? 'application/octet-stream',
            'content-disposition':
                _generateContentDisposition(field: field, fileName: fileName),
          },
          contentLength: fileSize,
        );

  static String _generateContentDisposition({
    required String field,
    required String? fileName,
  }) {
    var res = 'form-data; name="${_browserEncode(field)}"';
    if (fileName != null) {
      res += '; filename="${_browserEncode(fileName)}"';
    }
    return res;
  }

  @override
  final String field;
}

base class MultiPartFormDataHttpRequest extends MultiPartHttpRequest {
  MultiPartFormDataHttpRequest({
    required super.method,
    required super.url,
    Map<String, String>? fields,
    List<MultiPartFormDataFileHttpPacket>? files,
    super.headers,
    super.context,
    super.random,
  })  : files = files ?? [],
        fields = fields ?? {};

  final Map<String, String> fields;
  final List<MultiPartFormDataFileHttpPacket> files;

  @override
  List<HttpPacketMixin> get parts => MultiPartBodySerializer.getFormDataParts(
        fields: fields,
        files: files,
      );
}

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

final _newlineRegExp = RegExp(r'\r\n|\r|\n');
String _browserEncode(String value) {
  // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
  // field names and file names, but in practice user agents seem not to
  // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
  // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
  // characters). We follow their behavior.
  return value.replaceAll(_newlineRegExp, '%0D%0A').replaceAll('"', '%22');
}

/// All character codes that are valid in multipart boundaries.
///
/// This is the intersection of the characters allowed in the `bcharsnospace`
/// production defined in [RFC 2046][] and those allowed in the `token`
/// production defined in [RFC 1521][].
///
/// [RFC 2046]: http://tools.ietf.org/html/rfc2046#section-5.1.1.
/// [RFC 1521]: https://tools.ietf.org/html/rfc1521#section-4
const List<int> _boundaryCharacters = <int>[
  43,
  95,
  45,
  46,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  97,
  98,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  107,
  108,
  109,
  110,
  111,
  112,
  113,
  114,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122
];
