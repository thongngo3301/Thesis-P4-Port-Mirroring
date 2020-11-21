/* -*- P4_16 -*- */

/*
  action:
    clone3<T>(in CloneType type, in bit<32> session, in T data);

  "In addition to other session attributes, clone_spec determines
  the egress specification (standard metadata egress_spec) that
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
    trasition parse_ethernet;
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

control PM_Update_Checksum(inout headers_t hdr,
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

  action mirror_select(id) {
    meta.pm_metadata.mirror_id = id;
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

https://github.com/p4lang/p4-spec/blob/master/p4-16/psa/examples/psa-example-parser-checksum.p4
https://github.com/FZU-SDN/p4pktgen/blob/master/docs/p4pktgen-intro-by-example.md
https://github.com/p4lang/p4-spec/blob/master/p4-16/psa/examples/psa-example-parser-checksum.p4
https://p4.org/p4-spec/docs/P4-16-v1.1.0-draft.html#sec-vss-example
http://csie.nqu.edu.tw/smallko/sdn/p4_meter.htm
https://github.com/FZU-SDN/MatReduce-examples/blob/master/c1/p4src/optimize.p4

http://csie.nqu.edu.tw/smallko/sdn/p4-clone.htm
http://csie.nqu.edu.tw/smallko/sdn/p4utils_sendtocpu.htm
http://csie.nqu.edu.tw/smallko/sdn/p4switch.htm
http://csie.nqu.edu.tw/smallko/sdn/p4bmv2docker.htm