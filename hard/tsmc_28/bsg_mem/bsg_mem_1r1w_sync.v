//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//

`define bsg_mem_1r1w_sync_macro_rf(words,bits,mux) \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          tsmc28_1r1w_d128_w64_m2_2rf mem                       \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.REB      ( ~r_v_i        )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r_data_o      )                       \
            );                                                  \
  end

`include "bsg_defines.v"

module bsg_mem_1r1w_sync #(parameter `BSG_INV_PARAM(width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter addr_width_lp=$clog2(els_p)
                          // whether to substitute a 1r1w
                          , parameter read_write_same_addr_p=0
                          , parameter disable_collision_warning_p=0
                          , parameter substitute_1r1w_p=1
                          , parameter harden_p=1)
   (input   clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    , output logic [width_p-1:0] r_data_o
    );

     `bsg_mem_1r1w_sync_macro_rf(128, 64, 2) else
     begin: notmacro

        bsg_mem_1r1w_sync_synth
          # (.width_p(width_p)
           ,.els_p(els_p)
           ) synth
            (.*);

     end // block: notmacro

   // synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
        assert ( read_write_same_addr_p == 0) else begin
                $error("## The hard memory do not support read write the same address. (%m)");
                $finish;
        end
     end

   // synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync)
