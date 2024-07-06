import 'package:openapi_infrastructure/openapi_infrastructure.dart';
import 'package:test/test.dart';

void main() {
  group('UndefinedWrapper', () {
    final v1 = UndefinedWrapper("a");
    final v2 = UndefinedWrapper<String?>(null);
    final v3 = UndefinedWrapper(5);
    final v4 = UndefinedWrapper.undefined();
    test('isDefined', () {
      expect(v1.isDefined, isTrue);
      expect(v2.isDefined, isTrue);
      expect(v3.isDefined, isTrue);
      expect(v4.isDefined, isFalse);
    });
    test('isDefined without static typing', () {
      final vs = [v1, v2, v3, v4];
      expect(vs.map((e) => e.isDefined), [true, true, true, false]);
    });
    test(
      'wrong type casting',
      () {
        //while v1 is defined as a String, it's undefined as an integer.
        final wrongV1Type = (v1 as Object) as UndefinedWrapper<int>;
        expect(wrongV1Type.isDefined, isFalse);
        expect(wrongV1Type.valueOrNull, isNull);
      },
    );
  });
}
