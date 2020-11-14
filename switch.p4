#include "includes/header.p4"
#include "includes/parser.p4"
#include "port_mirror.p4"

// table and action

action _drop() {
    drop();
}

action _nop() {
}

#define MAC_LEARN_RECEIVER 1024

field_list mac_learn_digest {
    ethernet.src_addr;
    standard_metadata.ingress_port;
}

action mac_learn() {
    generate_digest(MAC_LEARN_RECEIVER, mac_learn_digest);
}

table smac {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {mac_learn; _nop;}
    size : 512;
}

action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
    // port security:
    modify_field(port_sec_metadata.port, port);
}

action broadcast() {
    modify_field(intrinsic_metadata.mcast_grp, 1);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        forward;
        broadcast;
    }
    size : 512;
}

table mcast_src_pruning {
    reads {
        standard_metadata.instance_type : exact;
    }
    actions {_nop; _drop;}
    size : 1;
}

control ingress {
    // port mirror:
    port_mirror_ingress();

    apply(smac);
    apply(dmac);

    // trTCM:
    trTCM_process();
    // resubmit:
    resubmit_ingress();
    resubmit_egress();
}

control egress {
    if (standard_metadata.ingress_port == standard_metadata.egress_port) {
        apply(mcast_src_pruning);
    }

    // l2 port security:
    port_security_process();
    // icmp security:
    icmp_security_process();
    // udp flood:
    udp_flood_process();

    // port mirror:
    port_mirror_egress();
}
