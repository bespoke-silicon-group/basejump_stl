// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_macro(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)               \
  begin: macro                                       \
    tsmc40_1rw_d``words``_w``bits``_m``mux`` mem     \
      (.A     ( addr_i           )                   \
      ,.D     ( data_i           )                   \
      ,.BWEB  ( {``bits``{1'b0}} )                   \
      ,.WEB   ( ~w_i             )                   \
      ,.CEB   ( ~v_i             )                   \
      ,.CLK   ( clk_i            )                   \
      ,.Q     ( data_o           )                   \
      ,.WT    ( 1'b0             )                   \
      ,.DELAY ( 2'b0             )                   \
      ,.TEST  ( 2'b0             ));                 \
  end

`define bsg_mem_1rf_sync_macro(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)               \
  begin: macro                                       \
    tsmc40_1rf_d``words``_w``bits``_m``mux`` mem     \
      (.A     ( addr_i           )                   \
      ,.D     ( data_i           )                   \
      ,.BWEB  ( {``bits``{1'b0}} )                   \
      ,.WEB   ( ~w_i             )                   \
      ,.CEB   ( ~v_i             )                   \
      ,.CLK   ( clk_i            )                   \
      ,.Q     ( data_o           )                   \
      ,.DELAY ( 2'b0             ));                 \
  end

module bsg_mem_1rw_sync #(parameter width_p=-1
                          , parameter els_p=-1
                          , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                          //, parameter addr_width_lp=$clog2(els_p)
                          // whether to substitute a 1r1w
                          , parameter substitute_1r1w_p=1)
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

   `bsg_mem_1rf_sync_macro(256,34,8,2)   else

     begin : z
        // we substitute a 1r1w macro
        // fixme: theoretically there may be
        // a more efficient way to generate a 1rw synthesized ram
        if (substitute_1r1w_p)
          begin: s1r1w
             logic [width_p-1:0] data_lo;

             bsg_mem_1r1w #(.width_p(width_p)
                            ,.els_p(els_p)
                            ,.read_write_same_addr_p(0)
                            ) mem
               (.w_clk_i   (clk_i)
                ,.w_reset_i(reset_i)
                ,.w_v_i    (v_i & w_i)
                ,.w_addr_i (addr_i)
                ,.w_data_i (data_i)
                ,.r_addr_i (addr_i)
                ,.r_v_i    (v_i & ~w_i)
                ,.r_data_o (data_lo)
                );

             // register output data to convert sync to async
             always_ff @(posedge clk_i)
               data_o <= data_lo;
         end // block: subst
        else
          begin: notmacro

             bsg_mem_1rw_sync_synth
               # (.width_p(width_p)
                ,.els_p(els_p)
                ) synth
                 (.*);

          end // block: notmacro
     end // block: z


   // synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
     end

   // synopsys translate_on

endmodule
