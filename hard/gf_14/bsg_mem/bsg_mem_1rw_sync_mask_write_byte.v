
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

`define bsg_mem_1rw_sync_mask_write_byte_macro_banks_cracks(words,bits,mux,banks,cracks) \
  if (harden_p && els_p == words*cracks && data_width_p == bits*banks)                \
    begin: macro                                                                      \
      localparam lg_cracks_lp = `BSG_SAFE_CLOG2(cracks);                              \
      localparam lg_words_lp = `BSG_SAFE_CLOG2(words);                                \
      wire [data_width_p-1:0] wen;                                                    \
      wire [cracks-1:0][data_width_p-1:0] data_lo;                                    \
      for(genvar k = 0; k < write_mask_width_lp; k++)                                 \
        assign wen[8*k+:8] = {8{write_mask_i[k]}};                                    \
      for (genvar j = 0; j < cracks; j++)                                             \
        begin: crack                                                                  \
          wire crack_sel_li = (addr_i[lg_words_lp+:lg_cracks_lp] == j);               \
          wire v_li = v_i & crack_sel_li;                                             \
          wire w_li = w_i & crack_sel_li;                                             \
          for (genvar i = 0; i < banks; i++)                                          \
            begin: bank                                                               \
              gf14_1rw_d``words``_w``bits``_m``mux``_byte                             \
                mem                                                                   \
                  ( .CLK   ( clk_i  )                                                 \
                  , .A     ( addr_i[0+:lg_words_lp] )                                 \
                  , .D     ( data_i[i*(data_width_p/banks)+:data_width_p/banks]     ) \
                  , .Q     ( data_lo[j][i*(data_width_p/banks)+:data_width_p/banks] ) \
                  , .CEN   ( ~v_li  )                                                 \
                  , .GWEN  ( ~w_li  )                                                 \
                  , .WEN   ( ~wen[i*(data_width_p/banks)+:data_width_p/banks] )       \
                  , .RET1N ( 1'b1   )                                                 \
                  , .STOV  ( 1'b0   )                                                 \
                  , .EMA   ( 3'b011 )                                                 \
                  , .EMAW  ( 2'b01  )                                                 \
                  , .EMAS  ( 1'b0   )                                                 \
                  );                                                                  \
            end                                                                       \
        end                                                                           \
      logic [lg_cracks_lp-1:0] crack_r;                                               \
      always_ff @(posedge clk_i)                                                      \
        if (v_i & ~w_i) crack_r <= addr_i[lg_words_lp+:lg_cracks_lp];                 \
      assign data_o = data_lo[crack_r];                                               \
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
  `bsg_mem_1rw_sync_mask_write_byte_macro_banks_cracks(512,64,2,4,4) else

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

