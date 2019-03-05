// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`define bsg_mem_1rw_sync_macro_bit(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)                   \
  begin: macro                                           \
    tsmc40_1rw_lg``lgEls``_w``bits``_m``mux mem          \
      (.A     ( addr_i    )                              \
      ,.D     ( data_i    )                              \
      ,.BWEB  ( ~w_mask_i )                              \
      ,.WEB   ( ~w_i      )                              \
      ,.CEB   ( ~v_i      )                              \
      ,.CLK   ( clk_i     )                              \
      ,.Q     ( data_o    )                              \
      ,.DELAY ( 2'b0      )                              \
      ,.TEST  ( 2'b0      ));                            \
  end

`define bsg_mem_1rf_sync_macro_bit(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)                   \
  begin: macro                                           \
    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem          \
      (.A     ( addr_i    )                              \
      ,.D     ( data_i    )                              \
      ,.BWEB  ( ~w_mask_i )                              \
      ,.WEB   ( ~w_i      )                              \
      ,.CEB   ( ~v_i      )                              \
      ,.CLK   ( clk_i     )                              \
      ,.Q     ( data_o    )                              \
      ,.DELAY ( 2'b0      ));                            \
  end

module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
			               , parameter els_p=-1
			               , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [width_p-1:0] w_mask_i
    , input w_i
    , output [width_p-1:0]  data_o
    );
  
  wire unused = reset_i;

   // we use a 2 port RF because the 1 port RF
   // does not support bit-level masking for 80-bit width
   // alternatively we could instantiate 2 40-bit 1rw RF's 								
   `bsg_mem_1rf_sync_macro_bit(256,4,8,4) else
   `bsg_mem_1rf_sync_macro_bit(256,30,8,2) else
   `bsg_mem_1rf_sync_macro_bit(256,32,8,2) else
   `bsg_mem_1rf_sync_macro_bit(256,34,8,2) else
   `bsg_mem_1rf_sync_macro_bit(256,36,8,2) else
   `bsg_mem_1rw_sync_macro_bit(64,80,6,1)  else
   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ) synth
       (.*);

   // synopsys translate_off

   always_ff @(posedge clk_i)
     if (v_i)
       assert (addr_i < els_p)
         else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

  // synopsys translate_on


endmodule
