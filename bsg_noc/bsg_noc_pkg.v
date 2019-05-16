`ifndef BSG_NOC_PKG_V
`define BSG_NOC_PKG_V

// direction type
package bsg_noc_pkg;
  typedef enum logic[2:0] {P=3'd0, W=3'd1, E=3'd2, N=3'd3, S=3'd4} Dirs;
endpackage

`endif
