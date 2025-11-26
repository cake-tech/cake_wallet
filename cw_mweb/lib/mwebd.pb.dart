///
//  Generated code. Do not modify.
//  source: lib/mwebd.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class StatusRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StatusRequest', createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  StatusRequest._() : super();
  factory StatusRequest() => create();
  factory StatusRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatusRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatusRequest clone() => StatusRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatusRequest copyWith(void Function(StatusRequest) updates) => super.copyWith((message) => updates(message as StatusRequest)) as StatusRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StatusRequest create() => StatusRequest._();
  StatusRequest createEmptyInstance() => create();
  static $pb.PbList<StatusRequest> createRepeated() => $pb.PbList<StatusRequest>();
  @$core.pragma('dart2js:noInline')
  static StatusRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusRequest>(create);
  static StatusRequest? _defaultInstance;
}

class StatusResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StatusResponse', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockHeaderHeight', $pb.PbFieldType.O3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mwebHeaderHeight', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mwebUtxosHeight', $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockTime', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  StatusResponse._() : super();
  factory StatusResponse({
    $core.int? blockHeaderHeight,
    $core.int? mwebHeaderHeight,
    $core.int? mwebUtxosHeight,
    $core.int? blockTime,
  }) {
    final _result = create();
    if (blockHeaderHeight != null) {
      _result.blockHeaderHeight = blockHeaderHeight;
    }
    if (mwebHeaderHeight != null) {
      _result.mwebHeaderHeight = mwebHeaderHeight;
    }
    if (mwebUtxosHeight != null) {
      _result.mwebUtxosHeight = mwebUtxosHeight;
    }
    if (blockTime != null) {
      _result.blockTime = blockTime;
    }
    return _result;
  }
  factory StatusResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatusResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatusResponse clone() => StatusResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatusResponse copyWith(void Function(StatusResponse) updates) => super.copyWith((message) => updates(message as StatusResponse)) as StatusResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StatusResponse create() => StatusResponse._();
  StatusResponse createEmptyInstance() => create();
  static $pb.PbList<StatusResponse> createRepeated() => $pb.PbList<StatusResponse>();
  @$core.pragma('dart2js:noInline')
  static StatusResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusResponse>(create);
  static StatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get blockHeaderHeight => $_getIZ(0);
  @$pb.TagNumber(1)
  set blockHeaderHeight($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockHeaderHeight() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockHeaderHeight() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get mwebHeaderHeight => $_getIZ(1);
  @$pb.TagNumber(2)
  set mwebHeaderHeight($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMwebHeaderHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearMwebHeaderHeight() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get mwebUtxosHeight => $_getIZ(2);
  @$pb.TagNumber(3)
  set mwebUtxosHeight($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMwebUtxosHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearMwebUtxosHeight() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get blockTime => $_getIZ(3);
  @$pb.TagNumber(4)
  set blockTime($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBlockTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlockTime() => clearField(4);
}

class UtxosRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UtxosRequest', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromHeight', $pb.PbFieldType.O3)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  UtxosRequest._() : super();
  factory UtxosRequest({
    $core.int? fromHeight,
    $core.List<$core.int>? scanSecret,
  }) {
    final _result = create();
    if (fromHeight != null) {
      _result.fromHeight = fromHeight;
    }
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    return _result;
  }
  factory UtxosRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UtxosRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UtxosRequest clone() => UtxosRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UtxosRequest copyWith(void Function(UtxosRequest) updates) => super.copyWith((message) => updates(message as UtxosRequest)) as UtxosRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UtxosRequest create() => UtxosRequest._();
  UtxosRequest createEmptyInstance() => create();
  static $pb.PbList<UtxosRequest> createRepeated() => $pb.PbList<UtxosRequest>();
  @$core.pragma('dart2js:noInline')
  static UtxosRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UtxosRequest>(create);
  static UtxosRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fromHeight => $_getIZ(0);
  @$pb.TagNumber(1)
  set fromHeight($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFromHeight() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromHeight() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get scanSecret => $_getN(1);
  @$pb.TagNumber(2)
  set scanSecret($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScanSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearScanSecret() => clearField(2);
}

class Utxo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Utxo', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.O3)
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'address')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockTime', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  Utxo._() : super();
  factory Utxo({
    $core.int? height,
    $fixnum.Int64? value,
    $core.String? address,
    $core.String? outputId,
    $core.int? blockTime,
  }) {
    final _result = create();
    if (height != null) {
      _result.height = height;
    }
    if (value != null) {
      _result.value = value;
    }
    if (address != null) {
      _result.address = address;
    }
    if (outputId != null) {
      _result.outputId = outputId;
    }
    if (blockTime != null) {
      _result.blockTime = blockTime;
    }
    return _result;
  }
  factory Utxo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Utxo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Utxo clone() => Utxo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Utxo copyWith(void Function(Utxo) updates) => super.copyWith((message) => updates(message as Utxo)) as Utxo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Utxo create() => Utxo._();
  Utxo createEmptyInstance() => create();
  static $pb.PbList<Utxo> createRepeated() => $pb.PbList<Utxo>();
  @$core.pragma('dart2js:noInline')
  static Utxo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Utxo>(create);
  static Utxo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get height => $_getIZ(0);
  @$pb.TagNumber(1)
  set height($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHeight() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeight() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get value => $_getI64(1);
  @$pb.TagNumber(2)
  set value($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get outputId => $_getSZ(3);
  @$pb.TagNumber(4)
  set outputId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOutputId() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutputId() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get blockTime => $_getIZ(4);
  @$pb.TagNumber(5)
  set blockTime($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBlockTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearBlockTime() => clearField(5);
}

class AddressRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddressRequest', createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromIndex', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'toIndex', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spendPubkey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  AddressRequest._() : super();
  factory AddressRequest({
    $core.int? fromIndex,
    $core.int? toIndex,
    $core.List<$core.int>? scanSecret,
    $core.List<$core.int>? spendPubkey,
  }) {
    final _result = create();
    if (fromIndex != null) {
      _result.fromIndex = fromIndex;
    }
    if (toIndex != null) {
      _result.toIndex = toIndex;
    }
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    if (spendPubkey != null) {
      _result.spendPubkey = spendPubkey;
    }
    return _result;
  }
  factory AddressRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddressRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddressRequest clone() => AddressRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddressRequest copyWith(void Function(AddressRequest) updates) => super.copyWith((message) => updates(message as AddressRequest)) as AddressRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddressRequest create() => AddressRequest._();
  AddressRequest createEmptyInstance() => create();
  static $pb.PbList<AddressRequest> createRepeated() => $pb.PbList<AddressRequest>();
  @$core.pragma('dart2js:noInline')
  static AddressRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddressRequest>(create);
  static AddressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fromIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set fromIndex($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFromIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromIndex() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get toIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set toIndex($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasToIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearToIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get scanSecret => $_getN(2);
  @$pb.TagNumber(3)
  set scanSecret($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasScanSecret() => $_has(2);
  @$pb.TagNumber(3)
  void clearScanSecret() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get spendPubkey => $_getN(3);
  @$pb.TagNumber(4)
  set spendPubkey($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSpendPubkey() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpendPubkey() => clearField(4);
}

class AddressResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddressResponse', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'address')
    ..hasRequiredFields = false
  ;

  AddressResponse._() : super();
  factory AddressResponse({
    $core.Iterable<$core.String>? address,
  }) {
    final _result = create();
    if (address != null) {
      _result.address.addAll(address);
    }
    return _result;
  }
  factory AddressResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AddressResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AddressResponse clone() => AddressResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AddressResponse copyWith(void Function(AddressResponse) updates) => super.copyWith((message) => updates(message as AddressResponse)) as AddressResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddressResponse create() => AddressResponse._();
  AddressResponse createEmptyInstance() => create();
  static $pb.PbList<AddressResponse> createRepeated() => $pb.PbList<AddressResponse>();
  @$core.pragma('dart2js:noInline')
  static AddressResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddressResponse>(create);
  static AddressResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get address => $_getList(0);
}

class LedgerApdu extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LedgerApdu', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  LedgerApdu._() : super();
  factory LedgerApdu({
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory LedgerApdu.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LedgerApdu.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LedgerApdu clone() => LedgerApdu()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LedgerApdu copyWith(void Function(LedgerApdu) updates) => super.copyWith((message) => updates(message as LedgerApdu)) as LedgerApdu; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LedgerApdu create() => LedgerApdu._();
  LedgerApdu createEmptyInstance() => create();
  static $pb.PbList<LedgerApdu> createRepeated() => $pb.PbList<LedgerApdu>();
  @$core.pragma('dart2js:noInline')
  static LedgerApdu getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LedgerApdu>(create);
  static LedgerApdu? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);
}

class SpentRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SpentRequest', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..hasRequiredFields = false
  ;

  SpentRequest._() : super();
  factory SpentRequest({
    $core.Iterable<$core.String>? outputId,
  }) {
    final _result = create();
    if (outputId != null) {
      _result.outputId.addAll(outputId);
    }
    return _result;
  }
  factory SpentRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SpentRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SpentRequest clone() => SpentRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SpentRequest copyWith(void Function(SpentRequest) updates) => super.copyWith((message) => updates(message as SpentRequest)) as SpentRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SpentRequest create() => SpentRequest._();
  SpentRequest createEmptyInstance() => create();
  static $pb.PbList<SpentRequest> createRepeated() => $pb.PbList<SpentRequest>();
  @$core.pragma('dart2js:noInline')
  static SpentRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SpentRequest>(create);
  static SpentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get outputId => $_getList(0);
}

class SpentResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SpentResponse', createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..hasRequiredFields = false
  ;

  SpentResponse._() : super();
  factory SpentResponse({
    $core.Iterable<$core.String>? outputId,
  }) {
    final _result = create();
    if (outputId != null) {
      _result.outputId.addAll(outputId);
    }
    return _result;
  }
  factory SpentResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SpentResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SpentResponse clone() => SpentResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SpentResponse copyWith(void Function(SpentResponse) updates) => super.copyWith((message) => updates(message as SpentResponse)) as SpentResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SpentResponse create() => SpentResponse._();
  SpentResponse createEmptyInstance() => create();
  static $pb.PbList<SpentResponse> createRepeated() => $pb.PbList<SpentResponse>();
  @$core.pragma('dart2js:noInline')
  static SpentResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SpentResponse>(create);
  static SpentResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get outputId => $_getList(0);
}

class CreateRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateRequest', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rawTx', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spendSecret', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'feeRatePerKb', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dryRun')
    ..hasRequiredFields = false
  ;

  CreateRequest._() : super();
  factory CreateRequest({
    $core.List<$core.int>? rawTx,
    $core.List<$core.int>? scanSecret,
    $core.List<$core.int>? spendSecret,
    $fixnum.Int64? feeRatePerKb,
    $core.bool? dryRun,
  }) {
    final _result = create();
    if (rawTx != null) {
      _result.rawTx = rawTx;
    }
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    if (spendSecret != null) {
      _result.spendSecret = spendSecret;
    }
    if (feeRatePerKb != null) {
      _result.feeRatePerKb = feeRatePerKb;
    }
    if (dryRun != null) {
      _result.dryRun = dryRun;
    }
    return _result;
  }
  factory CreateRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateRequest clone() => CreateRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateRequest copyWith(void Function(CreateRequest) updates) => super.copyWith((message) => updates(message as CreateRequest)) as CreateRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateRequest create() => CreateRequest._();
  CreateRequest createEmptyInstance() => create();
  static $pb.PbList<CreateRequest> createRepeated() => $pb.PbList<CreateRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateRequest>(create);
  static CreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rawTx => $_getN(0);
  @$pb.TagNumber(1)
  set rawTx($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRawTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearRawTx() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get scanSecret => $_getN(1);
  @$pb.TagNumber(2)
  set scanSecret($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScanSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearScanSecret() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get spendSecret => $_getN(2);
  @$pb.TagNumber(3)
  set spendSecret($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSpendSecret() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpendSecret() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get feeRatePerKb => $_getI64(3);
  @$pb.TagNumber(4)
  set feeRatePerKb($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFeeRatePerKb() => $_has(3);
  @$pb.TagNumber(4)
  void clearFeeRatePerKb() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get dryRun => $_getBF(4);
  @$pb.TagNumber(5)
  set dryRun($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDryRun() => $_has(4);
  @$pb.TagNumber(5)
  void clearDryRun() => clearField(5);
}

class CreateResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateResponse', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rawTx', $pb.PbFieldType.OY)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..hasRequiredFields = false
  ;

  CreateResponse._() : super();
  factory CreateResponse({
    $core.List<$core.int>? rawTx,
    $core.Iterable<$core.String>? outputId,
  }) {
    final _result = create();
    if (rawTx != null) {
      _result.rawTx = rawTx;
    }
    if (outputId != null) {
      _result.outputId.addAll(outputId);
    }
    return _result;
  }
  factory CreateResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateResponse clone() => CreateResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateResponse copyWith(void Function(CreateResponse) updates) => super.copyWith((message) => updates(message as CreateResponse)) as CreateResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateResponse create() => CreateResponse._();
  CreateResponse createEmptyInstance() => create();
  static $pb.PbList<CreateResponse> createRepeated() => $pb.PbList<CreateResponse>();
  @$core.pragma('dart2js:noInline')
  static CreateResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateResponse>(create);
  static CreateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rawTx => $_getN(0);
  @$pb.TagNumber(1)
  set rawTx($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRawTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearRawTx() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get outputId => $_getList(1);
}

class PsbtCreateRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtCreateRequest', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rawTx', $pb.PbFieldType.OY)
    ..pc<TxOut>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'witnessUtxo', $pb.PbFieldType.PM, subBuilder: TxOut.create)
    ..hasRequiredFields = false
  ;

  PsbtCreateRequest._() : super();
  factory PsbtCreateRequest({
    $core.List<$core.int>? rawTx,
    $core.Iterable<TxOut>? witnessUtxo,
  }) {
    final _result = create();
    if (rawTx != null) {
      _result.rawTx = rawTx;
    }
    if (witnessUtxo != null) {
      _result.witnessUtxo.addAll(witnessUtxo);
    }
    return _result;
  }
  factory PsbtCreateRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtCreateRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtCreateRequest clone() => PsbtCreateRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtCreateRequest copyWith(void Function(PsbtCreateRequest) updates) => super.copyWith((message) => updates(message as PsbtCreateRequest)) as PsbtCreateRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtCreateRequest create() => PsbtCreateRequest._();
  PsbtCreateRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtCreateRequest> createRepeated() => $pb.PbList<PsbtCreateRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtCreateRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtCreateRequest>(create);
  static PsbtCreateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rawTx => $_getN(0);
  @$pb.TagNumber(1)
  set rawTx($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRawTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearRawTx() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<TxOut> get witnessUtxo => $_getList(1);
}

class TxOut extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TxOut', createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pkScript', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  TxOut._() : super();
  factory TxOut({
    $fixnum.Int64? value,
    $core.List<$core.int>? pkScript,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    if (pkScript != null) {
      _result.pkScript = pkScript;
    }
    return _result;
  }
  factory TxOut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxOut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxOut clone() => TxOut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxOut copyWith(void Function(TxOut) updates) => super.copyWith((message) => updates(message as TxOut)) as TxOut; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TxOut create() => TxOut._();
  TxOut createEmptyInstance() => create();
  static $pb.PbList<TxOut> createRepeated() => $pb.PbList<TxOut>();
  @$core.pragma('dart2js:noInline')
  static TxOut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxOut>(create);
  static TxOut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get value => $_getI64(0);
  @$pb.TagNumber(1)
  set value($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get pkScript => $_getN(1);
  @$pb.TagNumber(2)
  set pkScript($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPkScript() => $_has(1);
  @$pb.TagNumber(2)
  void clearPkScript() => clearField(2);
}

class PsbtResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtResponse', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..hasRequiredFields = false
  ;

  PsbtResponse._() : super();
  factory PsbtResponse({
    $core.String? psbtB64,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    return _result;
  }
  factory PsbtResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtResponse clone() => PsbtResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtResponse copyWith(void Function(PsbtResponse) updates) => super.copyWith((message) => updates(message as PsbtResponse)) as PsbtResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtResponse create() => PsbtResponse._();
  PsbtResponse createEmptyInstance() => create();
  static $pb.PbList<PsbtResponse> createRepeated() => $pb.PbList<PsbtResponse>();
  @$core.pragma('dart2js:noInline')
  static PsbtResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtResponse>(create);
  static PsbtResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);
}

class PsbtAddInputRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtAddInputRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'addressIndex', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'feeRatePerKb', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  PsbtAddInputRequest._() : super();
  factory PsbtAddInputRequest({
    $core.String? psbtB64,
    $core.List<$core.int>? scanSecret,
    $core.String? outputId,
    $core.int? addressIndex,
    $fixnum.Int64? feeRatePerKb,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    if (outputId != null) {
      _result.outputId = outputId;
    }
    if (addressIndex != null) {
      _result.addressIndex = addressIndex;
    }
    if (feeRatePerKb != null) {
      _result.feeRatePerKb = feeRatePerKb;
    }
    return _result;
  }
  factory PsbtAddInputRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtAddInputRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtAddInputRequest clone() => PsbtAddInputRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtAddInputRequest copyWith(void Function(PsbtAddInputRequest) updates) => super.copyWith((message) => updates(message as PsbtAddInputRequest)) as PsbtAddInputRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtAddInputRequest create() => PsbtAddInputRequest._();
  PsbtAddInputRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtAddInputRequest> createRepeated() => $pb.PbList<PsbtAddInputRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtAddInputRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtAddInputRequest>(create);
  static PsbtAddInputRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get scanSecret => $_getN(1);
  @$pb.TagNumber(2)
  set scanSecret($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScanSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearScanSecret() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get outputId => $_getSZ(2);
  @$pb.TagNumber(3)
  set outputId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOutputId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get addressIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set addressIndex($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAddressIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddressIndex() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get feeRatePerKb => $_getI64(4);
  @$pb.TagNumber(5)
  set feeRatePerKb($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasFeeRatePerKb() => $_has(4);
  @$pb.TagNumber(5)
  void clearFeeRatePerKb() => clearField(5);
}

class PsbtAddRecipientRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtAddRecipientRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..aOM<PsbtRecipient>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'recipient', subBuilder: PsbtRecipient.create)
    ..a<$fixnum.Int64>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'feeRatePerKb', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  PsbtAddRecipientRequest._() : super();
  factory PsbtAddRecipientRequest({
    $core.String? psbtB64,
    PsbtRecipient? recipient,
    $fixnum.Int64? feeRatePerKb,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    if (recipient != null) {
      _result.recipient = recipient;
    }
    if (feeRatePerKb != null) {
      _result.feeRatePerKb = feeRatePerKb;
    }
    return _result;
  }
  factory PsbtAddRecipientRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtAddRecipientRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtAddRecipientRequest clone() => PsbtAddRecipientRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtAddRecipientRequest copyWith(void Function(PsbtAddRecipientRequest) updates) => super.copyWith((message) => updates(message as PsbtAddRecipientRequest)) as PsbtAddRecipientRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtAddRecipientRequest create() => PsbtAddRecipientRequest._();
  PsbtAddRecipientRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtAddRecipientRequest> createRepeated() => $pb.PbList<PsbtAddRecipientRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtAddRecipientRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtAddRecipientRequest>(create);
  static PsbtAddRecipientRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);

  @$pb.TagNumber(2)
  PsbtRecipient get recipient => $_getN(1);
  @$pb.TagNumber(2)
  set recipient(PsbtRecipient v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRecipient() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecipient() => clearField(2);
  @$pb.TagNumber(2)
  PsbtRecipient ensureRecipient() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get feeRatePerKb => $_getI64(2);
  @$pb.TagNumber(3)
  set feeRatePerKb($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFeeRatePerKb() => $_has(2);
  @$pb.TagNumber(3)
  void clearFeeRatePerKb() => clearField(3);
}

class PsbtGetRecipientsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtGetRecipientsRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..hasRequiredFields = false
  ;

  PsbtGetRecipientsRequest._() : super();
  factory PsbtGetRecipientsRequest({
    $core.String? psbtB64,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    return _result;
  }
  factory PsbtGetRecipientsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtGetRecipientsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtGetRecipientsRequest clone() => PsbtGetRecipientsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtGetRecipientsRequest copyWith(void Function(PsbtGetRecipientsRequest) updates) => super.copyWith((message) => updates(message as PsbtGetRecipientsRequest)) as PsbtGetRecipientsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtGetRecipientsRequest create() => PsbtGetRecipientsRequest._();
  PsbtGetRecipientsRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtGetRecipientsRequest> createRepeated() => $pb.PbList<PsbtGetRecipientsRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtGetRecipientsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtGetRecipientsRequest>(create);
  static PsbtGetRecipientsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);
}

class PsbtGetRecipientsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtGetRecipientsResponse', createEmptyInstance: create)
    ..pc<PsbtRecipient>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'recipient', $pb.PbFieldType.PM, subBuilder: PsbtRecipient.create)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'inputAddress')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fee')
    ..hasRequiredFields = false
  ;

  PsbtGetRecipientsResponse._() : super();
  factory PsbtGetRecipientsResponse({
    $core.Iterable<PsbtRecipient>? recipient,
    $core.Iterable<$core.String>? inputAddress,
    $fixnum.Int64? fee,
  }) {
    final _result = create();
    if (recipient != null) {
      _result.recipient.addAll(recipient);
    }
    if (inputAddress != null) {
      _result.inputAddress.addAll(inputAddress);
    }
    if (fee != null) {
      _result.fee = fee;
    }
    return _result;
  }
  factory PsbtGetRecipientsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtGetRecipientsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtGetRecipientsResponse clone() => PsbtGetRecipientsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtGetRecipientsResponse copyWith(void Function(PsbtGetRecipientsResponse) updates) => super.copyWith((message) => updates(message as PsbtGetRecipientsResponse)) as PsbtGetRecipientsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtGetRecipientsResponse create() => PsbtGetRecipientsResponse._();
  PsbtGetRecipientsResponse createEmptyInstance() => create();
  static $pb.PbList<PsbtGetRecipientsResponse> createRepeated() => $pb.PbList<PsbtGetRecipientsResponse>();
  @$core.pragma('dart2js:noInline')
  static PsbtGetRecipientsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtGetRecipientsResponse>(create);
  static PsbtGetRecipientsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<PsbtRecipient> get recipient => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get inputAddress => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get fee => $_getI64(2);
  @$pb.TagNumber(3)
  set fee($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFee() => $_has(2);
  @$pb.TagNumber(3)
  void clearFee() => clearField(3);
}

class PsbtRecipient extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtRecipient', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'address')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  PsbtRecipient._() : super();
  factory PsbtRecipient({
    $core.String? address,
    $fixnum.Int64? value,
  }) {
    final _result = create();
    if (address != null) {
      _result.address = address;
    }
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory PsbtRecipient.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtRecipient.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtRecipient clone() => PsbtRecipient()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtRecipient copyWith(void Function(PsbtRecipient) updates) => super.copyWith((message) => updates(message as PsbtRecipient)) as PsbtRecipient; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtRecipient create() => PsbtRecipient._();
  PsbtRecipient createEmptyInstance() => create();
  static $pb.PbList<PsbtRecipient> createRepeated() => $pb.PbList<PsbtRecipient>();
  @$core.pragma('dart2js:noInline')
  static PsbtRecipient getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtRecipient>(create);
  static PsbtRecipient? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get value => $_getI64(1);
  @$pb.TagNumber(2)
  set value($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

class PsbtSignRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtSignRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spendSecret', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  PsbtSignRequest._() : super();
  factory PsbtSignRequest({
    $core.String? psbtB64,
    $core.List<$core.int>? scanSecret,
    $core.List<$core.int>? spendSecret,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    if (spendSecret != null) {
      _result.spendSecret = spendSecret;
    }
    return _result;
  }
  factory PsbtSignRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtSignRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtSignRequest clone() => PsbtSignRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtSignRequest copyWith(void Function(PsbtSignRequest) updates) => super.copyWith((message) => updates(message as PsbtSignRequest)) as PsbtSignRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtSignRequest create() => PsbtSignRequest._();
  PsbtSignRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtSignRequest> createRepeated() => $pb.PbList<PsbtSignRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtSignRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtSignRequest>(create);
  static PsbtSignRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get scanSecret => $_getN(1);
  @$pb.TagNumber(2)
  set scanSecret($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScanSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearScanSecret() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get spendSecret => $_getN(2);
  @$pb.TagNumber(3)
  set spendSecret($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSpendSecret() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpendSecret() => clearField(3);
}

class PsbtSignNonMwebRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtSignNonMwebRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'privKey', $pb.PbFieldType.OY)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PsbtSignNonMwebRequest._() : super();
  factory PsbtSignNonMwebRequest({
    $core.String? psbtB64,
    $core.List<$core.int>? privKey,
    $core.int? index,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    if (privKey != null) {
      _result.privKey = privKey;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory PsbtSignNonMwebRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtSignNonMwebRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtSignNonMwebRequest clone() => PsbtSignNonMwebRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtSignNonMwebRequest copyWith(void Function(PsbtSignNonMwebRequest) updates) => super.copyWith((message) => updates(message as PsbtSignNonMwebRequest)) as PsbtSignNonMwebRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtSignNonMwebRequest create() => PsbtSignNonMwebRequest._();
  PsbtSignNonMwebRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtSignNonMwebRequest> createRepeated() => $pb.PbList<PsbtSignNonMwebRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtSignNonMwebRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtSignNonMwebRequest>(create);
  static PsbtSignNonMwebRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get privKey => $_getN(1);
  @$pb.TagNumber(2)
  set privKey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPrivKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrivKey() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get index => $_getIZ(2);
  @$pb.TagNumber(3)
  set index($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearIndex() => clearField(3);
}

class PsbtExtractRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PsbtExtractRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'psbtB64')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'unsigned')
    ..hasRequiredFields = false
  ;

  PsbtExtractRequest._() : super();
  factory PsbtExtractRequest({
    $core.String? psbtB64,
    $core.bool? unsigned,
  }) {
    final _result = create();
    if (psbtB64 != null) {
      _result.psbtB64 = psbtB64;
    }
    if (unsigned != null) {
      _result.unsigned = unsigned;
    }
    return _result;
  }
  factory PsbtExtractRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PsbtExtractRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PsbtExtractRequest clone() => PsbtExtractRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PsbtExtractRequest copyWith(void Function(PsbtExtractRequest) updates) => super.copyWith((message) => updates(message as PsbtExtractRequest)) as PsbtExtractRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PsbtExtractRequest create() => PsbtExtractRequest._();
  PsbtExtractRequest createEmptyInstance() => create();
  static $pb.PbList<PsbtExtractRequest> createRepeated() => $pb.PbList<PsbtExtractRequest>();
  @$core.pragma('dart2js:noInline')
  static PsbtExtractRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PsbtExtractRequest>(create);
  static PsbtExtractRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get psbtB64 => $_getSZ(0);
  @$pb.TagNumber(1)
  set psbtB64($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPsbtB64() => $_has(0);
  @$pb.TagNumber(1)
  void clearPsbtB64() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get unsigned => $_getBF(1);
  @$pb.TagNumber(2)
  set unsigned($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUnsigned() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnsigned() => clearField(2);
}

class BroadcastRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BroadcastRequest', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rawTx', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  BroadcastRequest._() : super();
  factory BroadcastRequest({
    $core.List<$core.int>? rawTx,
  }) {
    final _result = create();
    if (rawTx != null) {
      _result.rawTx = rawTx;
    }
    return _result;
  }
  factory BroadcastRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastRequest clone() => BroadcastRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastRequest copyWith(void Function(BroadcastRequest) updates) => super.copyWith((message) => updates(message as BroadcastRequest)) as BroadcastRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BroadcastRequest create() => BroadcastRequest._();
  BroadcastRequest createEmptyInstance() => create();
  static $pb.PbList<BroadcastRequest> createRepeated() => $pb.PbList<BroadcastRequest>();
  @$core.pragma('dart2js:noInline')
  static BroadcastRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastRequest>(create);
  static BroadcastRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get rawTx => $_getN(0);
  @$pb.TagNumber(1)
  set rawTx($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRawTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearRawTx() => clearField(1);
}

class BroadcastResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BroadcastResponse', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'txid')
    ..hasRequiredFields = false
  ;

  BroadcastResponse._() : super();
  factory BroadcastResponse({
    $core.String? txid,
  }) {
    final _result = create();
    if (txid != null) {
      _result.txid = txid;
    }
    return _result;
  }
  factory BroadcastResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastResponse clone() => BroadcastResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastResponse copyWith(void Function(BroadcastResponse) updates) => super.copyWith((message) => updates(message as BroadcastResponse)) as BroadcastResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BroadcastResponse create() => BroadcastResponse._();
  BroadcastResponse createEmptyInstance() => create();
  static $pb.PbList<BroadcastResponse> createRepeated() => $pb.PbList<BroadcastResponse>();
  @$core.pragma('dart2js:noInline')
  static BroadcastResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastResponse>(create);
  static BroadcastResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get txid => $_getSZ(0);
  @$pb.TagNumber(1)
  set txid($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTxid() => $_has(0);
  @$pb.TagNumber(1)
  void clearTxid() => clearField(1);
}

class CoinswapRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CoinswapRequest', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scanSecret', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spendSecret', $pb.PbFieldType.OY)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'addrIndex', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  CoinswapRequest._() : super();
  factory CoinswapRequest({
    $core.List<$core.int>? scanSecret,
    $core.List<$core.int>? spendSecret,
    $core.String? outputId,
    $core.int? addrIndex,
  }) {
    final _result = create();
    if (scanSecret != null) {
      _result.scanSecret = scanSecret;
    }
    if (spendSecret != null) {
      _result.spendSecret = spendSecret;
    }
    if (outputId != null) {
      _result.outputId = outputId;
    }
    if (addrIndex != null) {
      _result.addrIndex = addrIndex;
    }
    return _result;
  }
  factory CoinswapRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoinswapRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoinswapRequest clone() => CoinswapRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoinswapRequest copyWith(void Function(CoinswapRequest) updates) => super.copyWith((message) => updates(message as CoinswapRequest)) as CoinswapRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CoinswapRequest create() => CoinswapRequest._();
  CoinswapRequest createEmptyInstance() => create();
  static $pb.PbList<CoinswapRequest> createRepeated() => $pb.PbList<CoinswapRequest>();
  @$core.pragma('dart2js:noInline')
  static CoinswapRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoinswapRequest>(create);
  static CoinswapRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get scanSecret => $_getN(0);
  @$pb.TagNumber(1)
  set scanSecret($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasScanSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearScanSecret() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get spendSecret => $_getN(1);
  @$pb.TagNumber(2)
  set spendSecret($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSpendSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpendSecret() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get outputId => $_getSZ(2);
  @$pb.TagNumber(3)
  set outputId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOutputId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get addrIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set addrIndex($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAddrIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddrIndex() => clearField(4);
}

class CoinswapResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CoinswapResponse', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputId')
    ..hasRequiredFields = false
  ;

  CoinswapResponse._() : super();
  factory CoinswapResponse({
    $core.String? outputId,
  }) {
    final _result = create();
    if (outputId != null) {
      _result.outputId = outputId;
    }
    return _result;
  }
  factory CoinswapResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoinswapResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoinswapResponse clone() => CoinswapResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoinswapResponse copyWith(void Function(CoinswapResponse) updates) => super.copyWith((message) => updates(message as CoinswapResponse)) as CoinswapResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CoinswapResponse create() => CoinswapResponse._();
  CoinswapResponse createEmptyInstance() => create();
  static $pb.PbList<CoinswapResponse> createRepeated() => $pb.PbList<CoinswapResponse>();
  @$core.pragma('dart2js:noInline')
  static CoinswapResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoinswapResponse>(create);
  static CoinswapResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outputId => $_getSZ(0);
  @$pb.TagNumber(1)
  set outputId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOutputId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutputId() => clearField(1);
}

