import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void setupLocator<T>(T instance) {
  locator.registerSingleton<T>(instance);
}