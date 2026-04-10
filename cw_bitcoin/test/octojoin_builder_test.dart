import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/octojoin_transaction_builder.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitcoin_base/bitcoin_base.dart';

void main() {
  group('OctojoinTransactionBuilder E2E Logic Test', () {
    test('decomposeAmount successfully chunks into standard denominations', () {
      final amount = 300000;
      final denominations = OctojoinTransactionBuilder.decomposeAmount(amount);
      
      printV('Decomposed Amount: $amount sats');
      printV('Denominations Result: $denominations');
      
      expect(denominations.length, 2);
      expect(denominations.contains(200000), true);
      expect(denominations.contains(100000), true);
    });

    test('selectUTXOs correctly isolates octojoin notes from unspents', () {
      final walletId = 'test_wallet';
      
      final addrRecord1 = BitcoinAddressRecord('addr1', index: 0, type: SegwitAddresType.p2wpkh, network: BitcoinNetwork.testnet);
      final addrRecord2 = BitcoinAddressRecord('addr2', index: 1, type: SegwitAddresType.p2wpkh, network: BitcoinNetwork.testnet);
      final addrRecord3 = BitcoinAddressRecord('addr3', index: 2, type: SegwitAddresType.p2wpkh, network: BitcoinNetwork.testnet);

      final unspentCoins = [
         BitcoinUnspent(addrRecord1, 'hash1', 150000, 0),
         BitcoinUnspent(addrRecord2, 'hash2', 150000, 0),
         BitcoinUnspent(addrRecord3, 'hash3', 50000, 0),
      ];
      
      final unspentCoinsInfoValues = [
         UnspentCoinsInfo(walletId: walletId, hash: 'hash1', address: 'addr1', value: 150000, vout: 0, isFrozen: false, isSending: true, noteRaw: 'Octojoin 1'),
         UnspentCoinsInfo(walletId: walletId, hash: 'hash2', address: 'addr2', value: 150000, vout: 0, isFrozen: false, isSending: true, noteRaw: 'octojoin 2'),
         UnspentCoinsInfo(walletId: walletId, hash: 'hash3', address: 'addr3', value: 50000, vout: 0, isFrozen: false, isSending: true, noteRaw: 'Normal TX'),
      ];
      
      final selection = OctojoinTransactionBuilder.selectUTXOs(
        unspentCoins, 
        unspentCoinsInfoValues, 
        3, 
        walletId,
        300000
      );
      
      final swapped = selection['swapped'] as List<BitcoinUnspent>;
      final other = selection['other'] as List<BitcoinUnspent>;
      final all = selection['all'] as List<BitcoinUnspent>;
      
      printV('--- UTXO Selection Pipeline ---');
      printV('Swapped UTXOs Found: ${swapped.length}');
      printV('Total Value Selected: ${selection['totalValue']}');

      expect(swapped.length, 2);
      expect(other.length, 1);
      expect(all.length, 3);
      expect(selection['totalValue'], 350000);
    });
    
    test('distributeOutputs seamlessly maps exact denominations to destination addresses', () {
       final addrs = ['addr1', 'addr2'];
       final denominations = [200000, 100000, 1000];
       
       final outputsMap = OctojoinTransactionBuilder.distributeOutputs(denominations, addrs);
       
       printV('--- Final Output Structure Map ---');
       outputsMap.forEach((key, value) {
         printV('Address: $key -> Value: $value sats');
       });
       
       expect(outputsMap['addr1'], 201000);
       expect(outputsMap['addr2'], 100000);
    });
  });
}
