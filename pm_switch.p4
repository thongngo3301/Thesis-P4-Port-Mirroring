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
    verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
    verify(hdr.ipv4.ihl == 4w5, error.IPv4OptionsNotSupported);
    transition accept;
  }
}

control PM_Verify_Checksum(inout headers hdr,
                          inout local_metadata_t meta) {
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
                      inout local_metadata_t meta) {
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
                  inout local_metadata_t meta,
                  inout standard_metadata_t stdmeta) {
  action pm_drop() {
    mark_to_drop(stdmeta);
  }

  action pm_forward(egressSpec port) {
    stdmeta.egress_spec = port;
  }

  table forwarding {
    key = {
      stdmeta.ingress_port: exact;
    }
    actions = {
      pm_forward;
      pm_drop;
    }
    size = 1024;
    default_action = pm_drop();
  }

  action pm_copy() {
    clone3(CloneType.I2E, (bit<32>)32w250, { stdmeta });
  }

  table copying {
    actions = {
      pm_copy;
    }
    size = 1;
    default_action = pm_copy();
  }

  apply {
    copying.apply();
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