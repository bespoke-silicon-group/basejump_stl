/**
 *  bsg_read_latch.v
 *
 *  This module is for SRAM macro which does not latch the output data for
 *  more than one cycle after it's read.
 *
 *  this is to be used with modules like bsg_mem_1rw_sync, etc,
 *  or inside hardeded bsg_mem module for proceses with SRAM macro, which does
 *  not last read data.
 *
 *  v_i should be 1 only when SRAM is being read (not write).
 *  e.g.) v_i & ~w_i
 *
 *  @author tommy
 *
 */


module bsg_read_latch
  #(parameter width_p="inv")
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [width_p-1:0] data_i
  
    , output logic [width_p-1:0] data_o
  );


  logic v_r;
  logic [width_p-1:0] data_r, data_n;

  assign data_n = (v_r & ~v_i)
    ? data_i
    : data_r;

  assign data_o = v_r
    ? data_i
    : data_r;


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_r <= 1'b0;
    end
    else begin
      v_r <= v_i;
      data_r <= data_n;
    end
  end

endmodule
