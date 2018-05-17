// MBT 11/9/2014
//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//
// See "TSN45GS2PRF: TSMC 45nm (=N40G) General Purpose Superb Two-Port
// Register File Compiler Databook"
//
`define bsg_mem_1r1w_sync_macro_rf(words,bits,lgEls,newBits,mux) \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          wire [newBits-1:0] tmp_lo,tmp_li;                     \
          assign r_data_o = tmp_lo[bits-1:0];                    \
          assign tmp_li = newBits ' (w_data_i);                  \
                                                                \
          tsmc40_2rf_lg``lgEls``_w``bits``_m``mux``_all mem    \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( tmp_li        )                       \
             ,.BWEB     ( {``newBits``{1'b0}}     )             \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.REB      ( ~r_v_i        )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( tmp_lo        )                       \
                                                                \
             ,.RDELAY   ( 2'b00         )                       \
             ,.WDELAY   ( 2'b00         )                       \
            );                                                  \
  end

module bsg_mem_1r1w_sync #(parameter width_p=-1
                          , parameter els_p=-1
                          , parameter addr_width_lp=$clog2(els_p)
                          // whether to substitute a 1r1w
                          , parameter read_write_same_addr_p= 0
                          , parameter substitute_1r1w_p=1)
   (input   clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    , output logic [width_p-1:0] r_data_o
    );

     `bsg_mem_1r1w_sync_macro_rf(128,74,7,74,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,73,7,74,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,72,7,72,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,71,7,72,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,70,7,70,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,69,7,70,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,68,7,68,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,67,7,68,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,66,7,66,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,65,7,66,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,64,7,64,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,63,7,64,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,62,7,62,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,61,7,62,2) else
     `bsg_mem_1r1w_sync_macro_rf(128,16,7,16,2) else
     `bsg_mem_1r1w_sync_macro_rf(64 ,48,6,48,2) else

     begin : z
        // we substitute a 1r1w macro
        // fixme: theoretically there may be
        // a more efficient way to generate a 1r1w synthesized ram
        if (substitute_1r1w_p)
          begin: s1r1w
             logic [width_p-1:0] data_lo;

             bsg_mem_1r1w #(.width_p(width_p)
                            ,.els_p(els_p)
                            ,.read_write_same_addr_p(0)
                            ) mem
               (.w_clk_i   (clk_i)
                ,.w_reset_i(reset_i)
                ,.w_v_i    (w_v_i & w_v_i)
                ,.w_addr_i (w_addr_i)
                ,.w_data_i (w_data_i)
                ,.r_addr_i (r_addr_i)
                ,.r_v_i    (r_v_i & ~r_v_i)
                ,.r_data_o (data_lo)
                );

             // register output data to convert sync to async
             always_ff @(posedge clk_i)
               r_data_o <= data_lo;
         end // block: subst
        else
          begin: notmacro

             bsg_mem_1r1w_sync_synth
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
        assert ( read_write_same_addr_p == 0) else begin
                $error("## The hard memory do not support read write the same address. (%m)");
                $finish;
        end
     end

   // synopsys translate_on

endmodule
