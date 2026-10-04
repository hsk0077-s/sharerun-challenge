import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/features/shop/donation_match_line.dart';

void main() {
  test('company won is shown with the user and not as a receipt', () {
    final line = donationMatchContributionLine(
      sponsorName: 'SRC',
      contributorName: '러너상',
      companyWon: 1000,
    );

    expect(line, 'SRC 명의 1,000원 · 러너상 기여');
    expect(line.contains('영수증'), isFalse);
    expect(
      donationMatchContributionLine(
        sponsorName: 'SRC',
        contributorName: '',
        companyWon: 0,
      ),
      isEmpty,
    );
  });

  test('a month sums company won under the latest sponsor name', () {
    const entries = [
      DonationMatchEntry(
        sponsorName: 'SRC',
        contributorName: '러너상',
        companyWon: 1000,
        monthKey: '2026-10',
        valueSpent: 100,
      ),
      DonationMatchEntry(
        sponsorName: 'SRC',
        contributorName: '러너상',
        companyWon: 1000,
        monthKey: '2026-09',
        valueSpent: 100,
      ),
    ];

    expect(
      donationMatchSummary(entries, '2026-10'),
      'SRC 명의 1,000원 · 러너상 기여',
    );
    expect(donationMatchSummary(entries, '2026-11'), isEmpty);
    expect(
      DonationMatchEntry.fromDoc(const {
        'type': 'donation_match',
        'sponsorName': 'SRC',
        'contributorName': '러너상',
        'companyWon': 1000,
        'monthKey': '2026-10',
        'valueAmount': -100,
        'receiptIssued': false,
      })?.valueSpent,
      100,
    );
  });
}
