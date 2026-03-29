part of 'live_demo_bloc.dart';

@immutable
sealed class LiveDemoState {}

final class LiveDemoInitial extends LiveDemoState {}

final class LiveDemoConfiguring extends LiveDemoState {
 final String msg;

 LiveDemoConfiguring(this.msg);
}


final class LiveDemoReady extends LiveDemoState {}

final class LiveDemoError extends LiveDemoState {
 final String error;

 LiveDemoError(this.error);
}