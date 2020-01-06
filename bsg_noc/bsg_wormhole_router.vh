// this is a partial packet header should always go at the bottom bits of a header flit
// move to bsg_wormhole_router.vh
// FIXME:  have them pass in the cord_markers_pos_p
//         struct, then it will match bsg_wormhole_router
//

`define declare_bsg_wormhole_router_header_s(cord_width_mp, len_width_mp, struct_name_mp) \
typedef struct packed {                 \
  logic [len_width_mp-1:0]    len;      \
  logic [cord_width_mp-1:0 ]  cord;     \
} struct_name_mp

`define declare_bsg_wormhole_concentrator_header_s(cord_width_mp, len_width_mp, cid_width, struct_name_mp) \
  typedef struct packed {               \
    logic [cid_width-1:0]     cid;      \
    logic [len_width_mp-1:0]  len;      \
    logic [cord_width_mp-1:0] cord;     \
  } struct_name_mp

`define declare_bsg_wormhole_router_packet_s(cord_width_mp, len_width_mp, payload_width_mp, struct_name_mp) \
typedef struct packed {                 \
  logic [payload_width_mp-1:0] payload; \
  logic [len_width_mp-1:0]     len;     \
  logic [cord_width_mp-1:0]    cord;    \
} struct_name_mp

`define declare_bsg_wormhole_concentrator_packet_s(cord_width_mp, len_width_mp, cid_width_mp, payload_width_mp, struct_name_mp) \
typedef struct packed {                 \
  logic [payload_width_mp-1:0] payload; \
  logic [cid_width_mp-1:0]     cid;     \
  logic [len_width_mp-1:0]     len;     \
  logic [cord_width_mp-1:0]    cord;    \
} struct_name_mp

`define declare_bsg_wormhole_interdomain_packet_s(cord_width_mp, len_width_mp, did_width_mp, payload_width_mp, struct_name_mp) \
typedef struct packed {                 \
  logic [payload_width_mp-1:0] payload; \
  logic [did_width_mp-1:0]     did;     \
  logic [len_width_mp-1:0]     len;     \
  logic [cord_width_mp-1:0]    cord;    \
} struct_name_mp

`define bsg_wormhole_interdomain_packet_width(cord_width_mp, len_width_mp, did_width_mp, payload_width_mp) \
  (cord_width_mp + len_width_mp + did_width_mp + payload_width_mp)

`define bsg_wormhole_concentrator_packet_width(cord_width_mp, len_width_mp, cid_width_mp, payload_width_mp) \
  (cord_width_mp + len_width_mp + cid_width_mp + payload_width_mp)

`define bsg_wormhole_router_packet_width(cord_width_mp, len_width_mp, payload_width_mp) \
  (cord_width_mp + len_width_mp + payload_width_mp)

