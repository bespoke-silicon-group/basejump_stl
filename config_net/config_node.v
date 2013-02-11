module config_node
  #(parameter             // node specific parameters 
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    default_p = -1        // default/reset value of configurable register associated with this node
   )
   (input config_s config_i,
    
    output [data_bits_p - 1 : 0] data_o
   );

  /* ========================================================================== *
   * WARNING: Please do not modify the following hard-coded localparams unless
   *          you are clear about the possible consequences.
   *    
   *   frame_bit_size_lp is set to 1 and the current framing bit is defined as
   *   a single '0'.
   *
   *   data_frame_len_lp has to be less than the reset_len_lp, so that when
   *   bits are shifted in, the content of a data frame never gets interpreted
   *   as a reset sequence.
   *
   *   Since id bits and len bits are not framed in this implementation,
   *   id_width_lp and len_width_lp also should be less than reset_len_lp.
   * ========================================================================== */
  // local parameters same for all nodes in the configuration chain
  localparam frame_bit_size_lp  =  1;
  localparam data_frame_len_lp  =  8;  // bit '0' is inserted every data_frame_len_lp in data bits
  localparam id_width_lp        =  8;  // number of bits to represent the ID of a node, should be able to keep the max ID in the whole chain
  localparam len_width_lp       =  8;  // number of bits to represent number of bits in the configuration packet
  localparam reset_len_lp       = 10;  // reset sequence length


  localparam data_rx_len_lp     = (data_bits_p + (data_bits_p / data_frame_len_lp) + frame_bit_size_lp);
                                      // + frame_bit_size_lp means the end, or msb of received data is always framing bits
                                      // if data_bits_p is a multiple of data_frame_len_lp, "00" is expected at the end of received data

  localparam shift_width_lp     = (data_rx_len_lp + frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp);
                                      // shift register width of this node

  /* The communication packet is defined as follows:
   * msb                                                                                 lsb
   * |  data_rx  |  frame bits  |  node id  |  frame bits  |  packet length  |  valid bit  |
   *                                        |<------------------ reset ------------------->|
   *
   * valid bit is defined as '0'.
   * packet length equals the number of bits in one complete packet, i.e. msb - lsb + 1.
   * frame bits are certain patterns to separate packet content, defined as '0'.
   * node id is an unique integer to identify current node.
   * data_rx contains the data payload and framing bits inserted every data_frame_len_lp bits.
   *
   * Before use, reset the configuration node is mandatory by sending continuous '1's, and the
   * minimum length of the reset sequence is (frame_bit_size_lp * 2 + len_width_lp), or the
   * indicated field above.
   *
   * Each node contains a shift register that represents the same structure of a complete packet,
   * and the node begins interpret received packet once it sees a '0' in the lsb of the shift
   * register. The node determines if it is the target according to the node id bits. If so, the 
   * node captures received data, remove framing bits and write the data to its internal register.
   * Otherwise, the node simply passes every bit to its subsequent node.
   */

  typedef struct packed {
    logic [data_rx_len_lp - 1 : 0]       rx; // data_rx
    logic                                f1; // frame bit 1
    logic [id_width_lp - 1 : 0]          id; // node id
    logic [frame_bit_size_lp - 1 : 0]    f0; // frame bit 0
    logic [len_width_lp - 1 : 0]        len; // packet length
    logic                             valid; // valid bit
  } node_packet_s;

  node_packet_s shift_n, shift_r; // shift register
  logic [id_width_lp - 1 : 0]    node_id;
  logic                          reset;
  logic                          valid; // begin of packet signal
  logic                          match; // node id match signal
  logic                          data_en; // data_r write enable

  logic [len_width_lp - 1 : 0] packet_len;
  logic [len_width_lp - 1 : 0] count_n, count_r; // bypass counter
  logic                        count_non_zero; // bypass counter is zero signal

  logic [data_rx_len_lp - 1 : 0] data_rx;
  logic [data_bits_p - 1 : 0] data_n, data_r; // data payload register

  assign count_n = (valid) ? (packet_len - 1) : ((count_non_zero) ? (count_r - 1) : count_r);
         // Load packet length to counter at the beginning of a packet, and
         // decrease its value while it's non-zero. The node does not care
         // about content in its shift register when the counter is not zero.

  assign shift_n = {config_i.cfg_bit, shift_r[1 +: shift_width_lp - 1]};

  always_ff @ (posedge config_i.cfg_clk) begin
    if (reset) begin
      count_r <= 0;
      data_r <= default_p;
    end else begin
      count_r <= count_n;
      if (data_en)
        data_r <= data_n;
    end

    shift_r <= shift_n;
  end

  assign reset = & shift_r[0 +: reset_len_lp]; // reset sequence is an all '1' string of reset_len_lp length
  assign valid = (~count_non_zero) ? (~shift_r.valid) : 1'b0; // shift_r.valid == '0' means valid
  assign packet_len = shift_r.len;
  assign node_id    = shift_r.id;
  assign data_rx    = shift_r.rx;

  // This generate block is to remove framing bits and wire only data payload
  // bits to the config data register of this node.
  genvar i;
  generate
    for(i = 0; i < data_rx_len_lp - frame_bit_size_lp; i++) begin // the end, or msb of a transferred data is always '0' which is discarded
      if((i + 1) % (data_frame_len_lp + frame_bit_size_lp)) begin // bit is payload when % returns non-zero
        assign data_n[i - i / (data_frame_len_lp + frame_bit_size_lp)] = data_rx[i];
      end
    end
  endgenerate

  assign match = node_id == id_p;
  assign data_en = valid & match;
  assign count_non_zero = | count_r;

  // Output signals
  assign data_o = data_r;

endmodule
