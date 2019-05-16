`ifndef BSG_NOC_PKG_V
`define BSG_NOC_PKG_V

// direction type
package bsg_noc_pkg;
  // Explictly sizing enum values (P=3'd0, not P=0) is necessary per Verilator 4.015
  // https://www.veripool.org/issues/1442-Verilator-Enum-values-without-explicit-widths-are-considered-unsized
  typedef enum logic[2:0] {P=3'd0, W, E, N, S} Dirs;
endpackage

`endif
