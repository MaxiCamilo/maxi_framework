import 'package:maxi_framework/maxi_framework.dart';
import 'package:test/test.dart';

void main() {
  test('Oration auto-generates deterministic token IDs by type and message', () {
    const fixed = FixedOration(message: 'Shared text');
    const flexible = FlexibleOration(message: 'Shared text', textParts: []);
    const manual = FixedOration(message: 'Shared text', tokenID: 'manual.id');

    expect(fixed.tokenID, Oration.buildAutomaticTokenID(typeKey: 't', message: 'Shared text'));
    expect(flexible.tokenID, Oration.buildAutomaticTokenID(typeKey: 'f', message: 'Shared text'));
    expect(fixed.tokenID, isNot(flexible.tokenID));
    expect(manual.tokenID, 'manual.id');
  });
}
