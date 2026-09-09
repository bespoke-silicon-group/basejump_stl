`ifndef BSG_FSB_PKG_VH
`define BSG_FSB_PKG_VH

`ifndef FSB_LEGACY 
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
        
`else
//  ______ _____ ____   _      ______ _____          _______     __ 
// |  ____/ ____|  _ \ | |    |  ____/ ____|   /\   / ____\ \   / / 
// | |__ | (___ | |_) || |    | |__ | |  __   /  \ | |     \ \_/ /  
// |  __| \___ \|  _ < | |    |  __|| | |_ | / /\ \| |      \   /   
// | |    ____) | |_) || |____| |___| |__| |/ ____ \ |____   | |    
// |_|   |_____/|____/ |______|______\_____/_/    \_\_____|  |_|    
//                 ______                                           
//                |______|   

package bsg_fsb_pkg;

  typedef enum logic [6:0] {RNDISABLE_CMD       = 'd1
                           ,RNENABLE_CMD        = 'd2
                           ,RNDOWN_CMD          = 'd3
                           ,RNUP_CMD            = 'd4
                           ,RNRESET_ENABLE_CMD  = 'd5
                           ,RNRESET_DISABLE_CMD = 'd6} bsg_fsb_opcode_s;

// the top 5 bits are not re-purposable.
//

  typedef struct packed {
    // these bits are reserved and needed for this network
    logic [3:0]      destid; // 4 bits
    logic [0:0]      cmd;    // 1 bits (1 for switch, 0 for node)

    // for cmd=0, these 75 bits are free for general use; they can be repurposed
    bsg_fsb_opcode_s opcode; // 7 bits - only looked at by switch
    logic [3:0]      srcid;  // 4 bits
    logic [63:0]     data;   // 64 bits
  } bsg_fsb_pkt_s;

   typedef logic [74:0] bsg_fsb_pkt_client_data_t;

   // for client nodes; note destid and cmd must line up with bsg_fsb_pkt_s above
  typedef struct packed {
    // these bits are reserved and needed for this network
    logic [3:0]      destid; // 4 bits
    logic [0:0]      cmd;    // == 0
    bsg_fsb_pkt_client_data_t data;    // this is the payload
  } bsg_fsb_pkt_client_s;

endpackage
`endif
`endif
