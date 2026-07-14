part of 'trade_legacy.dart';

class TradeLegacyAdapter extends TypeAdapter<TradeLegacy> {
  @override
  final int typeId = TradeLegacy.typeId;

  @override
  TradeLegacy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      try {
        fields[reader.readByte()] = reader.read();
      } catch (_) {}
    }

    return TradeLegacy(
      id: fields[0] == null ? '' : fields[0] as String,
      amount: fields[7] == null ? '' : fields[7] as String,
      receiveAmount: fields[23] as String?,
      createdAt: fields[5] as DateTime?,
      expiredAt: fields[6] as DateTime?,
      inputAddress: fields[8] as String?,
      extraId: fields[9] as String?,
      outputTransaction: fields[10] as String?,
      refundAddress: fields[11] as String?,
      walletId: fields[12] as String?,
      payoutAddress: fields[13] as String?,
      password: fields[14] as String?,
      providerId: fields[15] as String?,
      providerName: fields[16] as String?,
      fromWalletAddress: fields[17] as String?,
      memo: fields[18] as String?,
      txId: fields[19] as String?,
      isRefund: fields[20] as bool?,
      isSendAll: fields[21] as bool?,
      router: fields[22] as String?,
      userCurrencyFromRaw: fields[24] as String?,
      userCurrencyToRaw: fields[25] as String?,
      needToRegisterInSwapXyz: fields[26] as bool?,
      sourceTokenAddress: fields[27] as String?,
      sourceTokenDecimals: fields[28] as int?,
      routerData: fields[29] as String?,
      routerValue: fields[30] as String?,
      routerChainId: fields[31] as int?,
      sourceTokenAmountRaw: fields[32] as String?,
      requiresTokenApproval: fields[33] as bool?,
      chainId: fields[34] as int?,
      fee: fields[35] as double?,
    )
      ..providerRaw = fields[1] == null ? 0 : fields[1] as int
      ..fromRaw = (fields[2] as int?) ?? -1
      ..toRaw = (fields[3] as int?) ?? -1
      ..stateRaw = fields[4] == null ? '' : fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, TradeLegacy obj) {
    writer
      ..writeByte(36)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.providerRaw)
      ..writeByte(2)
      ..write(obj.fromRaw)
      ..writeByte(3)
      ..write(obj.toRaw)
      ..writeByte(4)
      ..write(obj.stateRaw)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.expiredAt)
      ..writeByte(7)
      ..write(obj.amount)
      ..writeByte(8)
      ..write(obj.inputAddress)
      ..writeByte(9)
      ..write(obj.extraId)
      ..writeByte(10)
      ..write(obj.outputTransaction)
      ..writeByte(11)
      ..write(obj.refundAddress)
      ..writeByte(12)
      ..write(obj.walletId)
      ..writeByte(13)
      ..write(obj.payoutAddress)
      ..writeByte(14)
      ..write(obj.password)
      ..writeByte(15)
      ..write(obj.providerId)
      ..writeByte(16)
      ..write(obj.providerName)
      ..writeByte(17)
      ..write(obj.fromWalletAddress)
      ..writeByte(18)
      ..write(obj.memo)
      ..writeByte(19)
      ..write(obj.txId)
      ..writeByte(20)
      ..write(obj.isRefund)
      ..writeByte(21)
      ..write(obj.isSendAll)
      ..writeByte(22)
      ..write(obj.router)
      ..writeByte(23)
      ..write(obj.receiveAmount)
      ..writeByte(24)
      ..write(obj.userCurrencyFromRaw)
      ..writeByte(25)
      ..write(obj.userCurrencyToRaw)
      ..writeByte(26)
      ..write(obj.needToRegisterInSwapXyz)
      ..writeByte(27)
      ..write(obj.sourceTokenAddress)
      ..writeByte(28)
      ..write(obj.sourceTokenDecimals)
      ..writeByte(29)
      ..write(obj.routerData)
      ..writeByte(30)
      ..write(obj.routerValue)
      ..writeByte(31)
      ..write(obj.routerChainId)
      ..writeByte(32)
      ..write(obj.sourceTokenAmountRaw)
      ..writeByte(33)
      ..write(obj.requiresTokenApproval)
      ..writeByte(34)
      ..write(obj.chainId)
      ..writeByte(35)
      ..write(obj.fee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeLegacyAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
