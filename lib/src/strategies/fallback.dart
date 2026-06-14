import '../routing_context.dart';
import '../routing_strategy.dart';

/// Returns a fixed priority order of branch keys. The factory tries each in
/// turn until one succeeds (e.g. `['onDevice','cloud']` = PREFER_ON_DEVICE).
class FallbackStrategy implements RoutingStrategy {
  FallbackStrategy(this._order)
      : assert(_order.isNotEmpty, 'order must not be empty');

  final List<String> _order;

  @override
  List<String> route(RoutingContext context) => List.unmodifiable(_order);
}
