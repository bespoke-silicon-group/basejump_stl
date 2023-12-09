// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// reads are synchronous
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1r1w_sync_mask_write_bit.


`include "bsg_defines.sv"

module bsg_mem_1r1w_sync_mask_write_byte_synth #(parameter `BSG_INV_PARAM(width_p)
						, parameter `BSG_INV_PARAM(els_p)
						, parameter read_write_same_addr_p=0
						, parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                                , parameter latch_last_read_p=0
                                                , parameter write_mask_width_lp = width_p>>3
						, parameter harden_p=0
                                                , parameter disable_collision_warning_p=1
                                        )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    // for each bit set in the mask, a byte is written
    , input [`BSG_SAFE_MINUS(write_mask_width_lp, 1):0] w_mask_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
    );

   wire                   unused = reset_i;

   if (width_p == 0)
    begin: z
      wire unused0 = &{clk_i, w_v_i, w_mask_i, w_addr_i, r_v_i, r_addr_i};
      assign r_data_o = '0;
    end
   else
    begin: nz

  for(genvar i=0; i<write_mask_width_lp; i=i+1)
  begin: bk
    bsg_mem_1r1w_sync #( .width_p      (8)
                        ,.els_p        (els_p)
                        ,.addr_width_lp(addr_width_lp)
                        ,.latch_last_read_p(latch_last_read_p)
			,.verbose_if_synth_p(0) // don't print out details of ram if breaks into synth srams
                      ) mem_1r1w_sync
                      ( .clk_i  (clk_i)
                       ,.reset_i(reset_i)
                       ,.w_v_i    (w_v_i & w_mask_i[i])
                       ,.w_data_i (w_data_i[(i*8)+:8])
                       ,.w_addr_i (w_addr_i)
                       ,.r_v_i    (r_v_i)
                       ,.r_addr_i (r_addr_i)
                       ,.r_data_o (r_data_o[(i*8)+:8])
                      );
  end
   end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_byte_synth)

