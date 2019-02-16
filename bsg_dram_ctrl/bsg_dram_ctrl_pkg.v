/**
 *  bsg_dram_ctrl_pkg.v
 */

package bsg_dram_ctrl_pkg;

  // the command definition
  typedef enum logic [2:0] {
    eAppRead    = 3'b001
    ,eAppWrite  = 3'b000
  } eAppCmd;

endpackage
