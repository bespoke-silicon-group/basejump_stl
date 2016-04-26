package bsg_fsb_pkg;

  typedef enum logic [6:0] {RNDISABLE_CMD       = 'd1
                           ,RNENABLE_CMD        = 'd2
                           ,RNDOWN_CMD          = 'd3
                           ,RNUP_CMD            = 'd4
                           ,RNRESET_ENABLE_CMD  = 'd5
                           ,RNRESET_DISABLE_CMD = 'd6} bsg_fsb_opcode_s;

  typedef struct packed {
    logic [3:0]      srcid;  // 4 bits
    logic [3:0]      destid; // 4 bis
    logic [0:0]      cmd;    // 1 bits (1 for switch, 0 for node)
    bsg_fsb_opcode_s opcode; // 7 bits
    logic [63:0]     data;   // 64 bits
  } bsg_fsb_pkt_s;

endpackage

