#define ETHERTYPE_BF_FABRIC         0x9000
#define ETHERTYPE_VLAN              0x8100
#define ETHERTYPE_QINQ              0x9100
#define ETHERTYPE_MPLS              0x8847
#define ETHERTYPE_IPV4              0x0800
#define ETHERTYPE_IPV6              0x86dd
#define ETHERTYPE_ARP               0x0806
#define ETHERTYPE_RARP              0x8035
#define ETHERTYPE_NSH               0x894f
#define ETHERTYPE_ETHERNET          0x6558
#define ETHERTYPE_ROCE              0x8915
#define ETHERTYPE_FCOE              0x8906
#define ETHERTYPE_TRILL             0x22f3
#define ETHERTYPE_VNTAG             0x8926
#define ETHERTYPE_LLDP              0x88cc
#define ETHERTYPE_LACP              0x8809

#define IPV4_MULTICAST_MAC          0x01005E
#define IPV6_MULTICAST_MAC          0x3333

#define IP_PROTOCOLS_ICMP           1
#define IP_PROTOCOLS_IGMP           2
#define IP_PROTOCOLS_IPV4           4
#define IP_PROTOCOLS_TCP            6
#define IP_PROTOCOLS_UDP            17
#define IP_PROTOCOLS_IPV6           41
#define IP_PROTOCOLS_GRE            47
#define IP_PROTOCOLS_IPSEC_ESP      50
#define IP_PROTOCOLS_IPSEC_AH       51
#define IP_PROTOCOLS_ICMPV6         58
#define IP_PROTOCOLS_EIGRP          88
#define IP_PROTOCOLS_OSPF           89
#define IP_PROTOCOLS_PIM            103
#define IP_PROTOCOLS_VRRP           112

#define IP_PROTOCOLS_IPHL_ICMP      0x501
#define IP_PROTOCOLS_IPHL_IPV4      0x504
#define IP_PROTOCOLS_IPHL_TCP       0x506
#define IP_PROTOCOLS_IPHL_UDP       0x511
#define IP_PROTOCOLS_IPHL_IPV6      0x529
#define IP_PROTOCOLS_IPHL_GRE       0x52f

#define UDP_PORT_BOOTPS             67
#define UDP_PORT_BOOTPC             68
#define UDP_PORT_RIP                520
#define UDP_PORT_RIPNG              521
#define UDP_PORT_DHCPV6_CLIENT      546
#define UDP_PORT_DHCPV6_SERVER      547
#define UDP_PORT_HSRP               1985
#define UDP_PORT_BFD                3785
#define UDP_PORT_LISP               4341
#define UDP_PORT_VXLAN              4789
#define UDP_PORT_VXLAN_GPE          4790
#define UDP_PORT_ROCE_V2            4791
#define UDP_PORT_GENV               6081
#define UDP_PORT_SFLOW              6343

#define IP_IHL_MIN_LENGTH           5

typedef bit<48> EthernetAddress;
typedef bit<32> IPv4Address;
typedef bit<9>  egressSpec;

header ethernet_t {
    EthernetAddress src_addr;
    EthernetAddress dst_addr;
    bit<16> ether_type;
}

header intrinsic_metadata_t {
    bit<4> mcast_grp;
    bit<4> egress_rid;
    bit<16> mcast_hash;
    bit<32> lf_field_list;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    IPv4Address src_addr;
    IPv4Address dst_addr;
}

header icmp_t {
    bit<16> type_code;
    bit<16> hdr_checksum;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length_;
    bit<16> checksum;
}

struct pm_metadata_t {
    // used in mirroring
    bit<1> mirror_id;
}

struct local_metadata_t {
    // pm_metadata_t pm_metadata;
    intrinsic_metadata_t intrinsic_metadata;
}

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    // tcp_t       tcp;
}