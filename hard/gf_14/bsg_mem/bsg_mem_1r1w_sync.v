
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


  // TODO: Set hardened macro configs in this define
  `ifdef BSG_MEM_HARD_1R1W_SYNC_MACROS
  `BSG_MEM_HARD_1R1W_SYNC_MACROS
  `endif
  // or define them here
  //
    begin: notmacro
    bsg_mem_1r1w_sync_synth #(
      .width_p(width_p)
      ,.els_p(els_p)
      ,.read_write_same_addr_p(read_write_same_addr_p)
    ) synth (.*); 
  end

   //synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p,harden_p);
     end

   always_ff @(negedge clk_i)
     if (w_v_i)
       begin
          assert ((reset_i === 'X) || (reset_i === 1'b1) || (w_addr_i < els_p))
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert ((reset_i === 'X) || (reset_i === 1'b1) || ~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p && !disable_collision_warning_p))
            else
              begin
                 $error("X'ing matched read address %x (%m)",r_addr_i);
              end
       end
   //synopsys translate_on


endmodule
