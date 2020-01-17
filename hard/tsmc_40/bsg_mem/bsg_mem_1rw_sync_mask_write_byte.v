// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_macro_byte(words,bits,lgEls,mux) \
if (els_p == words && data_width_p == bits)               \
  begin: macro                                            \
    wire [data_width_p-1:0] wen;                          \
    genvar i;                                             \
    for(i=0;i<write_mask_width_lp;i++)                    \
      assign wen[8*i+:8] = {8{write_mask_i[i]}};          \
    tsmc40_1rw_d``words``_w``bits``_m``mux``_byte mem     \
      (.A     ( addr_i )                                  \
      ,.D     ( data_i )                                  \
      ,.BWEB  ( ~wen   )                                  \
      ,.WEB   ( ~w_i   )                                  \
      ,.CEB   ( ~v_i   )                                  \
      ,.CLK   ( clk_i  )                                  \
      ,.Q     ( data_o )                                  \
      ,.DELAY ( 2'b0   ));                                \
  end

`define bsg_mem_1rf_sync_macro_byte(words,bits,lgEls,mux) \
if (els_p == words && data_width_p == bits)               \
  begin: macro                                            \
    wire [data_width_p-1:0] wen;                          \
    genvar i;                                             \
    for(i=0;i<write_mask_width_lp;i++)                    \
      assign wen[8*i+:8] = {8{write_mask_i[i]}};          \
    tsmc40_1rf_d``words``_w``bits``_m``mux``_byte mem     \
      (.A     ( addr_i )                                  \
      ,.D     ( data_i )                                  \
      ,.BWEB  ( ~wen   )                                  \
      ,.WEB   ( ~w_i   )                                  \
      ,.CEB   ( ~v_i   )                                  \
      ,.CLK   ( clk_i  )                                  \
      ,.Q     ( data_o )                                  \
      ,.DELAY ( 2'b0   ));                                \
  end

`define bsg_mem_1rw_sync_mask_write_byte_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && data_width_p == bits) begin: macro        \
      bsg_mem_1rw_sync_mask_write_byte_banked #(                              \
        .data_width_p(data_width_p)                                           \
        ,.els_p(els_p)                                                        \
        ,.num_width_bank_p(wbank)                                             \
        ,.num_depth_bank_p(dbank)                                             \
        ,.latch_last_read_p(latch_last_read_p)                                \
      ) bmem (                                                                \
        .clk_i(clk_i)                                                         \
        ,.reset_i(reset_i)                                                    \
        ,.v_i(v_i)                                                            \
        ,.w_i(w_i)                                                            \
        ,.addr_i(addr_i)                                                      \
        ,.data_i(data_i)                                                      \
        ,.write_mask_i(write_mask_i)                                          \
        ,.data_o(data_o)                                                      \
      );                                                                      \
    end: macro

module bsg_mem_1rw_sync_mask_write_byte

 #(parameter els_p = -1
  ,parameter data_width_p = -1
  ,parameter latch_last_read_p = 0
  ,parameter harden_p = 1
  ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
  ,parameter write_mask_width_lp = data_width_p>>3
  )

  (input                           clk_i
  ,input                           reset_i

  ,input                           v_i
  ,input                           w_i

  ,input [addr_width_lp-1:0]       addr_i
  ,input [data_width_p-1:0]        data_i

  ,input [write_mask_width_lp-1:0] write_mask_i

  ,output [data_width_p-1:0] data_o
  );

  wire unused = reset_i;

  `bsg_mem_1rw_sync_macro_byte(4096,64,12,8) else
  `bsg_mem_1rw_sync_macro_byte(2048,64,11,4) else
  `bsg_mem_1rw_sync_macro_byte(2048,64,11,4) else
  `bsg_mem_1rw_sync_macro_byte(512,32,9,4) else
  `bsg_mem_1rf_sync_macro_byte(1024,32,10,8) else
  `bsg_mem_1rw_sync_macro_byte(1024,32,10,4) else
  //`bsg_mem_1rw_sync_macro_byte(1024,512,10,2) else
  `bsg_mem_1rw_sync_macro_byte(512,64,9,4) else
  `bsg_mem_1rw_sync_macro_byte(1024,64,10,4) else

  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024,32,1,2) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(2048,256,4,2) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024,512,8,2) else
  // no hardened version found
    begin  : notmacro

       bsg_mem_1rw_sync_mask_write_byte_synth
	 #(.els_p(els_p), .data_width_p(data_width_p))
       synth (.*);

    end


  // synopsys translate_off

  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

   initial
     begin
        $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
     end

  // synopsys translate_on
   
endmodule
