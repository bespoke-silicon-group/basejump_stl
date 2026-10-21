// 1 read-port, 1 write-port ram with a onehot address scheme
// write mask bytes
// reads are asynchronous
//

`include "bsg_defines.v"

module bsg_mem_1r1w_one_hot_mask_write_byte #(parameter `BSG_INV_PARAM(width_p)
                                           , parameter `BSG_INV_PARAM(els_p)
                                           , parameter write_mask_width_lp=(width_p>>3)
                                           , parameter safe_els_lp=`BSG_MAX(els_p,1)
                                           )
   (input   w_clk_i
    // Currently unused
    , input w_reset_i

    // one or zero-hot
    , input [safe_els_lp-1:0] w_v_i
    , input [width_p-1:0] w_data_i
    // for each bit set in the mask, a byte is written
    , input [write_mask_width_lp-1:0] w_mask_i

    // one or zero-hot
    , input [safe_els_lp-1:0] r_v_i
    , output logic [width_p-1:0] r_data_o
    );

  wire unused0 = w_reset_i;

  for(genvar i=0; i<write_mask_width_lp; i++)
  begin: replicate_non_masked_one_hot_rams
    bsg_mem_1r1w_one_hot #( 
      .width_p(8)
      ,.els_p(safe_els_lp)
    ) mem_1r1w_sync ( 
      .w_clk_i(w_clk_i)
      ,.w_reset_i(w_reset_i)
      ,.w_v_i(w_v_i & {safe_els_lp{w_mask_i[i]}})
      ,.w_data_i(w_data_i[(i*8)+:8])
      ,.r_v_i(r_v_i)
      ,.r_data_o(r_data_o[(i*8)+:8])
    );
  end


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
