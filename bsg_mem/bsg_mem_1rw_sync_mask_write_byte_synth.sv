// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1r1w_sync_mask_write_byte.

`include "bsg_defines.sv"

module bsg_mem_1rw_sync_mask_write_byte_synth
  #(parameter `BSG_INV_PARAM(els_p)
    , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
    , parameter latch_last_read_p=0

    , parameter `BSG_INV_PARAM(data_width_p )
    , parameter write_mask_width_lp = data_width_p>>3
  )
  ( input clk_i
   ,input reset_i

   ,input v_i
   ,input w_i

   ,input [addr_width_lp-1:0]       addr_i
   ,input [`BSG_SAFE_MINUS(data_width_p, 1):0]        data_i
    // for each bit set in the mask, a byte is written
   ,input [`BSG_SAFE_MINUS(write_mask_width_lp, 1):0] write_mask_i

   ,output [`BSG_SAFE_MINUS(data_width_p, 1):0] data_o
  );

  genvar i;

  if (data_width_p == 0 || els_p == 0)
   begin: z
     wire unused0 = &{clk_i, reset_i, v_i, w_i, addr_i, data_i, write_mask_i};
     assign data_o = '0;
   end
  else
   begin: nz

  for(i=0; i<write_mask_width_lp; i=i+1)
  begin: bk
    bsg_mem_1rw_sync #( .width_p      (8)
                        ,.els_p        (els_p)
                        ,.addr_width_lp(addr_width_lp)
                        ,.latch_last_read_p(latch_last_read_p)
			,.verbose_if_synth_p(0) // don't print out details of ram if breaks into synth srams
                      ) mem_1rw_sync
                      ( .clk_i  (clk_i)
                       ,.reset_i(reset_i)
                       ,.data_i (data_i[(i*8)+:8])
                       ,.addr_i (addr_i)
                       ,.v_i    (v_i & (w_i ? write_mask_i[i] : 1'b1))
                       ,.w_i    (w_i & write_mask_i[i])
                       ,.data_o (data_o[(i*8)+:8])
                      );
  end
   end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_byte_synth)
