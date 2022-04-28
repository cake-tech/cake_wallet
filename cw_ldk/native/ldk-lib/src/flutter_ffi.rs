use std::sync::{mpsc::{SyncSender, Receiver}, Mutex};

use std::sync::Arc;

use crate::{
	ChannelManager, 
	PeerManager
};

fn node_info(channel_manager: &Arc<ChannelManager>, peer_manager: &Arc<PeerManager>) -> String {
	let mut res :Vec<String> = Vec::new();

	res.push(format!("\t{{"));
	res.push(format!("\t\t node_pubkey: {}", channel_manager.get_our_node_id()));
	let chans = channel_manager.list_channels();
	res.push(format!("\t\t num_channels: {}", chans.len()));
	res.push(format!("\t\t num_usable_channels: {}", chans.iter().filter(|c| c.is_usable).count()));
	let local_balance_msat = chans.iter().map(|c| c.balance_msat).sum::<u64>();
	res.push(format!("\t\t local_balance_msat: {}", local_balance_msat));
	res.push(format!("\t\t num_peers: {}", peer_manager.get_peer_node_ids().len()));
	res.push(format!("\t}},"));

	format!("{:#?}", res)
}

#[allow(dead_code)]
#[allow(unused_variables)]
pub(crate) fn get_messages_from_channel(
	sender: &SyncSender<String>, 
	receiver: &Mutex<Receiver<String>>,
	channel_manager: Arc<ChannelManager>,
	peer_manager: Arc<PeerManager> 
) {

	let recv = &*receiver.lock().unwrap();
	
	for msg in recv {

		let mut words = msg.split_whitespace();
		if let Some(word) = words.next() {
			match word {
				"exit" => {
					break;
				},
				"nodeinfo" => {
					let res = node_info(&channel_manager, &peer_manager);
					sender.send(res).unwrap();
				}
				msg => {
					sender.send(format!("message received: {}", msg)).unwrap();
				}
			}
		}
	};
}