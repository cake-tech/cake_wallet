abstract class ConnectionToNodeState {}

class InitialConnectionState extends ConnectionToNodeState {}

class IsConnectingState extends ConnectionToNodeState {}

class ConnectedSuccessfullyState extends ConnectionToNodeState {
  ConnectedSuccessfullyState(this.isAlive);

  final bool isAlive;
}

class FailureConnectedState extends ConnectionToNodeState {
  FailureConnectedState(this.error);

  final String error;
}