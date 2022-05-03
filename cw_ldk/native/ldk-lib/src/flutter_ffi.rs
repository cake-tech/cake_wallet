use std::{sync::{mpsc::{SyncSender, Receiver}, Mutex}, time::Duration};
use std::sync::Arc;
use std::net::{IpAddr, SocketAddr, ToSocketAddrs};

use bitcoin::secp256k1::key::PublicKey;

use crate::hex_utils;
use crate::{
	ChannelManager, 
	PeerManager
};

fn node_info(channel_manager: &Arc<ChannelManager>, peer_manager: &Arc<PeerManager>) -> String {
	let mut res: String = String::new();
	res.push_str(format!("\t{{").as_str());
	res.push_str(format!("\t\t node_pubkey: {}", channel_manager.get_our_node_id()).as_str());
	let chans = channel_manager.list_channels();
	res.push_str(format!("\t\t num_channels: {}", chans.len()).as_str());
	res.push_str(format!("\t\t num_usable_channels: {}", chans.iter().filter(|c| c.is_usable).count()).as_str());
	let local_balance_msat = chans.iter().map(|c| c.balance_msat).sum::<u64>();
	res.push_str(format!("\t\t local_balance_msat: {}", local_balance_msat).as_str());
	res.push_str(format!("\t\t num_peers: {}", peer_manager.get_peer_node_ids().len()).as_str());
	res.push_str(format!("\t}},").as_str());
	res
}

pub(crate) fn parse_peer_info(
	peer_pubkey_and_ip_addr: String,
) -> Result<(PublicKey, SocketAddr), std::io::Error> {
	let mut pubkey_and_addr = peer_pubkey_and_ip_addr.split("@");
	let pubkey = pubkey_and_addr.next();
	let peer_addr_str = pubkey_and_addr.next();
	if peer_addr_str.is_none() || peer_addr_str.is_none() {
		return Err(std::io::Error::new(
			std::io::ErrorKind::Other,
			"ERROR: incorrectly formatted peer info. Should be formatted as: `pubkey@host:port`",
		));
	}

	let peer_addr = peer_addr_str.unwrap().to_socket_addrs().map(|mut r| r.next());
	if peer_addr.is_err() || peer_addr.as_ref().unwrap().is_none() {
		return Err(std::io::Error::new(
			std::io::ErrorKind::Other,
			"ERROR: couldn't parse pubkey@host:port into a socket address",
		));
	}

	let pubkey = hex_utils::to_compressed_pubkey(pubkey.unwrap());
	if pubkey.is_none() {
		return Err(std::io::Error::new(
			std::io::ErrorKind::Other,
			"ERROR: unable to parse given pubkey for node",
		));
	}

	Ok((pubkey.unwrap(), peer_addr.unwrap().unwrap()))
}

pub(crate) async fn connect_peer_if_necessary(
	pubkey: PublicKey, peer_addr: SocketAddr, peer_manager: Arc<PeerManager>,
) -> Result<(), ()> {
	for node_pubkey in peer_manager.get_peer_node_ids() {
		if node_pubkey == pubkey {
			return Ok(());
		}
	}
	let res = do_connect_peer(pubkey, peer_addr, peer_manager).await;
	if res.is_err() {
		println!("ERROR: failed to connect to peer");
	}
	res
}

pub(crate) async fn do_connect_peer(
	pubkey: PublicKey, peer_addr: SocketAddr, peer_manager: Arc<PeerManager>,
) -> Result<(), ()> {
	match lightning_net_tokio::connect_outbound(Arc::clone(&peer_manager), pubkey, peer_addr).await
	{
		Some(connection_closed_future) => {
			let mut connection_closed_future = Box::pin(connection_closed_future);
			loop {
				match futures::poll!(&mut connection_closed_future) {
					std::task::Poll::Ready(_) => {
						return Err(());
					}
					std::task::Poll::Pending => {}
				}
				// Avoid blocking the tokio context by sleeping a bit
				match peer_manager.get_peer_node_ids().iter().find(|id| **id == pubkey) {
					Some(_) => return Ok(()),
					None => tokio::time::sleep(Duration::from_millis(10)).await,
				}
			}
		}
		None => Err(()),
	}
}

#[allow(dead_code)]
#[allow(unused_variables)]
pub(crate) async fn get_messages_from_channel(
	sender: tokio::sync::mpsc::Sender<String>, 
	receiver: Arc<tokio::sync::Mutex<tokio::sync::mpsc::Receiver<String>>>,
	channel_manager: Arc<ChannelManager>,
	peer_manager: Arc<PeerManager> 
) {

	while let Some(msg) = receiver.lock().await.recv().await {
		let mut words = msg.split_whitespace();

		if let Some(word) = words.next() {
			match word {
				"nodeinfo" => {
					let res = node_info(&channel_manager, &peer_manager);
					sender.send(res).await.unwrap();
				},
				"connectpeer" => {
					let peer_pubkey_and_ip_addr = words.next();
					if peer_pubkey_and_ip_addr.is_none() {
						sender.send("ERROR: connectpeer requires peer connection info: `connectpeer pubkey@host:port`".to_string()).await.unwrap();
						continue;
					}

					let (pubkey, peer_addr) =
						match parse_peer_info(peer_pubkey_and_ip_addr.unwrap().to_string()) {
							Ok(info) => info,
							Err(e) => {
								println!("{:?}", e.into_inner().unwrap());
								continue;
							}
						};

					if connect_peer_if_necessary(pubkey, peer_addr, peer_manager.clone())
						.await
						.is_ok()
					{
						sender.send(format!("SUCCESS: connected to peer {}", pubkey)).await.unwrap();
					}
				},
				msg => {
					sender.send(format!("message received: {}", msg)).await.unwrap();
				},
			}
		}
	}

		
	// for msg in recv {

	// 	let mut words = msg.split_whitespace();
	// 	if let Some(word) = words.next() {
	// 		match word {
	// 			"exit" => {
	// 				break;
	// 			},
	// 			"nodeinfo" => {
	// 				let res = node_info(&channel_manager, &peer_manager);
	// 				sender.send(res).unwrap();
	// 			},
	// 			"connectpeer" => {
	// 				let peer_pubkey_and_ip_addr = words.next();
	// 				if peer_pubkey_and_ip_addr.is_none() {
	// 					sender.send("ERROR: connectpeer requires peer connection info: `connectpeer pubkey@host:port`".to_string()).unwrap();
	// 					continue;
	// 				}

	// 				let (pubkey, peer_addr) =
	// 					match parse_peer_info(peer_pubkey_and_ip_addr.unwrap().to_string()) {
	// 						Ok(info) => info,
	// 						Err(e) => {
	// 							println!("{:?}", e.into_inner().unwrap());
	// 							continue;
	// 						}
	// 					};
					
					
	// 				if connect_peer_if_necessary(pubkey, peer_addr, peer_manager.clone())
	// 					.await
	// 					.is_ok()
	// 				{
	// 					// sender.send(format!("SUCCESS: connected to peer {}", pubkey)).unwrap();
	// 				}

	// 			}
	// 			msg => {
	// 				sender.send(format!("message received: {}", msg)).unwrap();
	// 			}
	// 		}
	// 	}
	// };
}