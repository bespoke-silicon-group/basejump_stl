// MBT 11/9/2014
//
// Synchronous 2-port ram.
// read and write can happen in the same cycle but **NOT ALLOWED**
//
//  /gro/cad/pdk/tsmc40/tsn45gs2prf/TSMCHOME/sram/Documentation/documents/  \
//  tsn45gs2prf_20071100_120a/DB_TSN45GS2PRF_20071100_120a.pdf 
//
//  -------------------------
//  "TSN45GS2PRF: TSMC 45nm (=N40G) General Purpose Superb Two-Port Register
//  File Compiler Databook"
//  ------------------------
//
// 1. Address Contention in General
//
// Since CLKW and CLKR are independent clocks whose edges may not be related
// to each other, address contentions between ports A and B are not resolved.
// Address contention is defined as the same address being latched during
// a write and read operation where insufficient clock separation occurs
// ( twrcc). If an address contention occurs, indeterminate results are read
// from the array. Timing specification twrcc relate the minimum time required
// between CLKW and CLKR in order for same address operations to occur without
// indeterminate results. If the same external signal drives CLKW and CLKR,
// indeterminate results will occur if the addresses match during
// a simultaneous write and read operation.
//
// 2. Address Contention with Write Operation Followed by Read Operation
//
// twrcc (measured from both clocks rising) is the minimum separation time
// required for a write to complete before a successful read of the same
// address can occur. This guarantees that the data is written to the array
// before the data is accessed for a read operation. If twrcc is violated
// during a write followed by read operation, then the read output is
// indeterminate.
// 
// 3. Address Contention with Read Operation Followed by Write Operation
//
// Violation of twrcc will cause the unknown data appears in the read port
// output.
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
     `bsg_mem_1r1w_sync_macro_rf(128,16,7,16,4) else
     `bsg_mem_1r1w_sync_macro_rf(64 ,48,6,48,4) else

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
     end

   // synopsys translate_on

endmodule
