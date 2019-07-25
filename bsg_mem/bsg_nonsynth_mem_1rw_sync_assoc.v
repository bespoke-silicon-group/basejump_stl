/**
 *  bsg_nonsynth_mem_1rw_sync_assoc.v
 *
 *  bsg_mem_1rw_sync implementation using associative array.
 *
 *  This is for simulating arbitrarily large memories.
 *
 */


module bsg_nonsynth_mem_1rw_sync_assoc
  #(parameter width_p="inv"
    , parameter addr_width_p="inv"
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
  logic [width_p-1:0] mem [*];

  // write logic
  //
  always_ff @ (posedge clk_i) begin
    if (v_i & w_i) begin
      mem[addr_i] <= data_i;
    end
  end

  // read logic
  //
  always_ff @ (posedge clk_i) begin

    if (v_i & ~w_i) begin
      data_o <= mem[addr_i];
    end

  end


endmodule
