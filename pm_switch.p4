/* -*- P4_16 -*- */

/*
  MAC learning:
    digest<T>(in bit<32> receiver, in T data);

  Cloning action:
    clone3<T>(in CloneType type, in bit<32> session, in T data);

  "In addition to other session attributes, clone_spec determines
  the egress specification (standard metadata.egress_spec) that
  is presented to the Buffering Mechanism."

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
                inout local_metadata_t lcmeta,
                inout standard_metadata_t stdmeta) {
  state start {
    transition parse_ethernet;
  }

  state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.ether_type) {
      ETHERTYPE_IPV4: parse_ipv4;
      // no default rule: all other packets rejected
    }
  }

  state parse_ipv4 {
    packet.extract(hdr.ipv4);
    verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
    verify(hdr.ipv4.ihl == 4w5, error.IPv4OptionsNotSupported);
    transition select(hdr.ipv4.protocol) {
      IP_PROTOCOLS_TCP: parse_tcp;
      default: accept;
    }
  }

  state parse_tcp {
    packet.extract(hdr.tcp);
    transition accept;
  }
}

control PM_Verify_Checksum(inout headers hdr,
                          inout local_metadata_t lcmeta) {
  apply {
    verify_checksum(
            hdr.ipv4.isValid() && hdr.ipv4.ihl == IP_IHL_MIN_LENGTH,
            {
              hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.total_len,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.frag_offset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.src_addr,
              hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum, HashAlgorithm.csum16
    );
  }
}

control PM_Update_Checksum(inout headers hdr,
                      inout local_metadata_t lcmeta) {
  apply {
    update_checksum(
            hdr.ipv4.isValid() && hdr.ipv4.ihl == IP_IHL_MIN_LENGTH,
            {
              hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.total_len,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.frag_offset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.src_addr,
              hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum, HashAlgorithm.csum16
    );
  }
}

control PM_Ingress(inout headers hdr,
                  inout local_metadata_t lcmeta,
                  inout standard_metadata_t stdmeta) {
  /* COMMON */
  action _nop() { }

  action _drop() {
    mark_to_drop(stdmeta);
  }

  /* MAC learning */
  action _learn_mac() {
    lcmeta.mac_learn.src_addr = hdr.ethernet.src_addr;
    lcmeta.mac_learn.ingress_port = stdmeta.ingress_port;
    digest(MAC_LEARN_RECEIVER, lcmeta.mac_learn);
  }

  table pm_mac_learning {
    key = {
      hdr.ethernet.src_addr: exact;
    }
    actions = {
      _learn_mac;
      _nop;
    }
    size = 1024;
    default_action = _learn_mac();
  }

  /* MAC forwarding */
  action _broadcast() {
    stdmeta.mcast_grp = 1;
  }

  action _forward_mac(PortSpec port) {
    stdmeta.egress_spec = port;
  }

  table pm_mac_forwarding {
    key = {
      hdr.ethernet.dst_addr: exact;
    }
    actions = {
      _forward_mac;
      _broadcast;
    }
    size = 1024;
    default_action = _broadcast();
  }

  /* IPv4 forwarding */
  action _forward_ipv4(EthernetAddress dst_mac, PortSpec port) {
    hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
    hdr.ethernet.dst_addr = dst_mac;
    stdmeta.egress_spec = port;
    hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
  }

  table pm_ipv4_forwarding {
    key = {
      hdr.ipv4.dst_addr: lpm;
    }
    actions = {
      _forward_ipv4;
      _drop;
    }
    size = 1024;
    default_action = _drop();
  }

  /* Cloning all packets */
  action _clone_all() {
    clone3(CloneType.I2E, (bit<32>)32w300, { stdmeta });
  }

  table pm_cloning_all {
    actions = {
      _clone_all;
    }
    size = 1;
    default_action = _clone_all();
  }

  /* Cloning specific src_addr packets */
  action _clone_by_src_ip() {
    clone3(CloneType.I2E, (bit<32>)32w400, { stdmeta });
  }

  table pm_cloning_by_src_ip {
    key = {
      hdr.ipv4.src_addr: lpm;
    }
    actions = {
      _clone_by_src_ip;
      _drop;
    }
    size = 1;
    default_action = _drop();
  }

  /* Cloning specific dst_port packets */
  action _clone_by_dst_port() {
    clone3(CloneType.I2E, (bit<32>)32w500, { stdmeta });
  }

  table pm_cloning_by_dst_port {
    key = {
      hdr.tcp.dst_port: exact;
    }
    actions = {
      _clone_by_dst_port;
      _drop;
    }
    size = 1;
    default_action = _drop();
  }

  apply {
    pm_mac_learning.apply();
    pm_mac_forwarding.apply();
    pm_ipv4_forwarding.apply();
    pm_cloning_all.apply();
    pm_cloning_by_src_ip.apply();
    pm_cloning_by_dst_port.apply();
  }
}

control PM_Egress(inout headers hdr,
                inout local_metadata_t lcmeta,
                inout standard_metadata_t stdmeta) {
  apply { }
}

control PM_Deparser(packet_out packet,
                  in headers hdr) {
  apply {
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ipv4);
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