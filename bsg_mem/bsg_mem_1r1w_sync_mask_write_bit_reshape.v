
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

    , output                            w_v_o
    , output [fat_width_p-1:0]          w_mask_o
    , output [fat_addr_width_lp-1:0]    w_addr_o
    , output [fat_width_p-1:0]          w_data_o

    , output                            r_v_o
    , output [fat_addr_width_lp-1:0]    r_addr_o
    , input logic [fat_width_p-1:0]     r_data_i
    );

  localparam offset_width_lp = `BSG_SAFE_CLOG2(fat_width_p/skinny_width_p);

  logic [offset_width_lp-1:0] w_offset;
  assign w_offset = w_addr_i[0+:offset_width_lp];

  assign w_v_o    = w_v_i;
  assign w_mask_o = w_mask_i << (w_offset*skinny_width_p);
  assign w_addr_o = w_addr_i[offset_width_lp+:fat_addr_width_lp];
  assign w_data_o = w_data_i << (w_offset*skinny_width_p);

  logic [offset_width_lp-1:0] r_offset;
  assign r_offset = r_addr_i[0+:offset_width_lp];

  assign r_v_o    = r_v_i;
  assign r_addr_o = r_addr_i[offset_width_lp+:fat_addr_width_lp];

  logic [offset_width_lp-1:0] r_offset_r;
  bsg_dff_reset
   #(.width_p(offset_width_lp))
   r_offset_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(r_offset)
     ,.data_o(r_offset_r)
     );

  bsg_mux
   #(.width_p(skinny_width_p), .els_p(fat_width_p/skinny_width_p))
   r_data_mux
    (.data_i(r_data_i)
     ,.sel_i(r_offset_r)
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
     ,.data_i({r_v_i, r_addr_i, r_addr_o})
     ,.data_o({r_v_r, skinny_r_addr_r, fat_r_addr_r})
     );

  if (debug_lp)
    always_ff @(negedge clk_i)
      begin
        if (w_v_o)
            $display("%t [WRITE] Skinny[%x] = %b, WMASK: %b; Fat[%x] = %b, WMASK: %b", $time, w_addr_i, w_data_i, w_mask_i, w_addr_o, w_data_o, w_mask_o);
        if (r_v_r)
            $display("%t [READ] Skinny[%x]: %b; Fat[%x]: %b", $time, skinny_r_addr_r, r_data_o, fat_r_addr_r, r_data_i);
      end
  //synopsys translate_on
   
endmodule
