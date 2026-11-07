import 'package:allo_coursier_app/services/notification_api_service.dart';
import 'package:allo_coursier_app/services/notification_inbox.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart';

void main() {
  Map<String, dynamic> note(String id, {bool read = false}) => {
        'id': id,
        'title': 'Colis $id',
        'body': 'Mise à jour',
        'isRead': read,
        'sentAt': '2026-10-30T10:00:00.000Z',
        'orderId': '42',
      };

  test('a later poll announces only notifications that just arrived', () async {
    var calls = 0;
    final api = createMockApi((options) {
      calls += 1;
      final rows = calls == 1 ? [note('1', read: true)] : [note('2'), note('1', read: true)];
      return Response(requestOptions: options, statusCode: 200, data: ok(rows));
    });
    final arrived = <String>[];
    final inbox = NotificationInbox(
      service: NotificationApiService(api),
      onArrived: (item) => arrived.add(item.id),
    );

    await inbox.refresh();
    expect(arrived, isEmpty);
    expect(inbox.unread, 0);

    await inbox.refresh();
    expect(arrived, ['2']);
    expect(inbox.unread, 1);
    expect(inbox.items.first.id, '2');
  });
}
