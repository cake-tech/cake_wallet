import 'dart:async';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/selected_exchange_provider.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';

part 'selected_exchange_provider_store.g.dart';

class SelectedExchangeProviderStore = SelectedExchangeProviderBase with _$SelectedExchangeProviderStore;

abstract class SelectedExchangeProviderBase with Store {
  SelectedExchangeProviderBase({this.selectedProviderSource}) {
    selectedProviders = ObservableList<SelectedExchangeProvider>();
    update();
  }

  @observable
  ObservableList<SelectedExchangeProvider> selectedProviders;

  Box<SelectedExchangeProvider> selectedProviderSource;

  @action
  void update() =>
      selectedProviders.replaceRange(0, selectedProviders.length, selectedProviderSource.values.toList());

  @action
  Future selectProvider({ExchangeProvider provider}) async {
    final selectedProvider = SelectedExchangeProvider(provider: provider.title);
    await selectedProviderSource.add(selectedProvider);
    update();
  }

  @action
  Future remove({SelectedExchangeProvider provider}) async => await provider.delete();
}