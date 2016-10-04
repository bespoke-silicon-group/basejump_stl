`ifndef BSG_PKG_V

`define BSG_PKG_V

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
