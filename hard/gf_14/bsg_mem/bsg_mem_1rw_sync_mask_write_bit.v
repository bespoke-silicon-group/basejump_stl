
`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits,mux) \
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      gf14_1rw_d``words``_w``bits``_m``mux``_bit              \
        mem                                                   \
          ( .CLK   ( clk_i     )                              \
          , .A     ( addr_i    )                              \
          , .D     ( data_i    )                              \
          , .Q     ( data_o    )                              \
          , .CEN   ( ~v_i      )                              \
          , .GWEN  ( ~w_i      )                              \
          , .WEN   ( ~w_mask_i )                              \
          , .RET1N ( 1'b1      )                              \
          , .STOV  ( 1'b0      )                              \
          , .EMA   ( 3'b011    )                              \
          , .EMAW  ( 2'b01     )                              \
          , .EMAS  ( 1'b0      )                              \
          );                                                  \
    end: macro

`define bsg_mem_1rw_sync_mask_write_bit_macro_banks(words,bits,mux,banks) \
  if (harden_p && els_p == words && width_p == banks*bits)                \
    begin: macro                                                          \
      genvar i;                                                           \
      for (i = 0; i < banks; i++)                                         \
        begin: bank                                                       \
          gf14_1rw_d``words``_w``bits``_m``mux``_bit                      \
            mem                                                           \
              ( .CLK   ( clk_i                          )                 \
              , .A     ( addr_i                         )                 \
              , .D     ( data_i[i*(width_p/banks)+:width_p/banks]    )    \
              , .Q     ( data_o[i*(width_p/banks)+:width_p/banks]    )    \
              , .CEN   ( ~v_i                           )                 \
              , .GWEN  ( ~w_i                           )                 \
              , .WEN   ( ~w_mask_i[i*(width_p/banks)+:width_p/banks] )    \
              , .RET1N ( 1'b1                           )                 \
              , .STOV  ( 1'b0                           )                 \
              , .EMA   ( 3'b011                         )                 \
              , .EMAW  ( 2'b01                          )                 \
              , .EMAS  ( 1'b0                           )                 \
              );                                                          \
        end: bank                                                         \
    end: macro

module bsg_mem_1rw_sync_mask_write_bit #( parameter width_p = -1
                                        , parameter els_p = -1
                                        , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p = 1
                                        , parameter latch_last_read_p = 1
                                        )
  ( input                       clk_i
  , input                       reset_i
  , input [width_p-1:0]         data_i
  , input [addr_width_lp-1:0]   addr_i
  , input                       v_i
  , input [width_p-1:0]         w_mask_i
  , input                       w_i
  , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_bit_macro( 64,15,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro( 64, 7,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,48,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,30,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,34,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,32,2) else

  `bsg_mem_1rw_sync_mask_write_bit_macro_banks(64,116,2, 2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro_banks(64,116,2, 4) else
  
  // HACKED VERSION OF THE FOLLOWING
  // `bsg_mem_1rw_sync_mask_write_bit_macro_banks( 8,116,2,32) else
  if (harden_p && els_p == 8 && width_p == 32*116)
    begin: macro
      genvar i;
      for (i = 0; i < 32; i++)
        begin: bank
          gf14_1rw_d16_w116_m2_bit
            mem
              ( .CLK   ( clk_i                                 )
              , .A     ( {1'b0, addr_i}                        )
              , .D     ( data_i[i*(width_p/32)+:width_p/32]    )
              , .Q     ( data_o[i*(width_p/32)+:width_p/32]    )
              , .CEN   ( ~v_i                                  )
              , .GWEN  ( ~w_i                                  )
              , .WEN   ( ~w_mask_i[i*(width_p/32)+:width_p/32] )
              , .RET1N ( 1'b1                                  )
              , .STOV  ( 1'b0                                  )
              , .EMA   ( 3'b010                                )
              , .EMAW  ( 2'b00                                 )
              , .EMAS  ( 1'b0                                  )
              );
        end: bank
    end: macro
  else
    begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth #(.width_p(width_p), .els_p(els_p))
        synth
          (.*);
    end // block: notmacro

  // synopsys translate_off
  always_ff @(posedge clk_i)
    begin
      if (v_i)
        assert (addr_i < els_p)
          else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);
    end

  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
    end
// synopsys translate_on

endmodule

