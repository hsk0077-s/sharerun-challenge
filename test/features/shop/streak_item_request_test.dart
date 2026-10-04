import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/api/api_exception.dart';
import 'package:share_run_challenge/features/shop/shop_request_ids.dart';
import 'package:share_run_challenge/features/shop/streak_item_message.dart';

void main() {
  test('a retryable failure reuses the request id', () {
    final ids = ShopRequestIds();
    var n = 0;
    String mint() => 'req-${n++}-aaaa';

    final first = ids.begin('buy:cpr', mint: mint);
    expect(first, 'req-0-aaaa');
    ids.failed('buy:cpr', first, retryable: true);
    expect(ids.begin('buy:cpr', mint: mint), first);

    ids.succeed('buy:cpr');
    expect(ids.begin('buy:cpr', mint: mint), 'req-1-aaaa');

    final rejected = ids.begin('use:guard', mint: mint);
    ids.failed('use:guard', rejected, retryable: false);
    expect(ids.begin('use:guard', mint: mint), isNot(rejected));
  });

  test('minted ids fit the server request id', () {
    final id = mintShopRequestId();
    expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(id), isTrue);
  });

  test('streak item errors stay in Korean', () {
    expect(
      streakItemMessage(
        const ApiException(statusCode: 400, detail: 'Safeguard hold cap is 2.'),
        fallback: 'fallback',
      ),
      '세이프가드는 최대 2개까지 보유할 수 있습니다.',
    );
    expect(
      streakItemMessage(
        const ApiException(statusCode: 400, detail: 'CPR monthly use cap is 2.'),
        fallback: 'fallback',
      ),
      '심폐소생권은 한 달에 2번까지 사용할 수 있습니다.',
    );
    expect(
      streakItemMessage(
        const ApiException(statusCode: 400, detail: 'No item to use.'),
        fallback: '보유량이 없습니다.',
      ),
      '보유량이 없습니다.',
    );
  });
}