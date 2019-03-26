// DGS 3/2/2018
// 
// Synchronous 1 read-port and 1 write port ram.
//

`define bsg_mem_1r1w_sync_macro(bits,words) \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       saed90_``bits``x``words``_2P mem     \
         (.CE1  (clk_lo)                     \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (1'b0)                      \
         ,.A1   (r_addr_i)                  \
         ,.O1   (r_data_o)                  \
         ,.CE2  (clk_i)                     \
         ,.WEB2 (~w_v_i)                    \
         ,.CSB2 (1'b0)                      \
         ,.A2   (w_addr_i)                  \
         ,.I2   (w_data_i)                  \
         );                                 \
    end

module bsg_mem_1r1w_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter addr_width_lp=$clog2(els_p)
                         ,parameter read_write_same_addr_p=0
                         // whether to substitute a 1r1w
                         ,parameter substitute_1r1w_p=1
                         ,parameter harden_p = 1
                         ,parameter enable_clock_gating_p=1'b0
                         )
      
  (input   clk_i
    , input reset_i
    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i
    , output logic [width_p-1:0] r_data_o
  );

   wire clk_lo;

   bsg_clkgate_optional icg
     (.clk_i( clk_i )
     ,.en_i( w_v_i | r_v_i )
     ,.bypass_i( ~enable_clock_gating_p )
     ,.gated_clock_o( clk_lo )
     );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1r1w_sync_macro    (64, 512) else

  begin: z
    // we substitute a 1r1w macro
    // fixme: theoretically there may be
    // a more efficient way to generate a 1rw synthesized ram
    if (substitute_1r1w_p)
      begin: s1r1w

        logic [width_p-1:0] data_lo;

        bsg_mem_1r1w_sync #(.width_p(width_p)
                      ,.els_p(els_p)
                      ,.read_write_same_addr_p(1)
                      ) mem
          (.clk_i( clk_lo )
          ,.reset_i
          ,.w_v_i
          ,.w_addr_i
          ,.w_data_i
          ,.r_v_i
          ,.r_addr_i
          ,.r_data_o
          );

        // register output data to convert sync to async
        //always_ff @(posedge clk_i)
          //data_o <= data_lo;

      end // block: s1r1w
    else
      begin: notmacro

        // Instantiate a synthesizable 1rw sync ram
        bsg_mem_1r1w_sync_synth #(.width_p(width_p), .els_p(els_p), .read_write_same_addr_p(read_write_same_addr_p)) synth
          (.clk_i( clk_lo )
          ,.reset_i
          ,.w_v_i
          ,.w_addr_i
          ,.w_data_i
          ,.r_v_i
          ,.r_addr_i
          ,.r_data_o
          );

      end // block: notmacro
  end // block: z

  // synopsys translate_off
  //initial
    //begin
      //$display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p/**,substitute_1r1w_p**/);
    //end
  // synopsys translate_on

endmodule

