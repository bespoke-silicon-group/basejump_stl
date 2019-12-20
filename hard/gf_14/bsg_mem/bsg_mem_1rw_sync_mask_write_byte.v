
`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,mux) \
  if (harden_p && els_p == words && data_width_p == bits)      \
    begin: macro                                               \
      wire [data_width_p-1:0] wen;                             \
      genvar j;                                                \
      for(j = 0; j < write_mask_width_lp; j++)                 \
        assign wen[8*j+:8] = {8{write_mask_i[j]}};             \
                                                               \
      gf14_1rw_d``words``_w``bits``_m``mux``_byte              \
        mem                                                    \
          ( .CLK   ( clk_i  )                                  \
          , .A     ( addr_i )                                  \
          , .D     ( data_i )                                  \
          , .Q     ( data_o )                                  \
          , .CEN   ( ~v_i   )                                  \
          , .GWEN  ( ~w_i   )                                  \
          , .WEN   ( ~wen   )                                  \
          , .RET1N ( 1'b1   )                                  \
          , .STOV  ( 1'b0   )                                  \
          , .EMA   ( 3'b011 )                                  \
          , .EMAW  ( 2'b01  )                                  \
          , .EMAS  ( 1'b0   )                                  \
          );                                                   \
    end: macro

`define bsg_mem_1rw_sync_mask_write_byte_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && data_width_p == bits) begin: macro        \
      bsg_mem_1rw_sync_mask_write_byte_banked #(                              \
        .data_width_p(data_width_p)                                           \
        ,.els_p(els_p)                                                        \
        ,.latch_last_read_p(latch_last_read_p)                                \
        ,.num_width_bank_p(wbank)                                             \
        ,.num_depth_bank_p(dbank)                                             \
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
  

module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                         , parameter data_width_p = -1
                                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         , parameter write_mask_width_lp = data_width_p>>3
                                         , parameter harden_p = 1
                                         , parameter latch_last_read_p = 1
                                         )

  ( input                           clk_i
  , input                           reset_i
  , input                           v_i
  , input                           w_i
  , input [addr_width_lp-1:0]       addr_i
  , input [data_width_p-1:0]        data_i
  , input [write_mask_width_lp-1:0] write_mask_i
  , output logic [data_width_p-1:0] data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_byte_macro(512,64,2) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024,32,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(2048,64,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(4096,64,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(512,128,2) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024,32,4) else

  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024,256,8,1) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(512,64,4,4) else

  // no hardened version found
    begin : notmacro
      bsg_mem_1rw_sync_mask_write_byte_synth #(.data_width_p(data_width_p), .els_p(els_p))
        synth
          (.*);
    end // block: notmacro


  // synopsys translate_off
  always_comb
    begin
      assert (data_width_p % 8 == 0)
        else $error("data width should be a multiple of 8 for byte masking");
    end

  initial
    begin
      $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
   
endmodule

