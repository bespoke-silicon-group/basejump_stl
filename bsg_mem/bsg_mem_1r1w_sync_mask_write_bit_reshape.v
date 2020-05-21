
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
// NOTE: This module requires that write_then_read_same_address is enabled in the fat memory
//
module bsg_mem_1r1w_sync_mask_write_bit_reshape #(parameter skinny_width_p=-1
                                                  , parameter skinny_els_p=-1
                                                  , parameter skinny_addr_width_lp=`BSG_SAFE_CLOG2(skinny_els_p)

                                                  , parameter fat_width_p=-1
                                                  , parameter fat_els_p=-1
                                                  , parameter fat_addr_width_lp=`BSG_SAFE_CLOG2(fat_els_p)

                                                  , parameter debug_lp = 0
                                                  )
   (input   clk_i
    , input reset_i

    , input                             w_v_i
    , input [skinny_width_p-1:0]        w_mask_i
    , input [skinny_addr_width_lp-1:0]  w_addr_i
    , input [skinny_width_p-1:0]        w_data_i

    , input                             r_v_i
    , input [skinny_addr_width_lp-1:0]  r_addr_i
    , output logic [skinny_width_p-1:0] r_data_o
    );

  localparam offset_width_lp = `BSG_SAFE_CLOG2(fat_width_p/skinny_width_p);

  logic                         fat_w_v_li;
  logic [fat_width_p-1:0]       fat_w_mask_li;
  logic [fat_addr_width_lp-1:0] fat_w_addr_li;
  logic [fat_width_p-1:0]       fat_w_data_li;
  wire [offset_width_lp-1:0]    fat_w_offset = w_addr_i[0+:offset_width_lp];

  assign fat_w_v_li    = w_v_i;
  assign fat_w_mask_li = w_mask_i << (fat_w_offset*skinny_width_p);
  assign fat_w_addr_li = w_addr_i[offset_width_lp+:fat_addr_width_lp];
  assign fat_w_data_li = w_data_i << (fat_w_offset*skinny_width_p);

  logic                         fat_r_v_li;
  logic [fat_addr_width_lp-1:0] fat_r_addr_li;
  logic [fat_width_p-1:0]       fat_r_data_lo;
  wire [offset_width_lp-1:0]    fat_r_offset = r_addr_i[0+:offset_width_lp];

  assign fat_r_v_li    = r_v_i;
  assign fat_r_addr_li = r_addr_i[offset_width_lp+:fat_addr_width_lp];

  bsg_mem_1r1w_sync_mask_write_bit
   #(.width_p(fat_width_p)
     ,.els_p(fat_els_p)
     ,.read_write_same_addr_p(1)
     )
   fat_mem
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(fat_w_v_li)
     ,.w_mask_i(fat_w_mask_li)
     ,.w_addr_i(fat_w_addr_li)
     ,.w_data_i(fat_w_data_li)

     ,.r_v_i(fat_r_v_li)
     ,.r_addr_i(fat_r_addr_li)

     ,.r_data_o(fat_r_data_lo)
     );

  logic [offset_width_lp-1:0] fat_r_offset_r;
  bsg_dff_reset
   #(.width_p(offset_width_lp))
   fat_r_offset_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(fat_r_offset)
     ,.data_o(fat_r_offset_r)
     );

  bsg_mux
   #(.width_p(skinny_width_p), .els_p(fat_width_p/skinny_width_p))
   r_data_mux
    (.data_i(fat_r_data_lo)
     ,.sel_i(fat_r_offset_r)
     ,.data_o(r_data_o)
     );

  //synopsys translate_off
  initial
    begin
      assert (fat_width_p % skinny_width_p == 0) else $error("%m Fat width must be multiple of skinny width");
      assert (skinny_els_p % fat_els_p == 0) else $error("%m Skinny els must be a multiple of fat els");
    end

  logic r_v_r;
  logic [skinny_addr_width_lp-1:0] skinny_r_addr_r;
  logic [fat_addr_width_lp-1:0] fat_r_addr_r;

  bsg_dff
   #(.width_p(1+skinny_addr_width_lp+fat_addr_width_lp))
   read_reg
    (.clk_i(clk_i)
     ,.data_i({r_v_i, r_addr_i, fat_r_addr_li})
     ,.data_o({r_v_r, skinny_r_addr_r, fat_r_addr_r})
     );

  if (debug_lp)
    always_ff @(negedge clk_i)
      begin
        if (w_v_i)
            $display("%t [WRITE] Skinny[%x] = %b, WMASK: %b; Fat[%x] = %b, WMASK: %b", $time, w_addr_i, w_data_i, w_mask_i, fat_w_addr_li, fat_w_data_li, fat_w_mask_li);
        if (r_v_r)
            $display("%t [READ] Skinny[%x]: %b; Fat[%x]: %b", $time, skinny_r_addr_r, r_data_o, fat_r_addr_r, fat_r_data_lo);
      end
  //synopsys translate_on
   
endmodule
