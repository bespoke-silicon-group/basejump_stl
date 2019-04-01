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

`define bsg_mem_1rf_sync_macro_bit_banked(banks,words,bits,lgEls,mux) \
if (els_p == words && width_p == banks*bits)                          \
  begin: macro                                                        \
    genvar i;                                                         \
    for(i=0;i<banks;i++) begin: bank                                  \
      tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem                     \
        (.A     ( addr_i                  )                           \
        ,.D     ( data_i[i*bits+:bits]    )                           \
        ,.BWEB  ( ~w_mask_i[i*bits+:bits] )                           \
        ,.WEB   ( ~w_i                    )                           \
        ,.CEB   ( ~v_i                    )                           \
        ,.CLK   ( clk_i                   )                           \
        ,.Q     ( data_o[i*bits+:bits]    )                           \
        ,.DELAY ( 2'b0                    ));                         \
    end                                                               \
  end

//`define bsg_mem_1rf_sync_macro_bit_banks(words,bits,lgEls,mux) \
//if (els_p == words && width_p == 4*``bits``)             \
//  begin: macro                                           \
//    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem0         \
//      (.A     ( addr_i                         )         \
//      ,.D     ( data_i[width_p/4-1:0]          )         \
//      ,.BWEB  ( ~w_mask_i[width_p/4-1:0]       )         \
//      ,.WEB   ( ~w_i                           )         \
//      ,.CEB   ( ~v_i                           )         \
//      ,.CLK   ( clk_i                          )         \
//      ,.Q     ( data_o[width_p/4-1:0]          )         \
//      ,.DELAY ( 2'b0                           ));       \
//    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem1         \
//      (.A     ( addr_i                         )         \
//      ,.D     ( data_i[width_p/2-1:width_p/4]  )         \
//      ,.BWEB  ( ~w_mask_i[width_p/2-1:width_p/4])         \
//      ,.WEB   ( ~w_i                           )         \
//      ,.CEB   ( ~v_i                           )         \
//      ,.CLK   ( clk_i                          )         \
//      ,.Q     ( data_o[width_p/2-1:width_p/4]  )         \
//      ,.DELAY ( 2'b0                           ));       \
//    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem2         \
//      (.A     ( addr_i                         )         \
//      ,.D     ( data_i[3*width_p/4-1:width/2]  )         \
//      ,.BWEB  ( ~w_mask_i[3*width_p/4-1:width/2])         \
//      ,.WEB   ( ~w_i                           )         \
//      ,.CEB   ( ~v_i                           )         \
//      ,.CLK   ( clk_i                          )         \
//      ,.Q     ( data_o[3*width_p/4-1:width/2]  )         \
//      ,.DELAY ( 2'b0                           ));       \
//    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem3         \
//      (.A     ( addr_i                         )         \
//      ,.D     ( data_i[width_p-1:3*width_p/4]  )         \
//      ,.BWEB  ( ~w_mask_i[width_p-1:3*width_p/4] )         \
//      ,.WEB   ( ~w_i                           )         \
//      ,.CEB   ( ~v_i                           )         \
//      ,.CLK   ( clk_i                          )         \
//      ,.Q     ( data_o[width_p-1:3*width_p/4]  )         \
//      ,.DELAY ( 2'b0                           ));       \
//  end

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
   `bsg_mem_1rf_sync_macro_bit_banked(2,64,96,6,2) else
   `bsg_mem_1rf_sync_macro_bit_banked(8,64,46,6,2) else
   `bsg_mem_1rf_sync_macro_bit_banked(16,64,46,6,2) else
   `bsg_mem_1rf_sync_macro_bit(64,96,6,2)  else
   `bsg_mem_1rf_sync_macro_bit(64,15,6,2)  else
   `bsg_mem_1rf_sync_macro_bit(64,7,6,2)  else
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
