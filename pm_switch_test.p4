/* -*- P4_16 -*- */

/*
  action:
    clone3<T>(in CloneType type, in bit<32> session, in T data);

  "In addition to other session attributes, clone_spec determines
  the egress specification (standard metadata.egress_spec) that
  is presented to the Buffering Mechanism."

  clone_spec = mirror_id in this example.
*/

/*
  Packet Mirror Processing:
  pkt -> pm_ingress -> mirror -> ... -> pm_egress -> listen port

  ------(ingress)------||------(egress)------> pipeline
*/

#include <core.p4>
#include <v1model.p4>
#include "includes/header.p4"

error {
  IPv4IncorrectVersion,
  IPv4OptionsNotSupported
}

parser PM_Parser(packet_in packet,
                out headers hdr,
                inout local_metadata_t meta,
                inout standard_metadata_t stdmeta) {
  // state start {
  //   transition accept;
  // }

  state start {
    transition parse_ethernet;
  }

  state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.ether_type) {
      ETHERTYPE_IPV4: parse_ipv4;
      default: accept;
    }
  }

  state parse_ipv4 {
    packet.extract(hdr.ipv4);
    transition select(hdr.ipv4.protocol) {
      IP_PROTOCOLS_ICMP: parse_icmp;
      IP_PROTOCOLS_UDP: parse_udp;
      IP_PROTOCOLS_TCP: parse_tcp;
      default: accept;
    }
  }

  state parse_icmp {
    packet.extract(hdr.icmp);
    transition accept;
  }

  state parse_udp {
    packet.extract(hdr.udp);
    transition accept;
  }

  state parse_tcp {
    packet.extract(hdr.tcp);
    transition accept;
  }
}

control PM_Verify_Checksum(inout headers hdr,
                          inout local_metadata_t meta) {
  apply { }
}

control PM_Update_Checksum(inout headers hdr,
                      inout local_metadata_t meta) {
  apply { }
}

control PM_Ingress(inout headers hdr,
                  inout local_metadata_t meta,
                  inout standard_metadata_t stdmeta) {
  action _drop() {
    mark_to_drop(stdmeta);
  }

  action _forward(PortSpec port) {
    stdmeta.egress_spec = port;
  }

  table forwarding {
    key = {
      // hdr.ipv4.dst_addr: lpm;
      stdmeta.ingress_port: exact;
    }
    actions = {
      _forward;
      _drop;
    }
    size = 1024;
    default_action = _drop();
  }

  // action pm_copy() {
  //   if (hdr.tcp.dst_port == 80) {
  //     clone3(CloneType.I2E, (bit<32>)32w250, { stdmeta });
  //   } else {
  //     _drop();
  //   }
  // }

  // table copying {
  //   actions = {
  //     pm_copy;
  //   }
  //   size = 1;
  //   default_action = pm_copy();
  // }

  apply {
    // copying.apply();
    if (hdr.tcp.dst_port == 80) {
      clone3(CloneType.I2E, (bit<32>)32w250, { stdmeta });
    } else {
      _drop();
    }
    forwarding.apply();
  }
}

control PM_Egress(inout headers hdr,
                inout local_metadata_t meta,
                inout standard_metadata_t stdmeta) {
  apply { }
}

control PM_Deparser(packet_out packet,
                  in headers hdr) {
  apply {
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
    // if (hdr.icmp.isValid()) {
      packet.emit(hdr.icmp);
    // }
    // if (hdr.udp.isValid()) {
      packet.emit(hdr.udp);
    // }
    // if (hdr.tcp.isValid()) {
      packet.emit(hdr.tcp);
    // }
  }
}

V1Switch(
  PM_Parser(),
  PM_Verify_Checksum(),
  PM_Ingress(),
  PM_Egress(),
  PM_Update_Checksum(),
  PM_Deparser()
) main;