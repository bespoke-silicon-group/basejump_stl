`ifndef BSG_TAG_VH
`define BSG_TAG_VH

`define declare_bsg_tag_header_s(PARAM_els,PARAM_lg_width)                  \
                                                                            \
   typedef struct packed {                                                  \
      logic [`BSG_SAFE_CLOG2((PARAM_els))-1:0]       nodeID;                \
      logic                                          data_not_reset;        \
      logic [(PARAM_lg_width)-1:0] len;                                     \
      } bsg_tag_header_s;

`define bsg_tag_max_packet_len(PARAM_els,PARAM_lg_width) ((1 << (PARAM_lg_width)) - 1 + $bits(bsg_tag_header_s))
`define bsg_tag_reset_len(PARAM_els,PARAM_lg_width) ((1 << `BSG_SAFE_CLOG2(`bsg_tag_max_packet_len((PARAM_els),(PARAM_lg_width))+1))+1)


`endif //  `ifndef BSG_TAG_VH
