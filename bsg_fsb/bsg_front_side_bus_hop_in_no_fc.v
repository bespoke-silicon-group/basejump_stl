// bsg_front_side_bus_hop_in
//
// this implements the front side bus
// input side. it does *not* have backwards
// flow control, since nodes are supposed
// to have enough buffering to accept
// all incoming packets.
//

`include "bsg_defines.v"

module bsg_front_side_bus_hop_in_no_fc #(parameter width_p="inv")
  ( input   clk_i
  , input   reset_i
  
  , input [width_p-1:0] data_i
  , input               v_i
  
  // 0 is to the next switch
  // 1 is to the local switch
  
  , output [1:0][width_p-1:0] data_o
  , output [1:0]              v_o
  , input                     local_accept_i
  );

  logic [width_p-1:0] data_r;
  logic               v_r;

  // fixme: trade logic/speed for power
  // and avoid fake transitions

  assign data_o[0] = data_r;
  assign    v_o[0] = v_r;

  // to local node
  assign data_o[1] = data_r;
  assign    v_o[1] = v_r & local_accept_i;

  bsg_dff_reset #( .width_p($bits(v_r)) )
    v_reg
      ( .clk_i  ( clk_i )
      , .reset_i( reset_i )
      , .data_i ( v_i )
      , .data_o ( v_r )
      );

  bsg_dff #( .width_p($bits(data_r)) )
    data_reg
      ( .clk_i ( clk_i )
      , .data_i( data_i )
      , .data_o( data_r )
      );

endmodule

