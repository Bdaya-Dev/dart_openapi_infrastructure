import 'package:http_parser/http_parser.dart';

extension MediaTypeExt on MediaType {
  MediaType fillDefaults() {
    MediaType res = this;
    if (res.type == '*') {
      res = res.change(
        type: 'application',
        subtype: 'octet-stream',
      );
    }
    if (res.subtype == '*') {
      switch (res.type) {
        case 'text':
          res = res.change(
            subtype: 'plain',
          );
        case 'application':
          res = res.change(
            subtype: 'octet-stream',
          );
        break;
      }
    }
    return res;
  }
}