// 1 read-port, 1 write-port ram with a onehot address scheme
// write mask bytes
// reads are asynchronous
//

`include "bsg_defines.v"

module bsg_mem_1r1w_one_hot_mask_write_byte #(parameter `BSG_INV_PARAM(width_p)
                                           , parameter `BSG_INV_PARAM(els_p)
                                           , parameter mask_width_lp=(width_p>>3)
                                           , parameter safe_els_lp=`BSG_MAX(els_p,1)
                                           )
   (input   w_clk_i
    // Currently unused
    , input w_reset_i

    // one or zero-hot
    , input [safe_els_lp-1:0] w_v_i
    , input [width_p-1:0] w_data_i

    , input [mask_width_lp-1:0] w_mask_i

    // one or zero-hot
    , input [safe_els_lp-1:0] r_v_i
    , output logic [width_p-1:0] r_data_o
    );

  wire unused0 = w_reset_i;

  logic [width_p-1:0] w_mask_expanded_lo;
  
  bsg_expand_bitmask #(.in_width_p(mask_width_lp)
                      ,.expand_p(8)
                      ) mask_expand
                      (.i(w_mask_i)
                      ,.o(w_mask_expanded_lo)
                      );

  bsg_mem_1r1w_one_hot_mask_write_bit #(.width_p(width_p)
                                       ,.els_p(els_p)
                                       ) mem_one_hot_write_bits
                                       (.w_clk_i(w_clk_i)
                                       ,.w_reset_i(w_reset_i)
                                       ,.w_v_i(w_v_i)
                                       ,.w_data_i(w_data_i)
                                       ,.w_mask_i(w_mask_expanded_lo)
                                       ,.r_v_i(r_v_i)
                                       ,.r_data_o(r_data_o)
                                       );


   //synopsys translate_off

   initial
     begin
	if (width_p*els_p >= 64)
          $display("## %L: instantiating width_p=%d, els_p=%d (%m)"
                   ,width_p,els_p);
     end

   always_ff @(negedge w_clk_i)
     begin
       assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(w_v_i) <= 1)
         else $error("Invalid write address %b to %m is not onehot (w_reset_i=%b)\n", w_v_i, w_reset_i);
       assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(r_v_i) <= 1)
         else $error("Invalid read address %b to %m is not onehot (w_reset_i=%b)\n", r_v_i, w_reset_i);
     end

   //synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_one_hot)
