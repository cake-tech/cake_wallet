import 'package:bloc/bloc.dart';
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
import 'package:meta/meta.dart';

part 'swap_event.dart';
part 'swap_state.dart';

class SwapBloc extends Bloc<SwapEvent, SwapState> {
  SwapBloc() : super(SwapInitial()) {
    on<SwapEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
