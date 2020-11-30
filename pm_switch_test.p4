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
  apply { }
}

V1Switch(
  PM_Parser(),
  PM_Verify_Checksum(),
  PM_Ingress(),
  PM_Egress(),
  PM_Update_Checksum(),
  PM_Deparser()
) main;