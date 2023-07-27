import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/anypay/any_pay_payment.dart';
import 'package:cake_wallet/anypay/any_pay_payment_instruction.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/anypay/anypay_api.dart';
import 'package:cake_wallet/anypay/any_pay_chain.dart';
import 'package:cake_wallet/anypay/any_pay_trasnaction.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/ionia/ionia_any_pay_payment_info.dart';

class IoniaAnyPay {
	IoniaAnyPay(this.ioniaService, this.anyPayApi, this.wallet);

	final IoniaService ioniaService;
	final AnyPayApi anyPayApi;
	final WalletBase wallet;

	Future<IoniaAnyPayPaymentInfo> purchase({
		required String merchId,
		required double amount}) async {
		final invoice = await ioniaService.purchaseGiftCard(
			merchId: merchId,
			amount: amount,
			currency: wallet.currency.title.toUpperCase());
		final anypayPayment = await anyPayApi.paymentRequest(invoice.uri);
		return IoniaAnyPayPaymentInfo(invoice, anypayPayment);
	}

	Future<AnyPayPaymentCommittedInfo> commitInvoice(AnyPayPayment payment) async {
		final transactionCredentials = payment.instructions
			.where((instruction) => instruction.type == AnyPayPaymentInstruction.transactionType)
			.map((AnyPayPaymentInstruction instruction) {
				switch(payment.chain.toUpperCase()) {
					case AnyPayChain.xmr:
						return monero!.createMoneroTransactionCreationCredentialsRaw(
							outputs: instruction.outputs.map((out) =>
							  OutputInfo(
								isParsedAddress: false,
								address: out.address,
								cryptoAmount: moneroAmountToString(amount: out.amount),
								formattedCryptoAmount: out.amount,
								sendAll: false)).toList(),
							priority: MoneroTransactionPriority.medium); // FIXME: HARDCODED PRIORITY
					case AnyPayChain.btc:
						return bitcoin!.createBitcoinTransactionCredentialsRaw(
							instruction.outputs.map((out) =>
							  OutputInfo(
								isParsedAddress: false,
								address: out.address,
								formattedCryptoAmount: out.amount,
								sendAll: false)).toList(),
							feeRate: instruction.requiredFeeRate);
					case AnyPayChain.ltc:
						return bitcoin!.createBitcoinTransactionCredentialsRaw(
							instruction.outputs.map((out) =>
							  OutputInfo(
								isParsedAddress: false,
								address: out.address,
								formattedCryptoAmount: out.amount,
								sendAll: false)).toList(),
							feeRate: instruction.requiredFeeRate);
					default:
						throw Exception('Incorrect transaction chain: ${payment.chain.toUpperCase()}');
				}
			});
		final transactions = (await Future.wait(transactionCredentials
			.map((Object credentials) async => await wallet.createTransaction(credentials))))
			.map((PendingTransaction pendingTransaction) {
				switch (payment.chain.toUpperCase()){
				case AnyPayChain.xmr:
					final ptx = monero!.pendingTransactionInfo(pendingTransaction);
					return AnyPayTransaction(ptx['hex'] ?? '', id: ptx['id'] ?? '', key: ptx['key']);
				default:
					return AnyPayTransaction(pendingTransaction.hex, id: pendingTransaction.id, key: null);
				} 
			})
			.toList();

		return await anyPayApi.payment(
			payment.paymentUrl,
			chain: payment.chain,
			currency: payment.chain,
			transactions: transactions);
	}
}