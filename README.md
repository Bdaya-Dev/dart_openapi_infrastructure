A shared package for openapi clients to use that provides helpful abstractions.

## Features

- Expose `NetworkingClientBase` with a single `sendRequest` method.
- abstract all types of requests (including multipart) via `HttpRequestBase` and responses via `HttpResponseBase`
- `UndefinedWrapper<T>` which uses [extension types](https://dart.dev/language/extension-types) to wrap undefined values, which are different from nullable values
  - A nullable value can be serialized to a json `null`
  - An undefined value should NOT be included in a JSON map in the first place.

## Getting started

Depend on the package

```shell
dart pub add openapi_infrastructure
```