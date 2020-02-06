// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_macro(bits,words)  \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       saed90_``bits``x``words``_1P mem     \
         (.CE1  (clk_lo)                     \
         ,.WEB1 (~w_i)                      \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (~v_i)                      \
         ,.A1   (addr_i)                    \
         ,.I1   (data_i)                    \
         ,.O1   (data_o)                    \
         );                                 \
    end

module bsg_mem_1rw_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter addr_width_lp=$clog2(els_p)
                         // whether to substitute a 1r1w
                         ,parameter substitute_1r1w_p=1
                         ,parameter enable_clock_gating_p=1'b0
			 ,parameter latch_last_read_p=0
                         )
  (input                      clk_i
  ,input                      reset_i
  ,input [width_p-1:0]        data_i
  ,input [addr_width_lp-1:0]  addr_i
  ,input                      v_i
  ,input                      w_i
  ,output logic [width_p-1:0] data_o
  );

   wire clk_lo;
   
   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( v_i )
         ,.bypass_i( 1'b0 )
         ,.gated_clock_o( clk_lo )
         );
     end
   else
     begin
       assign clk_lo = clk_i;
     end

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_macro    (512,512) else

  begin: z
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
          (.w_clk_i   (clk_lo     )
          ,.w_reset_i (reset_i   )
          ,.w_v_i     (v_i & w_i )
          ,.w_addr_i  (addr_i    )
          ,.w_data_i  (data_i    )
          ,.r_addr_i  (addr_i    )
          ,.r_v_i     (v_i & ~w_i)
          ,.r_data_o  (data_lo   )
          );

        // register output data to convert sync to async
        always_ff @(posedge clk_lo)
          data_o <= data_lo;

      end // block: s1r1w
    else
      begin: notmacro

        // Instantiate a synthesizable 1rw sync ram
        bsg_mem_1rw_sync_synth #(.width_p(width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p)) synth
          (.clk_i( clk_lo )
          ,.reset_i
          ,.data_i
          ,.addr_i
          ,.v_i
          ,.w_i
          ,.data_o
          );
          

      end // block: notmacro
  end // block: z

  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
    end
  // synopsys translate_on

endmodule
