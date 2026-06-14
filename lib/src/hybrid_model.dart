import 'package:genkit/genkit.dart';
import 'package:genkit/plugin.dart';

import 'routing_context.dart';
import 'routing_strategy.dart';

/// Branch key for the on-device model in the binary façade.
const String kOnDevice = 'onDevice';

/// Branch key for the cloud model in the binary façade.
const String kCloud = 'cloud';

/// Builds a hybrid [Model] that routes each request to one of [branches]
/// according to [strategy]. The result is an ordinary [Model]: callers use it
/// via `ai.generate(model: theResult)` exactly like any other model.
Model hybridModel({
  required Map<String, Model> branches,
  required RoutingStrategy strategy,
}) {
  if (branches.isEmpty) {
    throw ArgumentError.value(branches, 'branches', 'must not be empty');
  }
  return Model(
    name: 'hybrid',
    fn: (request, context) async {
      final order = strategy.route(RoutingContext(
        request: request,
        branchKeys: branches.keys.toSet(),
        isStreaming: context.streamingRequested,
      ));

      if (order.isEmpty) {
        throw GenkitException(
          'RoutingStrategy returned no branch to route to.',
          status: StatusCodes.FAILED_PRECONDITION,
        );
      }
      for (final key in order) {
        if (!branches.containsKey(key)) {
          throw GenkitException(
            'RoutingStrategy returned unknown branch key "$key". '
            'Available: ${branches.keys.join(', ')}.',
            status: StatusCodes.FAILED_PRECONDITION,
          );
        }
      }

      // Blocking path (streaming added in a later task).
      for (var i = 0; i < order.length; i++) {
        final key = order[i];
        final isLast = i == order.length - 1;
        try {
          return await branches[key]!.fn(request, context);
        } catch (_) {
          if (isLast) rethrow;
        }
      }
      throw StateError('unreachable');
    },
  );
}

/// Binary façade over [hybridModel] for the common on-device/cloud case.
Model hybridModelOnDeviceCloud({
  required Model onDevice,
  required Model cloud,
  required RoutingStrategy strategy,
}) {
  return hybridModel(
    branches: {kOnDevice: onDevice, kCloud: cloud},
    strategy: strategy,
  );
}
