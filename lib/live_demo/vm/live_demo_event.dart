part of 'live_demo_bloc.dart';

@immutable
sealed class LiveDemoEvent {}

final class ConnectionRequested extends LiveDemoEvent {
  final String host;
  final int port;

  ConnectionRequested({required this.host, required this.port});
}


final class PageReset extends LiveDemoEvent {


}