`include "bsg_defines.sv"

module bsg_mem_2rw_sync_mask_write_byte_synth #( parameter `BSG_INV_PARAM(width_p )
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter read_write_same_addr_p=0
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter harden_p = 1
                         , parameter disable_collision_warning_p=0     
                         , parameter write_mask_width_lp=(width_p>>3)              
                         )
  ( input                      clk_i
  , input                      reset_i

  , input [width_p-1:0]        a_data_i
  , input [write_mask_width_lp-1:0] a_w_mask_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [width_p-1:0]        b_data_i
  , input [write_mask_width_lp-1:0] b_w_mask_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [width_p-1:0] a_data_o
  , output logic [width_p-1:0] b_data_o
  );

   wire                   unused = reset_i;

   if (width_p == 0)
    begin: z
      wire unused0 = &{clk_i, a_data_i, a_w_mask_i, a_addr_i, a_v_i, a_w_i};
      wire unused1 = &{clk_i, b_data_i, b_w_mask_i, b_addr_i, b_v_i, b_w_i};
      assign a_data_o = '0;
      assign b_data_o = '0;
    end
   else
    begin: nz

  genvar i;
  for(i=0; i<write_mask_width_lp; i=i+1)
  begin: bk
    bsg_mem_2rw_sync #( .width_p      (8)
                        ,.els_p        (els_p)
                        ,.addr_width_lp(addr_width_lp)
                        ,.disable_collision_warning_p(disable_collision_warning_p)
                        ,.harden_p(harden_p)
                      ) mem_2rw_sync
                      ( .clk_i  (clk_i)
                       ,.reset_i(reset_i)
                       ,.a_data_i (a_data_i[(i*8)+:8])
                       ,.a_addr_i (a_addr_i)
                       ,.a_v_i    (a_v_i & (a_w_i ? a_w_mask_i[i] : 1'b1))
                       ,.a_w_i    (a_w_i & a_w_mask_i[i])
                       ,.a_data_o (a_data_o[(i*8)+:8])
                       ,.b_data_i (b_data_i[(i*8)+:8])
                       ,.b_addr_i (b_addr_i)
                       ,.b_v_i    (b_v_i & (b_w_i ? b_w_mask_i[i] : 1'b1))
                       ,.b_w_i    (b_w_i & b_w_mask_i[i])
                       ,.b_data_o (b_data_o[(i*8)+:8])
                      );
  end
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_byte_synth)

