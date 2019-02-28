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
    tsmc40_1rw_lg``lgEls``_w``bits``_m``mux mem           \
      (.A     ( addr_i )                                  \
      ,.D     ( data_i )                                  \
      ,.BWEB  ( ~wen   )                                  \
      ,.WEB   ( ~w_i   )                                  \
      ,.CEB   ( ~v_i   )                                  \
      ,.CLK   ( clk_i  )                                  \
      ,.Q     ( data_o )                                  \
      ,.DELAY ( 2'b0   )                                  \
      ,.TEST  ( 2'b0   ));                                \
  end

`define bsg_mem_1rf_sync_macro_byte(words,bits,lgEls,mux) \
if (els_p == words && data_width_p == bits)               \
  begin: macro                                            \
    wire [data_width_p-1:0] wen;                          \
    genvar i;                                             \
    for(i=0;i<write_mask_width_lp;i++)                    \
      assign wen[8*i+:8] = {8{write_mask_i[i]}};          \
    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem           \
      (.A     ( addr_i )                                  \
      ,.D     ( data_i )                                  \
      ,.BWEB  ( ~wen   )                                  \
      ,.WEB   ( ~w_i   )                                  \
      ,.CEB   ( ~v_i   )                                  \
      ,.CLK   ( clk_i  )                                  \
      ,.Q     ( data_o )                                  \
      ,.DELAY ( 2'b0   ));                                \
  end

`define bsg_mem_1rf_sync_macro_byte_banks(words,bits,lgEls,mux) \
if (els_p == 2*``words`` && data_width_p == bits)               \
  begin: macro                                                  \
    wire [data_width_p-1:0] wen;                                \
    wire [data_width_p-1:0] bank_data [0:1];                    \
    logic sel;                                                  \
    always_ff @(posedge clk_i)                                  \
      sel <= addr_i[0];                                         \
    genvar i;                                                   \
    for(i=0;i<write_mask_width_lp;i++)                          \
      assign wen[8*i+:8] = {8{write_mask_i[i]}};                \
    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem0                \
      (.A     ( addr_i[addr_width_lp-1:1] )                     \
      ,.D     ( data_i                    )                     \
      ,.BWEB  ( ~wen                      )                     \
      ,.WEB   ( ~w_i | addr_i[0]          )                     \
      ,.CEB   ( ~v_i | addr_i[0]          )                     \
      ,.CLK   ( clk_i                     )                     \
      ,.Q     ( bank_data[0]              )                     \
      ,.DELAY ( 2'b0   ));                                      \
    tsmc40_1rf_lg``lgEls``_w``bits``_m``mux mem1                \
      (.A     ( addr_i[addr_width_lp-1:1] )                     \
      ,.D     ( data_i                    )                     \
      ,.BWEB  ( ~wen                      )                     \
      ,.WEB   ( ~w_i | ~addr_i[0]         )                     \
      ,.CEB   ( ~v_i | ~addr_i[0]         )                     \
      ,.CLK   ( clk_i                     )                     \
      ,.Q     ( bank_data[1]              )                     \
      ,.DELAY ( 2'b0                      ));                   \
    assign data_o = sel? bank_data[1]: bank_data[0];            \
  end

module bsg_mem_1rw_sync_mask_write_byte

 #(parameter els_p = -1
  ,parameter data_width_p = -1
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
  `bsg_mem_1rf_sync_macro_byte_banks(512,32,9,4) else
  `bsg_mem_1rf_sync_macro_byte(1024,32,10,8) else
  `bsg_mem_1rw_sync_macro_byte(1024,32,10,4) else
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
