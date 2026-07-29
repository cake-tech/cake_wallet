/// The api bodies the per-provider mocks answer with.
///
/// These are trimmed copies of the real responses in `test/exchange/fixtures/`, with the
/// amounts rounded off so the limits, rates and trade amounts the provider suite asserts are
/// exact values rather than whatever the market was doing when the fixtures were fetched.
/// Anything the providers do not read has been dropped.
///
/// They live apart from the mocks so `canned_responses_test.dart` can check them against the
/// generated schemas without pulling in the provider classes.
library;

// ── shared ───────────────────────────────────────────────────────────────────────────────

/// The addresses the suite's TradeRequest carries, echoed by the mocked exchanges.
const payoutAddress = "payout-address";
const refundAddress = "refund-address";

// ── ChangeNOW - btc to xmr, floating ─────────────────────────────────────────────────────

const changeNowTradeId = "cn-trade-1";
const changeNowPayinAddress = "bc1qchangenowdepositaddress";
const changeNowValidUntil = "2026-07-29T15:04:27.001Z";

const changeNowRange = '{"fromCurrency":"btc","fromNetwork":"btc","toCurrency":"xmr",'
    '"toNetwork":"xmr","flow":"standard","minAmount":0.001,"maxAmount":20}';

const changeNowEstimatedAmount = '{"fromCurrency":"btc","fromNetwork":"btc",'
    '"toCurrency":"xmr","toNetwork":"xmr","flow":"standard","type":"direct","rateId":null,'
    '"validUntil":null,"transactionSpeedForecast":"10-60","warningMessage":null,'
    '"depositFee":0,"withdrawalFee":0,"userId":null,"fromAmount":2,"toAmount":500}';

const changeNowCreateExchange = '{"fromAmount":2,"toAmount":500,"flow":"standard",'
    '"type":"direct","payinAddress":"$changeNowPayinAddress",'
    '"payoutAddress":"$payoutAddress","fromCurrency":"btc","toCurrency":"xmr",'
    '"refundAddress":"$refundAddress","id":"$changeNowTradeId","fromNetwork":"btc",'
    '"toNetwork":"xmr","payinExtraId":null,"payoutExtraId":null,"validUntil":null}';

const changeNowById = '{"id":"$changeNowTradeId","status":"confirming",'
    '"actionsAvailable":false,"fromCurrency":"btc","fromNetwork":"btc","toCurrency":"xmr",'
    '"toNetwork":"xmr","expectedAmountFrom":2,"expectedAmountTo":500,"amountFrom":2,'
    '"amountTo":500,"payinAddress":"$changeNowPayinAddress",'
    '"payoutAddress":"$payoutAddress","payinExtraId":null,"payoutExtraId":null,'
    '"refundAddress":"$refundAddress","refundExtraId":null,'
    '"createdAt":"2026-07-29T14:04:27.001Z","updatedAt":"2026-07-29T14:04:27.010Z",'
    '"validUntil":"$changeNowValidUntil","depositReceivedAt":null,'
    '"payinHash":"cn-payin-hash","payoutHash":"cn-payout-hash","fromLegacyTicker":"btc",'
    '"toLegacyTicker":"xmr","refundHash":null,"refundAmount":null,"userId":null}';

const changeNowNotFound = '{"error":"not_found","message":"Transaction not found"}';

// ── Exolix - btc to xmr, floating ────────────────────────────────────────────────────────

const exolixTradeId = "exolix-trade-1";
const exolixDepositAddress = "bc1qexolixdepositaddress";
const exolixCreatedAt = "2026-07-29T14:04:29.407Z";

/// `/rate` with `amount=1`, which is how fetchLimits asks for the pair's bounds.
const exolixUnitRate = '{"fromAmount":1,"toAmount":250,"rate":250,"message":null,'
    '"minAmount":0.001,"withdrawMin":0.01,"maxAmount":20,"priceImpact":"0"}';

/// `/rate` for the amount the user actually wants to send.
const exolixRate = '{"fromAmount":2,"toAmount":500,"rate":250,"message":null,'
    '"minAmount":0.001,"withdrawMin":0.01,"maxAmount":20,"priceImpact":"0"}';

const exolixTransaction = '{"id":"$exolixTradeId","amount":2,"amountTo":500,'
    '"coinFrom":{"coinCode":"BTC","coinName":"Bitcoin","network":"BTC",'
    '"networkName":"Bitcoin","networkShortName":"BTC","icon":"","memoName":"",'
    '"networkIcon":"","networkNotes":"","contract":null},'
    '"coinTo":{"coinCode":"XMR","coinName":"Monero","network":"XMR",'
    '"networkName":"Monero","networkShortName":"XMR","icon":"","memoName":"",'
    '"networkIcon":"","networkNotes":"","contract":null},'
    '"comment":null,"createdAt":"$exolixCreatedAt",'
    '"depositAddress":"$exolixDepositAddress","depositExtraId":null,'
    '"withdrawalAddress":"$payoutAddress","withdrawalExtraId":null,'
    '"refundAddress":"$refundAddress","refundExtraId":null,'
    '"hashIn":{"hash":"exolix-hash-in","link":null},'
    '"hashOut":{"hash":"exolix-hash-out","link":null},'
    '"rate":250,"rateType":"float","affiliateToken":null,"status":"confirmation",'
    '"source":"api","email":null,"clickId":null}';

const exolixNotFound = '{"message":"Transaction not found"}';

// ── StealthEX - btc to xmr, floating ─────────────────────────────────────────────────────

const stealthExTradeId = "stealthex-trade-1";
const stealthExDepositAddress = "bc1qstealthexdepositaddress";
const stealthExCreatedAt = "2026-07-29T14:04:37.519Z";

const stealthExRange = '{"min_amount":0.001,"max_amount":20}';

const stealthExEstimatedAmount = '{"estimated_amount":500}';

const stealthExExchange = '{"id":"$stealthExTradeId","status":"waiting","rate":"floating",'
    '"deposit":{"symbol":"btc","network":"mainnet","amount":2,"expected_amount":2,'
    '"address":"$stealthExDepositAddress","extra_id":null,"tx_hash":null,'
    '"address_explorer_url":"","tx_explorer_url":null},'
    '"withdrawal":{"symbol":"xmr","network":"mainnet","amount":500,"expected_amount":500,'
    '"address":"$payoutAddress","extra_id":null,"tx_hash":null,'
    '"address_explorer_url":"","tx_explorer_url":null},'
    '"refund_address":"$refundAddress","refund_extra_id":null,'
    '"created_at":"$stealthExCreatedAt","expires_at":null}';

const stealthExNotFound = '{"err":{"kind":"NotFound","details":"exchange not found"}}';

// ── LetsExchange - usdt to usdc, both erc20, floating ─────────────────────────────────────
//
// LetsExchange looks a trade's currencies up by ticker plus network, and a non-empty network
// tag has to match a tagged currency exactly - so this pair is two erc20 tokens rather than
// the btc/xmr pair the other providers use.

const letsExchangeTradeId = "le-trade-1";
const letsExchangeDepositAddress = "0xletsexchangedepositaddress";
const letsExchangeCreatedAt = "2026-07-29 17:04:31";
const letsExchangeExpiredAtSeconds = 1785335671;

const letsExchangeInfo = '{"deposit_min_amount":"10","deposit_max_amount":"50000",'
    '"min_amount":"10","max_amount":"50000","amount":"99","fee":"0","rate":"0.99",'
    '"profit":"0","withdrawal_fee":"0","extra_fee_amount":"0","rate_id":"le-rate-1",'
    '"rate_id_expired_at":0,"applied_promo_code_id":null,"networks_from":[],'
    '"networks_to":[],"deposit_amount_usdt":"100","expired_at":"1785333936912",'
    '"base_amount":"99"}';

const letsExchangeTransaction = '{"is_float":true,"status":"wait","type":"cex",'
    '"coin_from":"USDT","coin_to":"USDC","deposit_amount":"100",'
    '"withdrawal_amount":"99","withdrawal":"$payoutAddress","withdrawal_extra_id":null,'
    '"return":"$refundAddress","return_extra_id":null,"coin_from_network":"ERC20",'
    '"coin_to_network":"ERC20","deposit":"$letsExchangeDepositAddress",'
    '"deposit_extra_id":null,"rate":"0.99","fee":"0","revert":false,'
    '"transaction_id":"$letsExchangeTradeId","expired_at":$letsExchangeExpiredAtSeconds,'
    '"created_at":"$letsExchangeCreatedAt","hash_in":null,"hash_out":null,'
    '"confirmations":0,"need_confirmations":64,"aml_error_signals":[],"error_code":""}';

const letsExchangeNotFound = '{"error":"Transaction not found"}';

// ── Trocador - btc to xmr, floating ──────────────────────────────────────────────────────

const trocadorTradeId = "tr-trade-1";
const trocadorAddressProvider = "bc1qtrocadordepositaddress";
const trocadorDate = "2026-07-29T14:04:45.650325Z";

const trocadorCoin = '[{"name":"Bitcoin","ticker":"btc","network":"Mainnet","memo":false,'
    '"image":"","minimum":0.001,"maximum":20.0}]';

const trocadorNewRate = '{"trade_id":"tr-rate-1","date":"$trocadorDate",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":2,"amount_to":500,'
    '"provider":"ChangeNow","fixed":false,"payment":false,"status":"new",'
    '"quotes":{"markup":true,"quotes":[{"provider":"ChangeNow","amount_to":"500","eta":10,'
    '"fixed":"False","waste":"0","insurance":100,"kycrating":"A","logpolicy":"B"},'
    '{"provider":"Exolix","amount_to":"499","eta":12,"fixed":"False","waste":"-0.2",'
    '"insurance":100,"kycrating":"B","logpolicy":"B"}]}}';

const trocadorTrade = '{"trade_id":"$trocadorTradeId","date":"$trocadorDate","type":"api",'
    '"ticker_from":"btc","ticker_to":"xmr","coin_from":"Bitcoin","coin_to":"Monero",'
    '"network_from":"Mainnet","network_to":"Mainnet","amount_from":2,"amount_to":500,'
    '"provider":"ChangeNow","fixed":false,"payment":false,"status":"waiting",'
    '"address_provider":"$trocadorAddressProvider","address_provider_memo":"tr-memo",'
    '"address_user":"$payoutAddress","address_user_memo":"",'
    '"refund_address":"$refundAddress","refund_address_memo":"",'
    '"password":"tr-password","id_provider":"tr-provider-id","affiliate_partner":"Cake"}';

// ── SwapTrade - btc to xmr, floating only ────────────────────────────────────────────────

const swapTradeTradeId = "st-order-1";
const swapTradeServerAddress = "bc1qswaptradedepositaddress";
const swapTradeCreatedAt = "2026-07-29T14:04:52.327Z";

const swapTradeCoins = '{"success":true,"status":200,"msg":"Fetch Coins successfully !",'
    '"data":[{"id":"BTC","name":"Bitcoin","network":"BTC","price":"64000","min":"0.001",'
    '"max":"20","memo":false,"enabled":true},'
    '{"id":"XMR","name":"Monero","network":"XMR","price":"256","min":"0.1","max":"5000",'
    '"memo":false,"enabled":true}]}';

const swapTradeRate = '{"success":true,"status":200,"msg":"Fetch Full Rate successfully !",'
    '"data":{"price":"250","symbol":"BTCXMR"}}';

const swapTradeCreateOrder = '{"success":true,"status":200,'
    '"msg":"Create Order successfully !","data":{"order_id":"$swapTradeTradeId",'
    '"server_address":"$swapTradeServerAddress","amount_receive":"500"}}';

const swapTradeOrder = '{"success":true,"status":200,"msg":"Fetch Order successfully !",'
    '"data":{"id":47063,"order_id":"$swapTradeTradeId","coin_send":"BTC",'
    '"coin_send_network":"BTC","amount_send":"2","coin_receive":"XMR",'
    '"coin_receive_network":"XMR","amount_receive":"500","rate_type":"dynamic",'
    '"recipient":"$payoutAddress","server_address":"$swapTradeServerAddress",'
    '"memo":"st-memo","status":"5","created_at":"$swapTradeCreatedAt",'
    '"updated_at":"$swapTradeCreatedAt","service":"cake",'
    '"refund_address":"$refundAddress"}}';

const swapTradeOrderNotFound = '{"success":false,"status":400,"msg":"Order not found",'
    '"errors":[{"msg":"Order not found"}]}';

// ── XOSwap - btc to xmr, floating ────────────────────────────────────────────────────────

const xoSwapTradeId = "xo-order-1";
const xoSwapPayInAddress = "bc1qxoswapdepositaddress";
const xoSwapCreatedAt = "2026-07-29T14:04:41.678Z";

/// Two market makers for the pair. The provider is expected to take the best output the
/// requested amount is eligible for, so the second one - cheaper but with a lower ceiling -
/// is there to be beaten.
const xoSwapPairRates = "["
    '{"amount":{"assetId":"XMR","value":250},"expiry":1785333919000,"id":"xo-rate-1",'
    '"max":{"assetId":"BTC","value":10},"min":{"assetId":"BTC","value":0.001},'
    '"minerFee":{"assetId":"XMR","value":0},"pairId":"BTC_XMR","features":[],'
    '"sponsoredByCampaignId":null},'
    '{"amount":{"assetId":"XMR","value":200},"expiry":1785333919000,"id":"xo-rate-2",'
    '"max":{"assetId":"BTC","value":5},"min":{"assetId":"BTC","value":0.002},'
    '"minerFee":{"assetId":"XMR","value":0},"pairId":"BTC_XMR","features":[],'
    '"sponsoredByCampaignId":null}]';

const xoSwapOrder = '{"amount":{"assetId":"BTC","value":"2"},'
    '"toAmount":{"assetId":"XMR","value":"500"},"createdAt":"$xoSwapCreatedAt",'
    '"fromAddress":"$refundAddress","fromTransactionId":"","id":"$xoSwapTradeId",'
    '"message":"","pairId":"BTC_XMR","payInAddress":"$xoSwapPayInAddress",'
    '"providerOrderId":"xo-provider-order-1","rateId":"xo-rate-1",'
    '"toAddress":"$payoutAddress","toTransactionId":"","updatedAt":"$xoSwapCreatedAt",'
    '"status":"inProgress","extraFeatures":{},"sponsoredByCampaignId":null}';

const xoSwapNotFound =
    '{"code":"NOT_FOUND","error":"NotFound","message":"order not found"}';

// ── Chainflip - btc to eth ───────────────────────────────────────────────────────────────
//
// Chainflip only lists a handful of chains, so this pair is btc -> eth.

const chainflipIssuedBlock = 14138313;
const chainflipChannelId = 13128;
const chainflipTradeId = "$chainflipIssuedBlock-bitcoin-$chainflipChannelId";
const chainflipDepositAddress = "bc1qchainflipdepositaddress";

const chainflipAssets = '{"assets":['
    '{"enabled":true,"id":"btc.btc","direction":"both","ticker":"BTC","name":"Bitcoin",'
    '"network":"Bitcoin","networkLogo":"","assetLogo":"","decimals":8,'
    '"minimalAmount":0.001,"minimalAmountNative":"100000","usdPrice":64000,'
    '"usdPriceNative":"64000000000","platforms":["chainflip"]},'
    '{"enabled":true,"id":"eth.eth","direction":"both","ticker":"ETH","name":"Ethereum",'
    '"network":"Ethereum","networkLogo":"","assetLogo":"","decimals":18,'
    '"minimalAmount":0.01,"minimalAmountNative":"10000000000000000","usdPrice":2000,'
    '"usdPriceNative":"2000000000","platforms":["chainflip"]}]}';

/// Two quotes; the provider is expected to take the one paying out the most.
const chainflipQuotes = "["
    '{"type":"regular","ingressAsset":"btc.btc","ingressAmountNative":"200000000",'
    '"intermediateAsset":"usdc.eth","intermediateAmountNative":"128000000000",'
    '"egressAsset":"eth.eth","egressAmountNative":"60000000000000000000",'
    '"includedFees":[{"type":"network","asset":"usdc.eth","amountNative":"6451953"}],'
    '"recommendedSlippageTolerancePercent":2.5,"lowLiquidityWarning":false,'
    '"poolInfo":[{"baseAsset":"btc.btc","quoteAsset":"usdc.eth",'
    '"fee":{"type":"liquidity","asset":"btc.btc","amountNative":"0"}}],'
    '"estimatedDurationSeconds":1014,'
    '"estimatedDurationsSeconds":{"deposit":906,"swap":12,"egress":96},'
    '"estimatedPrice":30,"numberOfChunks":1,"chunkIntervalBlocks":2},'
    '{"type":"regular","ingressAsset":"btc.btc","ingressAmountNative":"200000000",'
    '"egressAsset":"eth.eth","egressAmountNative":"59000000000000000000",'
    '"includedFees":[],"recommendedSlippageTolerancePercent":2.5,'
    '"lowLiquidityWarning":false,"poolInfo":[],"estimatedDurationSeconds":1014,'
    '"estimatedDurationsSeconds":{"deposit":906,"swap":12,"egress":96},'
    '"estimatedPrice":29.5}]';

const chainflipSwap = '{"id":61978,"address":"$chainflipDepositAddress",'
    '"issuedBlock":$chainflipIssuedBlock,"network":"Bitcoin",'
    '"channelId":$chainflipChannelId,"sourceExpiryBlock":25645142,"explorerUrl":"",'
    '"channelOpeningFee":0,"channelOpeningFeeNative":"0"}';

const chainflipStatus = '{"id":61978,"platform":"chainflip","status":{"state":"swapping",'
    '"sourceAsset":"btc.btc","destinationAsset":"eth.eth",'
    '"destinationAddress":"$payoutAddress",'
    '"depositChannel":{"id":"$chainflipTradeId","createdAt":1785333864000,'
    '"brokerCommissionBps":5,"depositAddress":"$chainflipDepositAddress",'
    '"sourceChainExpiryBlock":"25645142","estimatedExpiryTime":1785407934000,'
    '"isExpired":false,"openedThroughBackend":false},'
    '"deposit":{"amountNative":"200000000","transactionReference":"cf-deposit-tx"},'
    '"swapEgress":{"amountNative":"60000000000000000000",'
    '"transactionReference":"cf-egress-tx"},'
    '"estimatedDurationSeconds":168,"sourceChainRequiredBlockConfirmations":5,"fees":[],'
    '"lastStateChainUpdateAt":1785333896842}}';

// ── Near Intents - btc to zec ────────────────────────────────────────────────────────────
//
// Near Intents has no monero asset, so this pair is btc -> zec.

const nearDepositAddress = "near-deposit-address";
const nearBtcAsset = "nep141:btc.omft.near";
const nearZecAsset = "nep141:zec.omft.near";

const nearTokens = "["
    '{"assetId":"$nearBtcAsset","decimals":8,"blockchain":"btc","symbol":"BTC",'
    '"price":64000,"priceUpdatedAt":"2026-07-29T14:04:00.457Z",'
    '"coingeckoId":"bitcoin"},'
    '{"assetId":"$nearZecAsset","decimals":8,"blockchain":"zec","symbol":"ZEC",'
    '"price":256,"priceUpdatedAt":"2026-07-29T14:04:00.457Z","coingeckoId":"zcash"}]';

String _nearQuoteRequest({
  required bool dry,
  required String recipient,
  required String refundTo,
}) =>
    '{"dry":$dry,"depositMode":"SIMPLE","swapType":"EXACT_INPUT","slippageTolerance":100,'
    '"originAsset":"$nearBtcAsset","depositType":"ORIGIN_CHAIN",'
    '"destinationAsset":"$nearZecAsset","amount":"200000000","refundTo":"$refundTo",'
    '"refundType":"ORIGIN_CHAIN","recipient":"$recipient",'
    '"recipientType":"DESTINATION_CHAIN","deadline":"2026-07-29T15:04:56.287Z",'
    '"confidentiality":"public","quoteWaitingTimeMs":0,"appFees":[],"insured":false}';

String _nearQuote({required bool withDepositAddress}) =>
    '{"amountIn":"200000000","amountInFormatted":"2","amountInUsd":"128000",'
    '"minAmountIn":"200000000","amountOut":"50000000000","amountOutFormatted":"500",'
    '"amountOutUsd":"128000","minAmountOut":"49500000000","timeEstimate":25,'
    '"refundFee":"0","withdrawFee":"0"'
    '${withDepositAddress ? ',"depositAddress":"$nearDepositAddress","depositMemo":null' : ""}}';

/// The dry run fetchRate uses: a price, but no address to pay into.
final nearDryQuote =
    '{"quote":${_nearQuote(withDepositAddress: false)},'
    '"quoteRequest":${_nearQuoteRequest(dry: true, recipient: "t1nearzecdummyaddress", refundTo: "bc1qnearbtcdummyaddress")},'
    '"signature":"ed25519:near-signature","timestamp":"2026-07-29T14:04:55.326Z",'
    '"correlationId":"near-correlation-1"}';

/// The live quote createTrade uses: same price, plus the deposit address that becomes the
/// trade id.
final nearLiveQuote =
    '{"quote":${_nearQuote(withDepositAddress: true)},'
    '"quoteRequest":${_nearQuoteRequest(dry: false, recipient: payoutAddress, refundTo: refundAddress)},'
    '"signature":"ed25519:near-signature","timestamp":"2026-07-29T14:04:56.375Z",'
    '"correlationId":"near-correlation-2"}';

final nearStatus =
    '{"status":"PROCESSING","updatedAt":"2026-07-29T14:04:56.761Z",'
    '"correlationId":"near-correlation-2","swapDetails":{"depositedAmount":"200000000",'
    '"depositedAmountFormatted":"2","intentHashes":[],"nearTxHashes":[],'
    '"amountIn":"200000000","amountInFormatted":"2","amountOut":"50000000000",'
    '"amountOutFormatted":"500","slippage":100,"refundedAmount":"0",'
    '"refundedAmountFormatted":"0","refundReason":null,"refundFee":"0","withdrawFee":"0",'
    '"originChainTxHashes":[{"hash":"near-origin-tx","explorerUrl":""}],'
    '"destinationChainTxHashes":[]},"quoteResponse":$nearLiveQuote}';

const nearNotFound = '{"message":"not found"}';

// ── Swaps.xyz - eth to usdt, same chain ──────────────────────────────────────────────────
//
// Swaps.xyz is an evm router, so this pair is a same-chain eth -> usdt swap.

const swapsXyzTxId = "0xswapsxyzswap1";
const swapsXyzRouter = "0x1b6257CAE0a0f5D0F1E0F0f0F0f0f0F0f0F0F0F0";
const swapsXyzSwapAndExecute = "0x9be111d1000000000000000000000000000000000000000000000000";
const swapsXyzNativeAddress = "0x0000000000000000000000000000000000000000";
const swapsXyzUsdtAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const swapsXyzTimestamp = 1785333864;

const swapsXyzChainList = '[{"chainId":1,"name":"Ethereum","vmId":"evm"}]';

const _swapsXyzEthToken = '{"chainId":1,"address":"$swapsXyzNativeAddress","name":"Ether",'
    '"symbol":"ETH","decimals":18,"isNative":true,"logo":"","minAmount":null,'
    '"maxAmount":null}';

/// getPaths without a destination: the provider uses this only to learn which token
/// addresses live on the chain.
const swapsXyzTokenPaths = '{"srcChainId":1,"srcToken":$_swapsXyzEthToken,'
    '"paths":[{"chainId":1,"tokens":[{"chainId":1,"address":"$swapsXyzUsdtAddress",'
    '"name":"Tether USD","symbol":"USDT","decimals":6,"isNative":false,'
    '"minAmount":"0.01","maxAmount":"100000"}],"supportsExactAmountIn":true,'
    '"supportsExactAmountOut":false}]}';

/// getPaths for the actual pair, which is where the limits come from.
const swapsXyzPairPaths = '{"srcChainId":1,"srcToken":$_swapsXyzEthToken,'
    '"paths":[{"chainId":1,"tokens":"all","supportsExactAmountIn":true,'
    '"supportsExactAmountOut":false,'
    '"amountLimits":{"minAmount":"0.01","maxAmount":"100"}}]}';

const _swapsXyzAmountIn = '{"amount":"2000000000000000000",'
    '"address":"$swapsXyzNativeAddress","chainId":1,"isNative":true,"name":"Ether",'
    '"symbol":"ETH","decimals":18,"usdAmount":4000}';
const _swapsXyzAmountOut = '{"amount":"4000000000","address":"$swapsXyzUsdtAddress",'
    '"chainId":1,"isNative":false,"name":"Tether USD","symbol":"USDT","decimals":6,'
    '"usdAmount":4000}';
const _swapsXyzAmountOutMin = '{"amount":"3960000000","address":"$swapsXyzUsdtAddress",'
    '"chainId":1,"isNative":false,"name":"Tether USD","symbol":"USDT","decimals":6,'
    '"usdAmount":3960}';
const _swapsXyzFee = '{"amount":"2000000000000000","address":"$swapsXyzNativeAddress",'
    '"chainId":1,"isNative":true,"name":"Ether","symbol":"ETH","decimals":18,'
    '"usdAmount":4}';

const swapsXyzQuote = '{"amountIn":$_swapsXyzAmountIn,"amountInMax":$_swapsXyzAmountIn,'
    '"amountOut":$_swapsXyzAmountOut,"amountOutMin":$_swapsXyzAmountOutMin,'
    '"protocolFee":$_swapsXyzFee,"applicationFee":$_swapsXyzFee,"bridgeFee":null,'
    '"exchangeRate":2000,"estimatedTxTime":30,"estimatedPriceImpact":0.01,"vmId":"evm",'
    '"requiresTokenApproval":false,"requiresRegisterTransaction":false,'
    '"executionsType":"standard"}';

/// The source token is native ether, so the router call carries it as the tx value.
const swapsXyzTxValue = "2000000000000000000";

const swapsXyzAction = '{"tx":{"to":"$swapsXyzRouter","chainId":1,'
    '"data":"$swapsXyzSwapAndExecute","value":"$swapsXyzTxValue"},'
    '"txId":"$swapsXyzTxId","vmId":"evm",'
    '"amountIn":$_swapsXyzAmountIn,"amountInMax":$_swapsXyzAmountIn,'
    '"amountOut":$_swapsXyzAmountOut,"amountOutMin":$_swapsXyzAmountOutMin,'
    '"protocolFee":$_swapsXyzFee,"applicationFee":$_swapsXyzFee,"exchangeRate":2000,'
    '"estimatedTxTime":30,"estimatedPriceImpact":0.01,"requiresTokenApproval":false,'
    '"requiresRegisterTransaction":false,"executionsType":"standard","bridgeIds":[],'
    '"allRoutes":[]}';

const swapsXyzStatus = '{"status":"pending","sender":"$refundAddress","srcChainId":1,'
    '"dstChainId":1,"txId":"$swapsXyzTxId","usdValue":4000,'
    '"srcTx":{"txHash":"0xswapsxyzsrctx","chainId":1,"timestamp":$swapsXyzTimestamp,'
    '"toAddress":"$swapsXyzRouter","paymentToken":$_swapsXyzAmountIn},'
    '"dstTx":{"txHash":"0xswapsxyzdsttx","chainId":1,"timestamp":$swapsXyzTimestamp,'
    '"toAddress":"$payoutAddress","paymentToken":$_swapsXyzAmountOut}}';

const swapsXyzNotFound = '{"success":false,"error":{"code":"NOT_FOUND",'
    '"name":"BackendError","message":"Failed to get tx status.","title":"Not found",'
    '"statusCode":404,"timestamp":"2026-07-29T14:05:06.967Z"}}';

// ── Jupiter - sol to usdc on solana ──────────────────────────────────────────────────────
//
// Jupiter is solana-only, so this pair is sol -> usdc on solana.

const jupiterRequestId = "jup-request-1";
const jupiterSolMint = "So11111111111111111111111111111111111111112";
const jupiterUsdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const jupiterTransaction = "AQABjupiter-signed-transaction-payload";

/// Without a taker the endpoint only prices the swap; with one it also builds the
/// transaction the wallet has to sign.
String jupiterOrder({required bool withTaker}) =>
    '{"requestId":"$jupiterRequestId","inputMint":"$jupiterSolMint",'
    '"outputMint":"$jupiterUsdcMint","inAmount":"2000000000","outAmount":"400000000",'
    '"otherAmountThreshold":"${withTaker ? "396000000" : "400000000"}",'
    '"swapType":"aggregator","swapMode":"ExactIn","slippageBps":${withTaker ? 100 : 0},'
    '"priceImpactPct":"0.0001","router":"metis","mode":"ultra","gasless":false,'
    '"platformFee":{"feeBps":50,"feeMint":"$jupiterUsdcMint"},'
    '"signatureFeeLamports":${withTaker ? 5000 : 0},"integratorFeeLamports":0,'
    '"prioritizationFeeLamports":${withTaker ? 10000 : 0},"rentFeeLamports":0,'
    '"inUsdValue":400,"outUsdValue":400,"swapUsdValue":400,"totalTime":120,'
    '${withTaker ? '"taker":"$refundAddress","transaction":"$jupiterTransaction",' : ""}'
    '"routePlan":[{"percent":100,"bps":10000,"swapInfo":{"ammKey":"jup-amm-1",'
    '"label":"Orca","inputMint":"$jupiterSolMint","outputMint":"$jupiterUsdcMint",'
    '"inAmount":"2000000000","outAmount":"400000000"}}]}';
