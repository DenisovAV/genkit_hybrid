import '../routing_context.dart';
import '../routing_strategy.dart';

/// Picks a single branch using a developer-supplied function.
///
/// The universal escape hatch for any app-specific rule (privacy, cost,
/// user tier, etc.) that the package cannot compute itself.
class PreRoutingStrategy implements RoutingStrategy {
  PreRoutingStrategy(this._select);

  final String Function(RoutingContext context) _select;

  @override
  List<String> route(RoutingContext context) => [_select(context)];
}
