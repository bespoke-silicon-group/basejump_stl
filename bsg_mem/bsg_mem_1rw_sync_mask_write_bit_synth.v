// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1rw_sync_mask_write_bit.
//

module bsg_mem_1rw_sync_mask_write_bit_synth
  #(parameter width_p="inv"
	  , parameter els_p="inv"
    , parameter latch_last_read_p=0

		, localparam addr_width_lp=`BSG_SAFE_CLOG2(els_p)
  )
  ( input clk_i
    , input reset_i

    , input v_i
    , input w_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input [width_p-1:0] w_mask_i

    , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  logic [width_p-1:0] mem [els_p-1:0];

  always_ff @ (posedge clk_i) begin
    if (v_i & ~w_i) begin
      data_o <= mem[addr_i];
    end
    else begin
      if (latch_last_read_p == 0) begin
        data_o <= 'X;
      end
    end
  end


// The Verilator and non-Verilator models are functionally equivalent. However, Verilator
//   cannot handle an array of non-blocking assignments in a for loop. It would be nice to 
//   see if these two models synthesize the same, because we can then reduce to the Verilator
//   model and avoid double maintenence. One could also add this feature to Verilator...
//   (Identified in Verilator 4.011)
`ifdef VERILATOR
   logic [width_p-1:0] data_n;

   for (genvar i = 0; i < width_p; i++)
     begin : rof1
       assign data_n[i] = w_mask_i[i] ? data_i[i] : mem[addr_i][i];
     end // rof1

   always_ff @(posedge clk_i)
     if (v_i & w_i)
       mem[addr_i] <= data_n;

`else 
   always_ff @(posedge clk_i)
     if (v_i & w_i)
       for (integer i = 0; i < width_p; i=i+1)
         if (w_mask_i[i])
           mem[addr_i][i] <= data_i[i];
`endif

endmodule
