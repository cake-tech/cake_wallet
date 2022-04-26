#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unused_mut)]
#![allow(unused_assignments)]

pub mod bitcoind_client;
mod cli;
mod convert;
mod disk;
mod hex_utils;

use crate::bitcoind_client::BitcoindClient;
use crate::disk::FilesystemLogger;
use bitcoin::blockdata::constants::genesis_block;
use bitcoin::blockdata::transaction::Transaction;
use bitcoin::consensus::encode;
use bitcoin::network::constants::Network;
use bitcoin::secp256k1::Secp256k1;
use bitcoin::BlockHash;
use bitcoin_bech32::WitnessProgram;
use lightning::chain;
use lightning::chain::chaininterface::{BroadcasterInterface, ConfirmationTarget, FeeEstimator};
use lightning::chain::chainmonitor;
use lightning::chain::keysinterface::{InMemorySigner, KeysInterface, KeysManager, Recipient};
use lightning::chain::{BestBlock, Filter, Watch};
use lightning::ln::channelmanager;
use lightning::ln::channelmanager::{
	ChainParameters, ChannelManagerReadArgs, SimpleArcChannelManager,
};
use lightning::ln::peer_handler::{IgnoringMessageHandler, MessageHandler, SimpleArcPeerManager};
use lightning::ln::{PaymentHash, PaymentPreimage, PaymentSecret};
use lightning::routing::network_graph::{NetGraphMsgHandler, NetworkGraph};
use lightning::routing::scoring::ProbabilisticScorer;
use lightning::util::config::UserConfig;
use lightning::util::events::{Event, PaymentPurpose};
use lightning::util::ser::ReadableArgs;
use lightning_background_processor::{BackgroundProcessor, Persister};
use lightning_block_sync::{init, rpc};
use lightning_block_sync::poll;
use lightning_block_sync::SpvClient;
use lightning_block_sync::UnboundedCache;
use lightning_invoice::payment;
use lightning_invoice::utils::DefaultRouter;
use lightning_net_tokio::SocketDescriptor;
use lightning_persister::FilesystemPersister;
use rand::{thread_rng, Rng};
use std::collections::hash_map::Entry;
use std::collections::HashMap;
use std::fmt;
use std::fs;
use std::fs::File;
use std::io;
use std::io::Write;
use std::ops::Deref;
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};

pub(crate) enum HTLCStatus {
	Pending,
	Succeeded,
	Failed,
}

pub(crate) struct MillisatAmount(Option<u64>);

impl fmt::Display for MillisatAmount {
	fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
		match self.0 {
			Some(amt) => write!(f, "{}", amt),
			None => write!(f, "unknown"),
		}
	}
}

pub(crate) struct PaymentInfo {
	preimage: Option<PaymentPreimage>,
	secret: Option<PaymentSecret>,
	status: HTLCStatus,
	amt_msat: MillisatAmount,
}

pub(crate) type PaymentInfoStorage = Arc<Mutex<HashMap<PaymentHash, PaymentInfo>>>;

type ChainMonitor = chainmonitor::ChainMonitor<
	InMemorySigner,
	Arc<dyn Filter + Send + Sync>,
	Arc<BitcoindClient>,
	Arc<BitcoindClient>,
	Arc<FilesystemLogger>,
	Arc<FilesystemPersister>,
>;

pub(crate) type PeerManager = SimpleArcPeerManager<
	SocketDescriptor,
	ChainMonitor,
	BitcoindClient,
	BitcoindClient,
	dyn chain::Access + Send + Sync,
	FilesystemLogger,
>;

pub(crate) type ChannelManager =
	SimpleArcChannelManager<ChainMonitor, BitcoindClient, BitcoindClient, FilesystemLogger>;

pub(crate) type InvoicePayer<E> = payment::InvoicePayer<
	Arc<ChannelManager>,
	Router,
	Arc<Mutex<ProbabilisticScorer<Arc<NetworkGraph>>>>,
	Arc<FilesystemLogger>,
	E,
>;

type Router = DefaultRouter<Arc<NetworkGraph>, Arc<FilesystemLogger>>;

struct DataPersister {
	data_dir: String,
}

impl
	Persister<
		InMemorySigner,
		Arc<ChainMonitor>,
		Arc<BitcoindClient>,
		Arc<KeysManager>,
		Arc<BitcoindClient>,
		Arc<FilesystemLogger>,
	> for DataPersister
{
	fn persist_manager(&self, channel_manager: &ChannelManager) -> Result<(), std::io::Error> {
		FilesystemPersister::persist_manager(self.data_dir.clone(), channel_manager)
	}

	fn persist_graph(&self, network_graph: &NetworkGraph) -> Result<(), std::io::Error> {
		if FilesystemPersister::persist_network_graph(self.data_dir.clone(), network_graph).is_err()
		{
			// Persistence errors here are non-fatal as we can just fetch the routing graph
			// again later, but they may indicate a disk error which could be fatal elsewhere.
			eprintln!("Warning: Failed to persist network graph, check your disk and permissions");
		}

		Ok(())
	}
}

async fn handle_ldk_events(
	channel_manager: Arc<ChannelManager>, bitcoind_client: Arc<BitcoindClient>,
	keys_manager: Arc<KeysManager>, inbound_payments: PaymentInfoStorage,
	outbound_payments: PaymentInfoStorage, network: Network, event: &Event,
) {
	match event {
		Event::FundingGenerationReady {
			temporary_channel_id,
			channel_value_satoshis,
			output_script,
			..
		} => {
			// Construct the raw transaction with one output, that is paid the amount of the
			// channel.
			let addr = WitnessProgram::from_scriptpubkey(
				&output_script[..],
				match network {
					Network::Bitcoin => bitcoin_bech32::constants::Network::Bitcoin,
					Network::Testnet => bitcoin_bech32::constants::Network::Testnet,
					Network::Regtest => bitcoin_bech32::constants::Network::Regtest,
					Network::Signet => bitcoin_bech32::constants::Network::Signet,
				},
			)
			.expect("Lightning funding tx should always be to a SegWit output")
			.to_address();
			let mut outputs = vec![HashMap::with_capacity(1)];
			outputs[0].insert(addr, *channel_value_satoshis as f64 / 100_000_000.0);
			let raw_tx = bitcoind_client.create_raw_transaction(outputs).await;

			// Have your wallet put the inputs into the transaction such that the output is
			// satisfied.
			let funded_tx = bitcoind_client.fund_raw_transaction(raw_tx).await;

			// Sign the final funding transaction and broadcast it.
			let signed_tx = bitcoind_client.sign_raw_transaction_with_wallet(funded_tx.hex).await;
			assert_eq!(signed_tx.complete, true);
			let final_tx: Transaction =
				encode::deserialize(&hex_utils::to_vec(&signed_tx.hex).unwrap()).unwrap();
			// Give the funding transaction back to LDK for opening the channel.
			if channel_manager
				.funding_transaction_generated(&temporary_channel_id, final_tx)
				.is_err()
			{
				println!(
					"\nERROR: Channel went away before we could fund it. The peer disconnected or refused the channel.");
				print!("> ");
				io::stdout().flush().unwrap();
			}
		}
		Event::PaymentReceived { payment_hash, purpose, amt, .. } => {
			let mut payments = inbound_payments.lock().unwrap();
			let (payment_preimage, payment_secret) = match purpose {
				PaymentPurpose::InvoicePayment { payment_preimage, payment_secret, .. } => {
					(*payment_preimage, Some(*payment_secret))
				}
				PaymentPurpose::SpontaneousPayment(preimage) => (Some(*preimage), None),
			};
			let status = match channel_manager.claim_funds(payment_preimage.unwrap()) {
				true => {
					println!(
						"\nEVENT: received payment from payment hash {} of {} millisatoshis",
						hex_utils::hex_str(&payment_hash.0),
						amt
					);
					print!("> ");
					io::stdout().flush().unwrap();
					HTLCStatus::Succeeded
				}
				_ => HTLCStatus::Failed,
			};
			match payments.entry(*payment_hash) {
				Entry::Occupied(mut e) => {
					let payment = e.get_mut();
					payment.status = status;
					payment.preimage = payment_preimage;
					payment.secret = payment_secret;
				}
				Entry::Vacant(e) => {
					e.insert(PaymentInfo {
						preimage: payment_preimage,
						secret: payment_secret,
						status,
						amt_msat: MillisatAmount(Some(*amt)),
					});
				}
			}
		}
		Event::PaymentSent { payment_preimage, payment_hash, fee_paid_msat, .. } => {
			let mut payments = outbound_payments.lock().unwrap();
			for (hash, payment) in payments.iter_mut() {
				if *hash == *payment_hash {
					payment.preimage = Some(*payment_preimage);
					payment.status = HTLCStatus::Succeeded;
					println!(
						"\nEVENT: successfully sent payment of {} millisatoshis{} from \
								 payment hash {:?} with preimage {:?}",
						payment.amt_msat,
						if let Some(fee) = fee_paid_msat {
							format!(" (fee {} msat)", fee)
						} else {
							"".to_string()
						},
						hex_utils::hex_str(&payment_hash.0),
						hex_utils::hex_str(&payment_preimage.0)
					);
					print!("> ");
					io::stdout().flush().unwrap();
				}
			}
		}
		Event::OpenChannelRequest { .. } => {
			// Unreachable, we don't set manually_accept_inbound_channels
		}
		Event::PaymentPathSuccessful { .. } => {}
		Event::PaymentPathFailed { .. } => {}
		Event::PaymentFailed { payment_hash, .. } => {
			print!(
				"\nEVENT: Failed to send payment to payment hash {:?}: exhausted payment retry attempts",
				hex_utils::hex_str(&payment_hash.0)
			);
			print!("> ");
			io::stdout().flush().unwrap();

			let mut payments = outbound_payments.lock().unwrap();
			if payments.contains_key(&payment_hash) {
				let payment = payments.get_mut(&payment_hash).unwrap();
				payment.status = HTLCStatus::Failed;
			}
		}
		Event::PaymentForwarded { fee_earned_msat, claim_from_onchain_tx } => {
			let from_onchain_str = if *claim_from_onchain_tx {
				"from onchain downstream claim"
			} else {
				"from HTLC fulfill message"
			};
			if let Some(fee_earned) = fee_earned_msat {
				println!(
					"\nEVENT: Forwarded payment, earning {} msat {}",
					fee_earned, from_onchain_str
				);
			} else {
				println!("\nEVENT: Forwarded payment, claiming onchain {}", from_onchain_str);
			}
			print!("> ");
			io::stdout().flush().unwrap();
		}
		Event::PendingHTLCsForwardable { time_forwardable } => {
			let forwarding_channel_manager = channel_manager.clone();
			let min = time_forwardable.as_millis() as u64;
			tokio::spawn(async move {
				let millis_to_sleep = thread_rng().gen_range(min, min * 5) as u64;
				tokio::time::sleep(Duration::from_millis(millis_to_sleep)).await;
				forwarding_channel_manager.process_pending_htlc_forwards();
			});
		}
		Event::SpendableOutputs { outputs } => {
			let destination_address = bitcoind_client.get_new_address().await;
			let output_descriptors = &outputs.iter().map(|a| a).collect::<Vec<_>>();
			let tx_feerate =
				bitcoind_client.get_est_sat_per_1000_weight(ConfirmationTarget::Normal);
			let spending_tx = keys_manager
				.spend_spendable_outputs(
					output_descriptors,
					Vec::new(),
					destination_address.script_pubkey(),
					tx_feerate,
					&Secp256k1::new(),
				)
				.unwrap();
			bitcoind_client.broadcast_transaction(&spending_tx);
		}
		Event::ChannelClosed { channel_id, reason, user_channel_id: _ } => {
			println!(
				"\nEVENT: Channel {} closed due to: {:?}",
				hex_utils::hex_str(channel_id),
				reason
			);
			print!("> ");
			io::stdout().flush().unwrap();
		}
		Event::DiscardFunding { .. } => {
			// A "real" node should probably "lock" the UTXOs spent in funding transactions until
			// the funding transaction either confirms, or this event is generated.
		}
	}
}

pub async fn start_ldk(
    rpc_info: String,
    ldk_storage_path: String,
    port: u16,
    network: String,
    node_name: String,
    address: String,
    mnemonic_key_phrase: String,
    callback: Box<dyn Fn(&str)>
) -> String {
    callback("...starting ldk");

    // setup args
	let args: cli::LdkUserInfo = cli::setup_ldkuserinfo(
		rpc_info.clone(),
		ldk_storage_path.clone(),
		port,
		network.clone(),
        node_name.clone(),
		address.clone()
	).unwrap();

    callback(format!("{:?}", args).as_str());

	// Initialize the LDK data directory if necessary.
	let ldk_data_dir = format!("{}/.ldk", args.ldk_storage_dir_path);
	fs::create_dir_all(ldk_data_dir.clone()).unwrap();

    callback("Initialize the LDK data directory if necessary.");

	// Initialize our bitcoind client.
	let bitcoind_client = match BitcoindClient::new(
		args.bitcoind_rpc_host.clone(),
		args.bitcoind_rpc_port,
		args.bitcoind_rpc_username.clone(),
		args.bitcoind_rpc_password.clone(),
		tokio::runtime::Handle::current(),
	)
	.await
	{
		Ok(client) => Arc::new(client),
		Err(e) => {
			let msg = format!("Failed to connect to bitcoind client: {}", e);
            callback(msg.as_str());
			return msg
		}
	};

    callback("Initialize our bitcoind client.");

	// Check that the bitcoind we've connected to is running the network we expect
	let bitcoind_chain = bitcoind_client.get_blockchain_info().await.chain;
	if bitcoind_chain
		!= match args.network {
			bitcoin::Network::Bitcoin => "main",
			bitcoin::Network::Testnet => "test",
			bitcoin::Network::Regtest => "regtest",
			bitcoin::Network::Signet => "signet",
		} {
		let msg = format!(
			"Chain argument ({}) didn't match bitcoind chain ({})",
			args.network, bitcoind_chain
		);
        callback(msg.as_str());
		return msg;
	}

    callback("Check that the bitcoind we've connected to is running the network we expect");

	// ## Setup
	// Step 1: Initialize the FeeEstimator

	// BitcoindClient implements the FeeEstimator trait, so it'll act as our fee estimator.
	let fee_estimator = bitcoind_client.clone();

    callback("Step 1: Initialize the FeeEstimator");

	// Step 2: Initialize the Logger
	let logger = Arc::new(FilesystemLogger::new(ldk_data_dir.clone()));

    callback("Step 2: Initialize the Logger");

	// Step 3: Initialize the BroadcasterInterface

	// BitcoindClient implements the BroadcasterInterface trait, so it'll act as our transaction
	// broadcaster.
	let broadcaster = bitcoind_client.clone();

    callback("Step 3: Initialize the BroadcasterInterface");

	// Step 4: Initialize Persist
	let persister = Arc::new(FilesystemPersister::new(ldk_data_dir.clone()));

    callback("Step 4: Initialize Persist");

	// Step 5: Initialize the ChainMonitor
	let chain_monitor: Arc<ChainMonitor> = Arc::new(chainmonitor::ChainMonitor::new(
		None,
		broadcaster.clone(),
		logger.clone(),
		fee_estimator.clone(),
		persister.clone(),
	));

    callback("Step 5: Initialize the ChainMonitor");

	// Step 6: Initialize the KeysManager

	// The key seed that we use to derive the node privkey (that corresponds to the node pubkey) and
	// other secret key material.
	let keys_seed_path = format!("{}/keys_seed", ldk_data_dir.clone());
	let keys_seed = if let Ok(seed) = fs::read(keys_seed_path.clone()) {
		assert_eq!(seed.len(), 32);
		let mut key = [0; 32];
		key.copy_from_slice(&seed);
		key
	} else {
		let mut key = [0; 32];
		thread_rng().fill_bytes(&mut key);
		match File::create(keys_seed_path.clone()) {
			Ok(mut f) => {
				f.write_all(&key).expect("Failed to write node keys seed to disk");
				f.sync_all().expect("Failed to sync node keys seed to disk");
			}
			Err(e) => {
				let msg = format!("ERROR: Unable to create keys seed file {}: {}", keys_seed_path, e);
				callback(msg.as_str());
                return msg;
			}
		}
		key
	};
	let cur = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap();
	let keys_manager = Arc::new(KeysManager::new(&keys_seed, cur.as_secs(), cur.subsec_nanos()));

    callback("Step 6: Initialize the KeysManager");

	// Step 7: Read ChannelMonitor state from disk
	let mut channelmonitors = persister.read_channelmonitors(keys_manager.clone()).unwrap();

    callback("Step 7: Read ChannelMonitor state from disk");

	// Step 8: Initialize the ChannelManager
	let mut user_config = UserConfig::default();
	user_config.peer_channel_config_limits.force_announced_channel_preference = false;
	let mut restarting_node = true;
	let (channel_manager_blockhash, channel_manager) = {
		if let Ok(mut f) = fs::File::open(format!("{}/manager", ldk_data_dir.clone())) {
			let mut channel_monitor_mut_references = Vec::new();
			for (_, channel_monitor) in channelmonitors.iter_mut() {
				channel_monitor_mut_references.push(channel_monitor);
			}
			let read_args = ChannelManagerReadArgs::new(
				keys_manager.clone(),
				fee_estimator.clone(),
				chain_monitor.clone(),
				broadcaster.clone(),
				logger.clone(),
				user_config,
				channel_monitor_mut_references,
			);
			<(BlockHash, ChannelManager)>::read(&mut f, read_args).unwrap()
		} else {
			// We're starting a fresh node.
			restarting_node = false;
			let getinfo_resp = bitcoind_client.get_blockchain_info().await;

			let chain_params = ChainParameters {
				network: args.network,
				best_block: BestBlock::new(
					getinfo_resp.latest_blockhash,
					getinfo_resp.latest_height as u32,
				),
			};
			let fresh_channel_manager = channelmanager::ChannelManager::new(
				fee_estimator.clone(),
				chain_monitor.clone(),
				broadcaster.clone(),
				logger.clone(),
				keys_manager.clone(),
				user_config,
				chain_params,
			);
			(getinfo_resp.latest_blockhash, fresh_channel_manager)
		}
	};

    callback("Step 8: Initialize the ChannelManager");

	// Step 9: Sync ChannelMonitors and ChannelManager to chain tip
	let mut chain_listener_channel_monitors = Vec::new();
	let mut cache = UnboundedCache::new();
	let mut chain_tip: Option<poll::ValidatedBlockHeader> = None;
	if restarting_node {
		let mut chain_listeners =
			vec![(channel_manager_blockhash, &channel_manager as &dyn chain::Listen)];

		for (blockhash, channel_monitor) in channelmonitors.drain(..) {
			let outpoint = channel_monitor.get_funding_txo().0;
			chain_listener_channel_monitors.push((
				blockhash,
				(channel_monitor, broadcaster.clone(), fee_estimator.clone(), logger.clone()),
				outpoint,
			));
		}

		for monitor_listener_info in chain_listener_channel_monitors.iter_mut() {
			chain_listeners
				.push((monitor_listener_info.0, &monitor_listener_info.1 as &dyn chain::Listen));
		}
		chain_tip = Some(
			init::synchronize_listeners(
				&mut bitcoind_client.deref(),
				args.network,
				&mut cache,
				chain_listeners,
			)
			.await
			.unwrap(),
		);
	}

    callback("Step 9: Sync ChannelMonitors and ChannelManager to chain tip");

	// Step 10: Give ChannelMonitors to ChainMonitor
	for item in chain_listener_channel_monitors.drain(..) {
		let channel_monitor = item.1 .0;
		let funding_outpoint = item.2;
		chain_monitor.watch_channel(funding_outpoint, channel_monitor).unwrap();
	}

    callback("Step 10: Give ChannelMonitors to ChainMonitor");

    format!("...finish start_ldk({}, {}, {}, {}, {}, {}, {})", rpc_info, ldk_storage_path, port, network, node_name, address, mnemonic_key_phrase)
}


#[cfg(test)]
mod tests {
    use super::start_ldk;

	#[test]
	fn test_start_ldk(){
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async move {
            // println!("hello ldk...");
            let res = start_ldk(
                "rpc_info".to_string(),
                "ldk_storage_path".to_string(),
                9732,
                "regtest".to_string(),
                "hellolighting".to_string(),
                "0.0.0.0".to_string(),
                "mnemonic_key_phrase".to_string(),
                Box::new(|msg| { println!("{}",msg)})).await;
            
            println!("{}",res);
        })
	}
}
