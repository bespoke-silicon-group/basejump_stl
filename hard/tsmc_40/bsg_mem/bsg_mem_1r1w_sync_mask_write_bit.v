// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//
// See "TSN45GS2PRF: TSMC 45nm (=N40G) General Purpose Superb Two-Port
// Register File Compiler Databook"
//

`define bsg_mem_1r1w_sync_macro_rf(words,bits,lgEls,mux)        \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          tsmc40_2rf_lg``lgEls``_w``bits``_m``mux``_bit mem    \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.REB      ( ~r_v_i        )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r_data_o      )                       \
                                                                \
             ,.RDELAY   ( 2'b00         )                       \
             ,.WDELAY   ( 2'b00         )                       \
            );                                                  \
  end                                   


module bsg_mem_1r1w_sync_mask_write_bit #(parameter width_p=-1
                                        , parameter els_p=-1
                                        , parameter read_write_same_addr_p=0
                                        , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p=1
                                        )
   (  input clk_i
    , input reset_i

    , input                     w_v_i
    , input [width_p-1:0]       w_mask_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

`bsg_mem_1r1w_sync_macro_rf(256,128,8,1) else
`bsg_mem_1r1w_sync_macro_rf(64,88,6,1) else
   bsg_mem_1r1w_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p (els_p  )
       ,.read_write_same_addr_p(read_write_same_addr_p)
       ,.harden_p(harden_p)
       ) synth
       (.*);

   //synopsys translate_off

/*
   always_ff @(negedge clk_i)
     begin
        if (reset_i!==1'b1 & (r_v_i | w_v_i))
          $display("@@ w=%b w_addr=%x w_data=%x w_mask=%x r=%b r_addr=%x (%m)",w_v_i,w_addr_i,w_data_i,w_mask_i,r_v_i,r_addr_i);
     end
 */

   always_ff @(posedge clk_i)
     if (w_v_i)
       begin
          assert (w_addr_i < els_p)
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert (~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
            else
              begin
                 $error("%m: Attempt to read and write same address (reset_i %b, %x <= %x (mask %x)",reset_i, w_addr_i,w_data_i,w_mask_i);
                 //$finish();
              end
       end

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p, harden_p);
        assert ( read_write_same_addr_p == 0) else begin
                $error("## The hard memory do not support read write the same address. (%m)");
                $finish;
     end

   //synopsys translate_on

endmodule
