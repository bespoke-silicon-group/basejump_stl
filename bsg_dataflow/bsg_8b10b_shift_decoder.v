`include "bsg_defines.v"

module bsg_8b10b_shift_decoder
  ( input   clk_i
  , input   data_i

  , output logic [7:0] data_o
  , output logic       k_o
  , output logic       v_o
  
  , output logic       frame_align_o
  );

  // 8b10b decode running disparity and error signals
  wire        decode_rd_r, decode_rd_n, decode_rd_lo;
  wire        decode_data_err_lo;
  wire        decode_rd_err_lo;

  // Signal if a RD- or RD+ comma code has been shifted in
  wire        comma_code_rdn, comma_code_rdp;

  // Signal that indicates that a frame (10b) have arrived
  wire        frame_recv;

  // Input Shift Register
  //======================
  // We need to use a shift register (rather than a SIPO) becuase we don't have
  // reset and we need to detect frame alignments. 8b10b shifts LSB first, so
  // don't change the shift direction!

  logic [9:0] shift_reg_r;

  always_ff @(posedge clk_i)
    begin
      shift_reg_r[8:0] <= shift_reg_r[9:1];
      shift_reg_r[9]   <= data_i;
    end

  // Comma Code Detection and Frame Alignment
  //==========================================
  // We are using a very simple comma code detection to reduce the amount of
  // logic. This means that use of K.28.7 is not allowed. Sending a K.28.7's
  // to this channel will likely cause frame misalignment.

  assign comma_code_rdn = (shift_reg_r[6:0] == 7'b1111100);    // Comma code detect (sender was RD-, now RD+)
  assign comma_code_rdp = (shift_reg_r[6:0] == 7'b0000011);    // Comma code detect (sender was RD+, now RD-)

  assign frame_align_o = (comma_code_rdn | comma_code_rdp);

  // Frame Counter
  //===============
  // Keeps track of where in the 10b frame we are. Resets when a comma code is
  // detected to realign the frame.

  bsg_counter_overflow_en #( .max_val_p(9), .init_val_p(0) )
    frame_counter
      ( .clk_i     ( clk_i )
      , .reset_i   ( frame_align_o )
      , .en_i      ( 1'b1 )
      , .count_o   ()
      , .overflow_o( frame_recv )
      );

  // 8b/10b Decoder
  //================
  // The 8b10b decoder has a running disparity (RD) which normally starts at
  // -1. However on boot, the RD register is unknown and there is no reset.
  // Therefore, we use the comma code to determine what our starting disparity
  // should be. If the comma code was a RD- encoding, then we set our disparity
  // to RD+ and vice-versa. This is because the allowed comma codes (K.28.1 and
  // K.28.5) will swap the running disparity.

  assign decode_rd_n = frame_align_o ? comma_code_rdn : (v_o ? decode_rd_lo : decode_rd_r);

  bsg_dff #(.width_p($bits(decode_rd_r)))
    decode_rd_reg
      ( .clk_i ( clk_i )
      , .data_i( decode_rd_n )
      , .data_o( decode_rd_r )
      );

  bsg_8b10b_decode_comb
    decode_8b10b
      ( .data_i    ( shift_reg_r )
      , .rd_i      ( decode_rd_r )
      , .data_o    ( data_o )
      , .k_o       ( k_o )
      , .rd_o      ( decode_rd_lo )
      , .data_err_o( decode_data_err_lo )
      , .rd_err_o  ( decode_rd_err_lo )
      );

  assign v_o = frame_recv & ~(decode_data_err_lo | decode_rd_err_lo);

  // Error Detection
  //=================
  // Display an error if we ever see a K.28.7 code. This code is not allowed
  // with the given comma code detection logic.

  // synopsys translate_off
  always_ff @(negedge clk_i)
    begin
      assert (shift_reg_r !== 10'b0001_111100 && shift_reg_r !== 10'b1110_000011) else
        $display("## ERROR (%M) - K.28.7 Code Detected!");
    end
  // synopsys translate_on

endmodule

