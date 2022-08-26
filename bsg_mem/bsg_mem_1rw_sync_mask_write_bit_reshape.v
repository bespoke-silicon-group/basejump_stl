
//
// This module fattens a skinny bitmasked RAM to a more PD-friendly wider ram
// It does so by 'folding' the RAM like so:
// [aa]
// [bb]
// [cc]      [bbaa]    
// [dd]  ->  [ddcc] -> [ddccbbaa]
// [ee]  ->  [ffee] -> [hhggffee]
// [ff]      [hhgg]
// [gg]
// [hh]
//
//
module bsg_mem_1rw_sync_mask_write_bit_reshape #(parameter skinny_width_p=-1
                                                 , parameter skinny_els_p=-1
                                                 , parameter skinny_addr_width_lp=`BSG_SAFE_CLOG2(skinny_els_p)

                                                 , parameter fat_width_p=-1
                                                 , parameter fat_els_p=-1
                                                 , parameter fat_addr_width_lp=`BSG_SAFE_CLOG2(fat_els_p)

                                                 , parameter latch_last_read_p = 0

                                                 , parameter debug_lp = 0
                                                 )
   (input   clk_i
    , input reset_i

    , input                             v_i
    , input                             w_i
    , input [skinny_width_p-1:0]        w_mask_i
    , input [skinny_addr_width_lp-1:0]  addr_i
    , input [skinny_width_p-1:0]        data_i

    , output logic [skinny_width_p-1:0] data_o
    );

  localparam offset_width_lp = `BSG_SAFE_CLOG2(fat_width_p/skinny_width_p);

  logic                         fat_v_li;
  logic                         fat_w_li;
  logic [fat_width_p-1:0]       fat_w_mask_li;
  logic [fat_addr_width_lp-1:0] fat_addr_li;
  logic [fat_width_p-1:0]       fat_data_li;
  wire [offset_width_lp-1:0]    fat_offset = addr_i[0+:offset_width_lp];

  assign fat_v_li      = v_i;
  assign fat_w_li      = w_i;
  assign fat_w_mask_li = w_mask_i << (fat_offset*skinny_width_p);
  assign fat_addr_li   = addr_i[offset_width_lp+:fat_addr_width_lp];
  assign fat_data_li   = data_i << (fat_offset*skinny_width_p);

  logic [fat_width_p-1:0] fat_data_lo;
  bsg_mem_1rw_sync_mask_write_bit
   #(.width_p(fat_width_p)
     ,.els_p(fat_els_p)
     ,.latch_last_read_p(latch_last_read_p)
     )
   fat_mem
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(fat_v_li)
     ,.w_i(fat_w_li)
     ,.w_mask_i(fat_w_mask_li)
     ,.addr_i(fat_addr_li)
     ,.data_i(fat_data_li)

     ,.data_o(fat_data_lo)
     );

  logic [offset_width_lp-1:0] fat_offset_r;
  bsg_dff_reset
   #(.width_p(offset_width_lp))
   fat_offset_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fat_offset)
     ,.data_o(fat_offset_r)
     );

  bsg_mux
   #(.width_p(skinny_width_p), .els_p(fat_width_p/skinny_width_p))
   data_mux
    (.data_i(fat_data_lo)
     ,.sel_i(fat_offset_r)
     ,.data_o(data_o)
     );

  //synopsys translate_off
  initial
    begin
      assert (fat_width_p % skinny_width_p == 0) else $error("%m Fat width must be multiple of skinny width");
      assert (skinny_els_p % fat_els_p == 0) else $error("%m Skinny els must be a multiple of fat els");
    end

  logic r_v_r;
  logic [skinny_addr_width_lp-1:0] skinny_addr_r;
  logic [fat_addr_width_lp-1:0] fat_addr_r;

  bsg_dff
   #(.width_p(1+skinny_addr_width_lp+fat_addr_width_lp))
   read_reg
    (.clk_i(clk_i)
     ,.data_i({v_i & ~w_i, addr_i, fat_addr_li})
     ,.data_o({r_v_r, skinny_addr_r, fat_addr_r})
     );

  if (debug_lp)
    always_ff @(negedge clk_i)
      begin
        if (v_i & w_i)
            $display("%t [WRITE] Skinny[%x] = %b, WMASK: %b; Fat[%x] = %b, WMASK: %b", $time, addr_i, data_i, w_mask_i, fat_addr_li, fat_data_li, fat_w_mask_li);
        if (r_v_r)
            $display("%t [READ] Skinny[%x]: %b; Fat[%x]: %b", $time, skinny_addr_r, data_o, fat_addr_r, fat_data_lo);
      end
  //synopsys translate_on
   
endmodule
