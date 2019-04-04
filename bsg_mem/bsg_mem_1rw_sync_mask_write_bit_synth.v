// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1rw_sync_mask_write_bit.
//

module bsg_mem_1rw_sync_mask_write_bit_synth #(parameter width_p=-1
					       , parameter els_p=-1
					       , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [width_p-1:0] w_mask_i
    , input w_i
    , output [width_p-1:0]  data_o
    );

   wire unused = reset_i;

   logic [addr_width_lp-1:0] addr_r;
   logic [width_p-1:0] mem [els_p-1:0];
   logic [width_p-1:0] data_n;

   always_ff @(posedge clk_i)
     if (v_i & ~w_i)
       addr_r <= addr_i;
     else
       addr_r <= 'X;

   assign data_o = mem[addr_r];

   for (genvar i = 0; i < width_p; i++) 
   begin : rof1
     assign data_n[i] = w_mask_i[i] ? data_i[i] : mem[addr_i][i];
   end // rof1

   always_ff @(posedge clk_i)
     if (v_i & w_i)
       mem[addr_i] <= data_n;

endmodule

