//
//  Generated code. Do not modify.
//  source: mwebd.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mwebd.pb.dart' as $0;

export 'mwebd.pb.dart';

@$pb.GrpcServiceName('Rpc')
class RpcClient extends $grpc.Client {
  static final _$status = $grpc.ClientMethod<$0.StatusRequest, $0.StatusResponse>(
      '/Rpc/Status',
      ($0.StatusRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.StatusResponse.fromBuffer(value));
  static final _$utxos = $grpc.ClientMethod<$0.UtxosRequest, $0.Utxo>(
      '/Rpc/Utxos',
      ($0.UtxosRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Utxo.fromBuffer(value));
  static final _$addresses = $grpc.ClientMethod<$0.AddressRequest, $0.AddressResponse>(
      '/Rpc/Addresses',
      ($0.AddressRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.AddressResponse.fromBuffer(value));
  static final _$spent = $grpc.ClientMethod<$0.SpentRequest, $0.SpentResponse>(
      '/Rpc/Spent',
      ($0.SpentRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SpentResponse.fromBuffer(value));
  static final _$create = $grpc.ClientMethod<$0.CreateRequest, $0.CreateResponse>(
      '/Rpc/Create',
      ($0.CreateRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CreateResponse.fromBuffer(value));
  static final _$psbtCreate = $grpc.ClientMethod<$0.PsbtCreateRequest, $0.PsbtResponse>(
      '/Rpc/PsbtCreate',
      ($0.PsbtCreateRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtResponse.fromBuffer(value));
  static final _$psbtAddInput = $grpc.ClientMethod<$0.PsbtAddInputRequest, $0.PsbtResponse>(
      '/Rpc/PsbtAddInput',
      ($0.PsbtAddInputRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtResponse.fromBuffer(value));
  static final _$psbtAddRecipient = $grpc.ClientMethod<$0.PsbtAddRecipientRequest, $0.PsbtResponse>(
      '/Rpc/PsbtAddRecipient',
      ($0.PsbtAddRecipientRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtResponse.fromBuffer(value));
  static final _$psbtGetRecipients = $grpc.ClientMethod<$0.PsbtGetRecipientsRequest, $0.PsbtGetRecipientsResponse>(
      '/Rpc/PsbtGetRecipients',
      ($0.PsbtGetRecipientsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtGetRecipientsResponse.fromBuffer(value));
  static final _$psbtSign = $grpc.ClientMethod<$0.PsbtSignRequest, $0.PsbtResponse>(
      '/Rpc/PsbtSign',
      ($0.PsbtSignRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtResponse.fromBuffer(value));
  static final _$psbtSignNonMweb = $grpc.ClientMethod<$0.PsbtSignNonMwebRequest, $0.PsbtResponse>(
      '/Rpc/PsbtSignNonMweb',
      ($0.PsbtSignNonMwebRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PsbtResponse.fromBuffer(value));
  static final _$psbtExtract = $grpc.ClientMethod<$0.PsbtExtractRequest, $0.CreateResponse>(
      '/Rpc/PsbtExtract',
      ($0.PsbtExtractRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CreateResponse.fromBuffer(value));
  static final _$ledgerExchange = $grpc.ClientMethod<$0.LedgerApdu, $0.LedgerApdu>(
      '/Rpc/LedgerExchange',
      ($0.LedgerApdu value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.LedgerApdu.fromBuffer(value));
  static final _$broadcast = $grpc.ClientMethod<$0.BroadcastRequest, $0.BroadcastResponse>(
      '/Rpc/Broadcast',
      ($0.BroadcastRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.BroadcastResponse.fromBuffer(value));
  static final _$coinswap = $grpc.ClientMethod<$0.CoinswapRequest, $0.CoinswapResponse>(
      '/Rpc/Coinswap',
      ($0.CoinswapRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoinswapResponse.fromBuffer(value));

  RpcClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.StatusResponse> status($0.StatusRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$status, request, options: options);
  }

  $grpc.ResponseStream<$0.Utxo> utxos($0.UtxosRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$utxos, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.AddressResponse> addresses($0.AddressRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$addresses, request, options: options);
  }

  $grpc.ResponseFuture<$0.SpentResponse> spent($0.SpentRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$spent, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateResponse> create($0.CreateRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$create, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtResponse> psbtCreate($0.PsbtCreateRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtCreate, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtResponse> psbtAddInput($0.PsbtAddInputRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtAddInput, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtResponse> psbtAddRecipient($0.PsbtAddRecipientRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtAddRecipient, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtGetRecipientsResponse> psbtGetRecipients($0.PsbtGetRecipientsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtGetRecipients, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtResponse> psbtSign($0.PsbtSignRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtSign, request, options: options);
  }

  $grpc.ResponseFuture<$0.PsbtResponse> psbtSignNonMweb($0.PsbtSignNonMwebRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtSignNonMweb, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateResponse> psbtExtract($0.PsbtExtractRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$psbtExtract, request, options: options);
  }

  $grpc.ResponseFuture<$0.LedgerApdu> ledgerExchange($0.LedgerApdu request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$ledgerExchange, request, options: options);
  }

  $grpc.ResponseFuture<$0.BroadcastResponse> broadcast($0.BroadcastRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$broadcast, request, options: options);
  }

  $grpc.ResponseFuture<$0.CoinswapResponse> coinswap($0.CoinswapRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$coinswap, request, options: options);
  }
}

@$pb.GrpcServiceName('Rpc')
abstract class RpcServiceBase extends $grpc.Service {
  $core.String get $name => 'Rpc';

  RpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StatusRequest, $0.StatusResponse>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StatusRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UtxosRequest, $0.Utxo>(
        'Utxos',
        utxos_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.UtxosRequest.fromBuffer(value),
        ($0.Utxo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddressRequest, $0.AddressResponse>(
        'Addresses',
        addresses_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddressRequest.fromBuffer(value),
        ($0.AddressResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SpentRequest, $0.SpentResponse>(
        'Spent',
        spent_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SpentRequest.fromBuffer(value),
        ($0.SpentResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateRequest, $0.CreateResponse>(
        'Create',
        create_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateRequest.fromBuffer(value),
        ($0.CreateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtCreateRequest, $0.PsbtResponse>(
        'PsbtCreate',
        psbtCreate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtCreateRequest.fromBuffer(value),
        ($0.PsbtResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtAddInputRequest, $0.PsbtResponse>(
        'PsbtAddInput',
        psbtAddInput_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtAddInputRequest.fromBuffer(value),
        ($0.PsbtResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtAddRecipientRequest, $0.PsbtResponse>(
        'PsbtAddRecipient',
        psbtAddRecipient_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtAddRecipientRequest.fromBuffer(value),
        ($0.PsbtResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtGetRecipientsRequest, $0.PsbtGetRecipientsResponse>(
        'PsbtGetRecipients',
        psbtGetRecipients_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtGetRecipientsRequest.fromBuffer(value),
        ($0.PsbtGetRecipientsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtSignRequest, $0.PsbtResponse>(
        'PsbtSign',
        psbtSign_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtSignRequest.fromBuffer(value),
        ($0.PsbtResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtSignNonMwebRequest, $0.PsbtResponse>(
        'PsbtSignNonMweb',
        psbtSignNonMweb_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtSignNonMwebRequest.fromBuffer(value),
        ($0.PsbtResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PsbtExtractRequest, $0.CreateResponse>(
        'PsbtExtract',
        psbtExtract_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PsbtExtractRequest.fromBuffer(value),
        ($0.CreateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LedgerApdu, $0.LedgerApdu>(
        'LedgerExchange',
        ledgerExchange_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LedgerApdu.fromBuffer(value),
        ($0.LedgerApdu value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BroadcastRequest, $0.BroadcastResponse>(
        'Broadcast',
        broadcast_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BroadcastRequest.fromBuffer(value),
        ($0.BroadcastResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CoinswapRequest, $0.CoinswapResponse>(
        'Coinswap',
        coinswap_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CoinswapRequest.fromBuffer(value),
        ($0.CoinswapResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.StatusResponse> status_Pre($grpc.ServiceCall call, $async.Future<$0.StatusRequest> request) async {
    return status(call, await request);
  }

  $async.Stream<$0.Utxo> utxos_Pre($grpc.ServiceCall call, $async.Future<$0.UtxosRequest> request) async* {
    yield* utxos(call, await request);
  }

  $async.Future<$0.AddressResponse> addresses_Pre($grpc.ServiceCall call, $async.Future<$0.AddressRequest> request) async {
    return addresses(call, await request);
  }

  $async.Future<$0.SpentResponse> spent_Pre($grpc.ServiceCall call, $async.Future<$0.SpentRequest> request) async {
    return spent(call, await request);
  }

  $async.Future<$0.CreateResponse> create_Pre($grpc.ServiceCall call, $async.Future<$0.CreateRequest> request) async {
    return create(call, await request);
  }

  $async.Future<$0.PsbtResponse> psbtCreate_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtCreateRequest> request) async {
    return psbtCreate(call, await request);
  }

  $async.Future<$0.PsbtResponse> psbtAddInput_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtAddInputRequest> request) async {
    return psbtAddInput(call, await request);
  }

  $async.Future<$0.PsbtResponse> psbtAddRecipient_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtAddRecipientRequest> request) async {
    return psbtAddRecipient(call, await request);
  }

  $async.Future<$0.PsbtGetRecipientsResponse> psbtGetRecipients_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtGetRecipientsRequest> request) async {
    return psbtGetRecipients(call, await request);
  }

  $async.Future<$0.PsbtResponse> psbtSign_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtSignRequest> request) async {
    return psbtSign(call, await request);
  }

  $async.Future<$0.PsbtResponse> psbtSignNonMweb_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtSignNonMwebRequest> request) async {
    return psbtSignNonMweb(call, await request);
  }

  $async.Future<$0.CreateResponse> psbtExtract_Pre($grpc.ServiceCall call, $async.Future<$0.PsbtExtractRequest> request) async {
    return psbtExtract(call, await request);
  }

  $async.Future<$0.LedgerApdu> ledgerExchange_Pre($grpc.ServiceCall call, $async.Future<$0.LedgerApdu> request) async {
    return ledgerExchange(call, await request);
  }

  $async.Future<$0.BroadcastResponse> broadcast_Pre($grpc.ServiceCall call, $async.Future<$0.BroadcastRequest> request) async {
    return broadcast(call, await request);
  }

  $async.Future<$0.CoinswapResponse> coinswap_Pre($grpc.ServiceCall call, $async.Future<$0.CoinswapRequest> request) async {
    return coinswap(call, await request);
  }

  $async.Future<$0.StatusResponse> status($grpc.ServiceCall call, $0.StatusRequest request);
  $async.Stream<$0.Utxo> utxos($grpc.ServiceCall call, $0.UtxosRequest request);
  $async.Future<$0.AddressResponse> addresses($grpc.ServiceCall call, $0.AddressRequest request);
  $async.Future<$0.SpentResponse> spent($grpc.ServiceCall call, $0.SpentRequest request);
  $async.Future<$0.CreateResponse> create($grpc.ServiceCall call, $0.CreateRequest request);
  $async.Future<$0.PsbtResponse> psbtCreate($grpc.ServiceCall call, $0.PsbtCreateRequest request);
  $async.Future<$0.PsbtResponse> psbtAddInput($grpc.ServiceCall call, $0.PsbtAddInputRequest request);
  $async.Future<$0.PsbtResponse> psbtAddRecipient($grpc.ServiceCall call, $0.PsbtAddRecipientRequest request);
  $async.Future<$0.PsbtGetRecipientsResponse> psbtGetRecipients($grpc.ServiceCall call, $0.PsbtGetRecipientsRequest request);
  $async.Future<$0.PsbtResponse> psbtSign($grpc.ServiceCall call, $0.PsbtSignRequest request);
  $async.Future<$0.PsbtResponse> psbtSignNonMweb($grpc.ServiceCall call, $0.PsbtSignNonMwebRequest request);
  $async.Future<$0.CreateResponse> psbtExtract($grpc.ServiceCall call, $0.PsbtExtractRequest request);
  $async.Future<$0.LedgerApdu> ledgerExchange($grpc.ServiceCall call, $0.LedgerApdu request);
  $async.Future<$0.BroadcastResponse> broadcast($grpc.ServiceCall call, $0.BroadcastRequest request);
  $async.Future<$0.CoinswapResponse> coinswap($grpc.ServiceCall call, $0.CoinswapRequest request);
}