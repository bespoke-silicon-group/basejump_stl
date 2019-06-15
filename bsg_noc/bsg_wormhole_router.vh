// this is a partial packet header, which should always go at the bottom bits of a header flit
// move to bsg_wormhole_router.vh
// FIXME:  have them pass in the cord_markers_pos_p
//         struct, then it will match bsg_wormhole_router
//

`define declare_bsg_wormhole_router_header_s(in_cord_width,in_len_width,in_struct_name) \
typedef struct packed {                 \
  logic [in_len_width-1:0]    len;      \
  logic [in_cord_width-1:0 ]  cord;     \
} in_struct_name
