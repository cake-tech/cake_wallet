import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';

class OctojoinTransactionBuilder {
  static const List<int> standardDenominations = [
    100000000,
    50000000,
    20000000,
    10000000,
    5000000,
    2000000,
    1000000,
    500000,
    200000,
    100000,
  ];

  static const int dustThreshold = 546;

  static List<int> decomposeAmount(int amountInSatoshis) {
    final denominations = <int>[];
    int remaining = amountInSatoshis;

    for (final denom in standardDenominations) {
      while (remaining >= denom) {
        denominations.add(denom);
        remaining -= denom;
      }
    }

    if (remaining > dustThreshold) {
      denominations.add(remaining);
    }

    return denominations;
  }

  static Map<String, int> distributeOutputs(List<int> denominations, List<String> addresses) {
    final outputs = <String, int>{};
    for (final addr in addresses) {
      outputs[addr] = 0;
    }

    for (int i = 0; i < denominations.length; i++) {
      final denom = denominations[i];
      final addrIndex = i % addresses.length;
      final addr = addresses[addrIndex];
      outputs[addr] = outputs[addr]! + denom;
    }

    return outputs;
  }

  static Map<String, dynamic> selectUTXOs(
      Iterable<BitcoinUnspent> unspentCoins, Iterable<UnspentCoinsInfo> unspentCoinsInfo, int numInputs, String walletId, int targetAmount) {
      
    final swappedUTXOs = unspentCoins.where((utxo) {
        final info = unspentCoinsInfo.firstWhere(
           (e) => e.walletId == walletId && e.hash == utxo.hash && e.vout == utxo.vout,
           orElse: () => UnspentCoinsInfo(walletId: walletId, hash: utxo.hash, isFrozen: false, isSending: false, noteRaw: '', address: utxo.address, vout: utxo.vout, value: utxo.value.toInt())
        );
        return _isOctojoin(info.note);
    }).toList();
    
    final otherUTXOs = unspentCoins.where((utxo) {
        final info = unspentCoinsInfo.firstWhere(
           (e) => e.walletId == walletId && e.hash == utxo.hash && e.vout == utxo.vout,
           orElse: () => UnspentCoinsInfo(walletId: walletId, hash: utxo.hash, isFrozen: false, isSending: false, noteRaw: '', address: utxo.address, vout: utxo.vout, value: utxo.value.toInt())
        );
        return !_isOctojoin(info.note);
    }).toList();

    final requiredSwapped = numInputs - 1;

    if (swappedUTXOs.length < requiredSwapped) {
      throw Exception("Not enough 'octojoin' coins. You need at least $requiredSwapped, but only found ${swappedUTXOs.length}.");
    }
    if (otherUTXOs.isEmpty) {
      throw Exception("Requires at least 1 non-octojoin coin.");
    }

    final selectedSwapped = swappedUTXOs.take(requiredSwapped).toList();
    final selectedOther = <BitcoinUnspent>[];
    
    otherUTXOs.sort((a, b) => b.value.compareTo(a.value));
    
    int currentTotalValue = selectedSwapped.fold<int>(0, (sum, utxo) => sum + utxo.value.toInt());
    
    const int feeBuffer = 0; 

    for (final other in otherUTXOs) {
      selectedOther.add(other);
      currentTotalValue += other.value.toInt();
      
      if (currentTotalValue >= targetAmount + feeBuffer) {
        break;
      }
    }

    if (currentTotalValue < targetAmount) {
       throw Exception("Insufficient funds. Total selected: ${(currentTotalValue/100000000).toStringAsFixed(8)} BTC, Target: ${(targetAmount/100000000).toStringAsFixed(8)} BTC.");
    }

    return {
      'swapped': selectedSwapped,
      'other': selectedOther,
      'all': [...selectedSwapped, ...selectedOther],
      'totalValue': currentTotalValue
    };
  }
  
  static bool _isOctojoin(String note) {
    return note.toLowerCase().contains('octojoin');
  }
}
