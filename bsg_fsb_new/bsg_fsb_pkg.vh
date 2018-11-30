`ifndef BSG_FSB_PKG_VH

`define BSG_FSB_PKG_VH

`define declare_bsg_fsb_pkt_s( fsb_width_lp,id_width_p )                      \
  typedef enum logic [6:0] {RNDISABLE_CMD       = 'd1                           \
                           ,RNENABLE_CMD        = 'd2                           \
                           ,RNDOWN_CMD          = 'd3                           \
                           ,RNUP_CMD            = 'd4                           \
                           ,RNRESET_ENABLE_CMD  = 'd5                           \
                           ,RNRESET_DISABLE_CMD = 'd6} bsg_fsb_opcode_s;        \
                                                                                \
                                                                                \
  localparam    fsb_pkt_data_width_lp =                                         \
                        fsb_width_lp - 2* id_width_p - $bits(bsg_fsb_opcode_s) -1; \
  typedef struct packed {                                                       \
    logic [id_width_p-1:0]      destid;                                         \
    logic [0:0]      cmd;                                                       \
                                                                                \
    bsg_fsb_opcode_s opcode;                                                    \
    logic [id_width_p-1:0]      srcid;                                          \
    logic [fsb_pkt_data_width_lp-1:0]     data;                                \
  } bsg_fsb_pkt_s;                                                              \
                                                                                \
   typedef logic [fsb_width_lp - id_width_p-1 -1:0] bsg_fsb_pkt_client_data_t;  \
                                                                                \
  typedef struct packed{                                                        \
    logic [id_width_p-1:0]      destid;                                         \
    logic [0:0]      cmd;                                                       \
    bsg_fsb_pkt_client_data_t data;                                             \
  } bsg_fsb_pkt_client_s;                                                       \
        

`endif
