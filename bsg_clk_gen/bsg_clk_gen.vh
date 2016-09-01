`ifndef BSG_CLK_GEN_VH
`define BSG_CLK_GEN_VH

`define declare_bsg_clk_gen_osc_tag_payload_s(PARAM_num_adg)    \
                                                                \
typedef struct packed {                                         \
        logic [(PARAM_num_adg)-1:0] adg;                        \
        logic [1:0] cdt;                                        \
        logic [1:0] fdt;                                        \
} bsg_clk_gen_osc_tag_payload_s;

`define declare_bsg_clk_gen_ds_tag_payload_s(PARAM_ds_width)    \
                                                                \
typedef struct packed {                                         \
   logic [PARAM_ds_width-1:0] val;                              \
   logic reset;                                                 \
} bsg_clk_gen_ds_tag_payload_s;

`endif
