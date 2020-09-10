`include "bsg_defines.v"

`ifndef CONFIG_DEFS_V
`include config_defs.v
`endif
// This task generates packet for config node and sends it
// bit by bit to the output on each negative clock edge
// In case of sending a reset packet, is_reset_cmd gets 1 and 
// rest of inputs are not used (set to zero by default)

task send_config_tag ( const ref clk
                     , input is_reset_cmd
                     , ref logic out
                     
                     , input [data_max_bits_lp - 1:0] data = 0
                     , input [id_width_lp -1:0] id = 0
                     , integer data_len = 0
                     );

  localparam max_message_size_lp = 
                  data_max_bits_lp + id_width_lp + 
                  len_width_lp + valid_bit_size_lp +
                  ((data_max_bits_lp/data_frame_len_lp)+4)*frame_bit_size_lp;

  automatic logic [frame_bit_size_lp-1:0] fb;
  automatic logic [max_message_size_lp:0] message;
  automatic logic [valid_bit_size_lp-1:0] valid;
  automatic logic [data_max_bits_lp - 1:0] data_t;

  integer full_length;
  integer dlen;
  integer ii;
  integer sh_amount;

  // framing and valid values
  fb = 0;
  valid = 2'b10;

  // initializing values
  dlen = data_len;
  data_t = data;
  sh_amount = 0;
  full_length = data_len + id_width_lp + 
                len_width_lp + valid_bit_size_lp +
                ((data_len/data_frame_len_lp)+4)*frame_bit_size_lp;

  // checking if its a reset message
  if (!is_reset_cmd) begin
    // in case of not being reset packet size must be different than zero
    // it could be problemtaic use, that user did not send values and
    // default values are used
    if (data_len == 0)
      $display("\nmessage length is zero!\n");

    // a normal packet
    else begin
      // frame bit before framed data, since it is zero it does not require
      // shift
      message = fb; 
      
      // generate framed data and add to message
      while (dlen >= data_frame_len_lp) begin
        message = message + ({fb,data_t[data_frame_len_lp-1:0]}<<sh_amount);
        sh_amount = sh_amount + data_frame_len_lp+frame_bit_size_lp; 
        dlen = dlen - data_frame_len_lp;
        data_t = data_t >> data_frame_len_lp;
      end
      
      // message was not multiple of data_frame_len, so last part does not
      // require frame bit
      if (dlen!=0)
        message = message + (data_t<<sh_amount);
      
      // frame bit and node id
      message = (message <<frame_bit_size_lp) + fb;
      message = (message <<id_width_lp) + id;
      
      // frame bit and packet length
      message = (message <<frame_bit_size_lp) + fb;
      message = (message <<len_width_lp) + full_length;
      
      // frame bit and valid
      message = (message <<frame_bit_size_lp) + fb;
      message = (message <<valid_bit_size_lp) + valid;

      // sending the packet cycle by cycle on negative edge of clk
      $display ("==========> message to be sent: %h (%d bits)", message,full_length);
      for (ii =0; ii< full_length; ii=ii+1) begin
        @(negedge clk)
        out = message[0];
        message = message >>1;
      end
      // message transmission finished
      $display ("message to %d sent<========\n", id);
    end
  // reset packet
  end else begin
    // made it two time reset_len_lp to be sure it was received
    for (ii =0; ii< reset_len_lp*2; ii=ii+1) begin
      @(negedge clk)
      out = 1'b1;
    end
    $display("\nconfig tag reset message sent\n");
    // reset packet is finished, so the line is lowered
    @(negedge clk)
    out = 1'b0;
  end

endtask
