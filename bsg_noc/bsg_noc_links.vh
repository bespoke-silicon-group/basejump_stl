`ifndef BSG_NOC_LINKS_VH
 `define BSG_NOC_LINKS_VH

// aka ready & valid
`define bsg_ready_and_link_sif_width(in_data_width) (in_data_width+2)

// aka ready->valid
`define bsg_ready_then_link_sif_width(in_data_width) (in_data_width+2)

// aka valid->ready
`define bsg_then_ready_link_sif_width(in_data_width) ((in_data_width)+2)

`define declare_bsg_ready_and_link_sif_s(in_data_width,in_struct_name)    \
   typedef struct packed {                                                \
      logic       v;                                                      \
      logic       ready_and_rev;                                          \
      logic [in_data_width-1:0] data;                                     \
  } in_struct_name

`define declare_bsg_ready_then_link_sif_s(in_data_width,in_struct_name)\
   typedef struct packed {                                                \
      logic       v;                                                      \
      logic       ready_then_rev;                                         \
      logic [in_data_width-1:0] data;                                     \
  } in_struct_name

`define declare_bsg_then_ready_link_sif_s(in_data_width,in_struct_name)\
   typedef struct packed {                                                \
      logic       v;                                                      \
      logic       then_ready_rev;                                         \
      logic [in_data_width-1:0] data;                                     \
  } in_struct_name

 `endif // BSG_NOC_LINKS_VH
