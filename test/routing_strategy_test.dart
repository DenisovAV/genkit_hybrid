import 'package:genkit/genkit.dart';
import 'package:genkit_hybrid/src/routing_context.dart';
import 'package:test/test.dart';

void main() {
  test('RoutingContext exposes request, branchKeys and isStreaming', () {
    final request = ModelRequest(messages: []);
    const ctx = RoutingContext(
      request: null,
      branchKeys: {'onDevice', 'cloud'},
      isStreaming: true,
    );
    expect(ctx.branchKeys, contains('cloud'));
    expect(ctx.isStreaming, isTrue);
    expect(ctx.request, isNull);

    final ctx2 = RoutingContext(
      request: request,
      branchKeys: const {'a'},
      isStreaming: false,
    );
    expect(ctx2.request, same(request));
    expect(ctx2.isStreaming, isFalse);
  });
}
