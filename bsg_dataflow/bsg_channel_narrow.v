// This module takes output of a previous module and sends this
// data in smaller number of bits by receiving deque from next
// module. When it is sending the last piece it would assert
// the deque to previous module.
//
// In case of input_width not being multiple of output_width,
// it would be padded by zeros in MSB. Moreover, by
// lsb_to_msb_p parameter the order of spiliting would be
// determined. By default it would start sending from LSB.
//
// In case of input_width being smaller than or equal to
// output_width, it would add the padding if necessary and
// forward the deque signal

`include "bsg_defines.v"

module bsg_channel_narrow #( parameter width_in_p   = -1
                           , parameter width_out_p  = -1
                           , parameter lsb_to_msb_p = 1
                           )
            ( input                          clk_i
            , input                          reset_i

            , input  [width_in_p-1:0]        data_i
            , output logic                   deque_o

            , output logic [width_out_p-1:0] data_o
            , input                          deque_i

            );

  // Calculating parameters
  localparam divisions_lp =  (width_in_p % width_out_p == 0)
                          ?  width_in_p / width_out_p
                          : (width_in_p / width_out_p) + 1;

  localparam padding_p    = width_in_p % width_out_p;

  //synopsys translate_off
   initial
    assert (width_in_p % width_out_p == 0)
      else $display ("zero is padded to the left (in=%d) vs (out=%d)", width_in_p, width_out_p);
  //synopsys translate_on

  logic [width_out_p - 1: 0] data [divisions_lp - 1: 0];
  // in case of 2 divisions, it would be only 1 bit counter
  logic [`BSG_SAFE_CLOG2(divisions_lp) - 1: 0] count_r, count_n;
  genvar i;

  // generating ranges for data, and padding if required
  generate
    // in case of input being smaller than or equal to output
    // there would be only one data which may require padding
    if (divisions_lp == 1) begin: gen_blk_0
      assign data[0] = {{padding_p{1'b0}},data_i};

    // Range selection based on lsb_to_msb_p and if required, padding
    end else if (lsb_to_msb_p) begin: gen_blk_0
      for (i = 0; i < divisions_lp - 1; i = i + 1) begin: gen_block
        assign data[i] = data_i[width_out_p * i + width_out_p - 1:
                                width_out_p * i];
      end
      assign data[divisions_lp - 1] =
          {{padding_p {1'b0}},
          data_i[width_in_p - 1: width_out_p * (divisions_lp - 1)]};

    end else begin: gen_blk_0

      for (i = 0; i < divisions_lp - 1; i = i + 1) begin: gen_block
        assign data[divisions_lp-1-i] =
                         data_i[width_out_p * i + width_out_p - 1:
                                width_out_p * i];
      end
      assign data[0] =
          {{padding_p {1'b0}},
          data_i[width_in_p - 1: width_out_p * (divisions_lp - 1)]};
    end
  endgenerate

  if (divisions_lp != 1) begin: gen_blk_1
    // counter for selecting which part to send
    always_comb begin
      count_n = count_r + deque_i;
      if (count_n == divisions_lp)
        count_n = 0;
    end

    always_ff @(posedge clk_i)
      if (reset_i)
        count_r <= 0;
      else
        count_r <= count_n;

    // multiplexer for output data
    assign data_o = data[count_r];

    // After all data is read, same cycle as last deque the output
    // deque is asserted
    // count_n cannot be used since it could be at 0 and no deque_i
    assign deque_o = deque_i & (count_r == $unsigned(divisions_lp - 1));

  // in case of input being smaller than or equal to output,
  // this module would be just forwarding the signals
  end else begin: gen_blk_1
    assign data_o  = data[0];
    assign deque_o = deque_i;
  end

endmodule
