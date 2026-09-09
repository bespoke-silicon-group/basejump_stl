`ifndef BSG_COMM_LINK_VH
`define BSG_COMM_LINK_VH

`define bsg_comm_link_channel_in_s_width(in_channel_width) ((in_channel_width)+3)

`declare declare_bsg_comm_link_channel_in_s(in_channel_width)   \
   typedef struct packed {                                      \
      /* incoming source-synchronous channel */                 \
      logic                        io_valid_tline;              \
      logic [in_channel_width-1:0] io_data_tline;               \
      logic                        io_clk_tline;                \
                                                                \
      /* return credits for outgoing channel; async */          \
      logic                       token_clk_tline;              \
      } bsg_comm_link_channel_in_s

`declare declare_bsg_comm_link_channel_out_s(in_channel_width)  \
   typedef struct packed {                                      \
      /* outgoing source-synchronous channel */                 \
      logic                        im_valid_tline;              \
      logic [in_channel_width-1:0] im_data_tline;               \
      logic                        im_clk_tline;                \
                                                                \
      /* returning credits for incoming channel */              \
      logic                       io_token_clk_tline;           \
   } bsg_comm_link_channel_out_s

`define bsg_comm_link_channel_out_s_width(in_channel_width) ((in_channel_width)+3)

`define bsg_fsb_in_s_width(in_ring_width)  ((in_ring_width)+4)
`define bsg_fsb_out_s_width(in_ring_width) ((in_ring_width)+2)

`define declare_bsg_fsb_in_s(in_ring_width) \
     typedef struct packed {                \
        logic                     en_r;     \
        logic                     reset_r;  \
                                            \
        logic                     v;        \
        logic [in_ring_width-1:0] data;     \
        logic                     yumi_rev; \
                                            \
        } bsg_fsb_in_s

`define declare_bsg_fsb_out_s(in_ring_width) \
     typedef struct packed {                 \
        logic                     v;         \
        logic [in_ring_width-1:0] data;      \
        logic                     ready_rev; \
        } bsg_fsb_out_s

`endif BSG_COMM_LINK_VH

