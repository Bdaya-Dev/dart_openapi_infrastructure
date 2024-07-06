## 2.0.1

- fix: `UndefinedWrapper` type checking.

## 2.0.0

- feat!: Introduce `SyncMultiPartBodySerializer` and change `MultiPartBodySerializer` to accept a stream of parts.

## 1.1.2

- Improved multi part form field request handling

## 1.0.2

- Added `MultiPartBodySerializer`.
  - Has static method `getFormDataParts`, which uses the newly added `MultiPartFormDataFileHttpPacket` and `MultiPartFormDataFieldHttpPacket`.
  - Has `Stream<List<int>> get bodyBytesStream` and `int? get contentLength` for multipart requests.
 
## 1.0.1

- Added `fillDefaults()` extension on `MediaType` from `package:http_parser`

## 1.0.0

- Initial version.
