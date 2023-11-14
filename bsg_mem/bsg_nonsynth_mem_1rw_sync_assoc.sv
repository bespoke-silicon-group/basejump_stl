/**
 *  bsg_nonsynth_mem_1rw_sync_assoc.sv
 *
 *  bsg_mem_1rw_sync implementation using associative array.
 *
 *  This is for simulating arbitrarily large memories.
 *
 */


`include "bsg_defines.sv"

module bsg_nonsynth_mem_1rw_sync_assoc
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , input [width_p-1:0] data_i
    , input [addr_width_p-1:0] addr_i
    , input v_i
    , input w_i
    , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // associative array
  //
  `ifdef VERILATOR
    // version 4.024 supports associative array, but not wildcard indexed.
    logic [width_p-1:0] mem [longint];
  `else
    logic [width_p-1:0] mem [*];
  `endif

  // write logic
  //
  always_ff @ (posedge clk_i) begin
    if (~reset_i & v_i & w_i) begin
      mem[addr_i] <= data_i;
    end
  end

  // read logic
  //
  always_ff @ (posedge clk_i) begin

    if (~reset_i & v_i & ~w_i) begin
      data_o <= mem[addr_i];
    end

  end


endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_mem_1rw_sync_assoc)
