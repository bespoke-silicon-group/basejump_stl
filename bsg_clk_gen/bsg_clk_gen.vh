`ifndef BSG_CLK_GEN_VH
`define BSG_CLK_GEN_VH

`define declare_bsg_clk_gen_osc_tag_payload_s(PARAM_num_rows, PARAM_num_cols)    \
                                                                \
typedef struct packed {                                         \
        logic [`BSG_SAFE_CLOG2(PARAM_num_cols*PARAM_num_rows)-1:0] ctl; \
} bsg_clk_gen_osc_tag_payload_s

`define declare_bsg_clk_gen_ds_tag_payload_s(PARAM_ds_width)    \
                                                                \
typedef struct packed {                                         \
   logic [PARAM_ds_width-1:0] val;                              \
   logic reset;                                                 \
} bsg_clk_gen_ds_tag_payload_s

`endif
