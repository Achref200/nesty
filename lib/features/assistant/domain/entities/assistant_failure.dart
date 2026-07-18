sealed class AssistantFailure {
  final String debugMessage;
  const AssistantFailure(this.debugMessage);
}

class AssistantNetworkFailure extends AssistantFailure {
  const AssistantNetworkFailure() : super('network');
}

class AssistantServerFailure extends AssistantFailure {
  const AssistantServerFailure() : super('server');
}

class AssistantRateLimitFailure extends AssistantFailure {
  const AssistantRateLimitFailure() : super('rate_limit');
}

class AssistantBlockedFailure extends AssistantFailure {
  const AssistantBlockedFailure() : super('blocked');
}

class AssistantConfigFailure extends AssistantFailure {
  const AssistantConfigFailure() : super('config');
}
