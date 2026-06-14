import 'package:genkit/genkit.dart';
import 'package:genkit_hybrid/src/routing_context.dart';
import 'package:genkit_hybrid/src/routing_strategy.dart';
import 'package:genkit_hybrid/src/strategies/connectivity.dart';
import 'package:genkit_hybrid/src/strategies/fallback.dart';
import 'package:genkit_hybrid/src/strategies/input_size.dart';
import 'package:genkit_hybrid/src/strategies/pre_routing.dart';
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

  test('RoutingStrategy can be implemented and returns ordered keys', () {
    final s = _ConstStrategy(['cloud', 'onDevice']);
    const ctx = RoutingContext(
      request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: false,
    );
    expect(s.route(ctx), ['cloud', 'onDevice']);
  });

  test('PreRoutingStrategy wraps a function and returns single key', () {
    final s = PreRoutingStrategy((c) => c.isStreaming ? 'cloud' : 'onDevice');
    const stream = RoutingContext(request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: true);
    const block = RoutingContext(request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: false);
    expect(s.route(stream), ['cloud']);
    expect(s.route(block), ['onDevice']);
  });

  test('FallbackStrategy returns its fixed order regardless of context', () {
    final s = FallbackStrategy(['onDevice', 'cloud']);
    const ctx = RoutingContext(request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: false);
    expect(s.route(ctx), ['onDevice', 'cloud']);
  });

  test('ConnectivityStrategy routes by online/offline', () {
    var online = true;
    final s = ConnectivityStrategy(
      isOnline: () => online,
      online: 'cloud',
      offline: 'onDevice',
    );
    const ctx = RoutingContext(request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: false);
    expect(s.route(ctx), ['cloud']);
    online = false;
    expect(s.route(ctx), ['onDevice']);
  });

  test('InputSizeStrategy routes by total prompt char length', () {
    final s = InputSizeStrategy(threshold: 10, small: 'onDevice', large: 'cloud');
    final shortReq = ModelRequest(messages: [
      Message(role: Role.user, content: [TextPart(text: 'hi')]),
    ]);
    final longReq = ModelRequest(messages: [
      Message(role: Role.user, content: [TextPart(text: 'this is a long prompt')]),
    ]);
    RoutingContext ctx(ModelRequest r) =>
        RoutingContext(request: r, branchKeys: {'onDevice', 'cloud'}, isStreaming: false);
    expect(s.route(ctx(shortReq)), ['onDevice']);
    expect(s.route(ctx(longReq)), ['cloud']);
  });

  test('InputSizeStrategy treats null request as size 0 (small)', () {
    final s = InputSizeStrategy(threshold: 10, small: 'onDevice', large: 'cloud');
    const ctx = RoutingContext(request: null, branchKeys: {'onDevice', 'cloud'}, isStreaming: false);
    expect(s.route(ctx), ['onDevice']);
  });
}

class _ConstStrategy implements RoutingStrategy {
  _ConstStrategy(this.keys);
  final List<String> keys;
  @override
  List<String> route(RoutingContext context) => keys;
}
