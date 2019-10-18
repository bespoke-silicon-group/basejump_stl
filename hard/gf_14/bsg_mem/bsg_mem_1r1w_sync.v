
`define bsg_mem_1r1w_sync_macro(words,bits,mux)\
  if (harden_p && els_p == words && width_p == bits)     \
    begin: macro                                            \
    gf14_1r1w_d``words``_w``bits``_m``mux                     \
      mem (                                                    \
      .CLKA   (clk_i)                                           \
      ,.CLKB  (clk_i)                                           \
      ,.CENA  (~r_v_i)                                         \
      ,.AA    (r_addr_i)                                      \
      ,.QA    (r_data_o)                                      \
      ,.CENB  (~w_v_i)                                        \
      ,.AB    (w_addr_i)                                      \
      ,.DB    (w_data_i)                                      \
      ,.EMAA  (3'b011)                                        \
      ,.EMAB  (3'b011)                                        \
      ,.EMASA (1'b0)                                          \
      ,.STOV  (1'b0)                                          \
      ,.RET1N (1'b1)                                          \
    );                                                        \
  end
      
      

module bsg_mem_1r1w_sync
  #(parameter width_p=-1
    , parameter els_p=-1
    , parameter read_write_same_addr_p=0
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    , parameter harden_p=1
    , parameter disable_collision_warning_p=0
    , parameter enable_clock_gating_p=0
  )
  (
    input clk_i
    , input reset_i
    
    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    
    , output logic [width_p-1:0] r_data_o
  );


  `bsg_mem_1r1w_sync_macro(32,92,1) else
    begin: notmacro
    bsg_mem_1r1w_sync_synth #(
      .width_p(width_p)
      ,.els_p(els_p)
      ,.read_write_same_addr_p(read_write_same_addr_p)
    ) synth (.*); 
  end



endmodule
