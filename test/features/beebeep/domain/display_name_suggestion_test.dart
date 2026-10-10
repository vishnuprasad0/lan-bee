import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/services/display_name_suggestion.dart';

void main() {
  group('suggestDisplayName', () {
    test('prefers the account name', () {
      expect(
        suggestDisplayName(userName: 'vishnu', hostName: 'Vishnus-MacBook-Pro'),
        'Vishnu',
      );
    });

    test('splits account names on dots and underscores', () {
      expect(suggestDisplayName(userName: 'vishnu.prasad'), 'Vishnu Prasad');
      expect(suggestDisplayName(userName: 'anil_kumar'), 'Anil Kumar');
    });

    test('falls back to the computer name for generic accounts', () {
      expect(
        suggestDisplayName(
          userName: 'Administrator',
          hostName: 'Vishnus-MacBook-Pro.local',
        ),
        'Vishnus MacBook Pro',
      );
    });

    test('returns null when nothing is usable, so the app asks', () {
      expect(suggestDisplayName(userName: null, hostName: 'localhost'), isNull);
      expect(
        suggestDisplayName(userName: 'mobile', hostName: 'iPhone'),
        isNull,
      );
      expect(suggestDisplayName(hostName: 'android-5f3a9c1d2e'), isNull);
      expect(suggestDisplayName(userName: '  ', hostName: ''), isNull);
    });
  });

  group('displayNameFromHost', () {
    test('ignores Windows default computer names', () {
      expect(displayNameFromHost('DESKTOP-4F2K9QH'), isNull);
      expect(displayNameFromHost('LAPTOP-AB12CD3'), isNull);
    });

    test('keeps chosen Windows computer names', () {
      expect(displayNameFromHost('RECEPTION-PC'), 'RECEPTION PC');
    });
  });
}
