/*
	Packet Mirror Processing:
	pkt -> pm_ingress -> mirror -> ... -> pm_egress -> listen port

	------(ingress)------||------(egress)------> pipeline
 */

/* local metadata */
header local_metadata_t {
    bit<1> mirror_id; // used in pkt mirroring
}

metadata local_metadata_t local_metadata;

/* Packet Mirroring in ingress */

field_list mirror_field_list {
	//standard_metadata;
	local_metadata.mirror_id;
}

// Add runtime command.
// mirroring_add [mirror_id] [output_port]
action mirror_select(id) {
	modify_field(local_metadata.mirror_id, id);
	clone_ingress_pkt_to_egress(id, mirror_field_list);
}

// select the pkt based on its dstAddr and srcAddr, and make mirror.
table pm_ingress {
	reads {
		ipv4.srcAddr : exact;
		ipv4.dstAddr : exact;
	}
	actions {_nop; mirror_select;}
}

/* Packet Mirroring in egress */

// the counter used to count the mirror pkt
counter mirror_counter {
	type : packets;
	static : pm_egress;
	instance_count : 10;
}

// count the mirror pkt.
action mirror_execute(index) {
	count(mirror_counter, index);
}

// reads the field, execute the action with the mirror pkt.
table pm_egress {
	reads {
		// instance_type is used to distinguish the mirror pkt
		// from the original pkt.
		// mirror packet => instance_type = 1
		standard_metadata.instance_type : exact;
	}
	actions {_nop; mirror_execute;}
}

/* Control Program */

// beginning of ingress pipeline.
control port_mirror_ingress {
	apply(pm_ingress);
}

// end of egress pipeline.
control port_mirror_egress {
	apply(pm_egress);
}