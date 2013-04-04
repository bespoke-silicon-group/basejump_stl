`include "config_s.v"

module config_node
  #(parameter             // node specific parameters
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    default_p = -1        // default/reset value of configurable register associated with this node
   )
   (input clk, // destination side clock from pins
    input reset, // destination side reset from pins
    input config_s config_i, // from IO pads

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
  localparam valid_bit_size_lp  =  2;
  localparam frame_bit_size_lp  =  1;
  localparam data_frame_len_lp  =  8;  // bit '0' is inserted every data_frame_len_lp in data bits
  localparam id_width_lp        =  8;  // number of bits to represent the ID of a node, should be able to keep the max ID in the whole chain
  localparam len_width_lp       =  8;  // number of bits to represent number of bits in the configuration packet
  localparam reset_len_lp       = 10;  // reset sequence length


  localparam data_rx_len_lp     = (data_bits_p + (data_bits_p / data_frame_len_lp) + frame_bit_size_lp);
                                      // + frame_bit_size_lp means the end, or msb of received data is always framing bits
                                      // if data_bits_p is a multiple of data_frame_len_lp, "00" is expected at the end of received data

  localparam shift_width_lp     = (data_rx_len_lp + frame_bit_size_lp +
                                   id_width_lp + frame_bit_size_lp +
                                   len_width_lp + frame_bit_size_lp +
                                   valid_bit_size_lp);
                                  // shift register width of this node

  localparam sync_len_lp        = 2;  // This has to be no less than 2 to provide reasonable MTBF

  localparam sync_shift_len_lp  = sync_len_lp + 2;  // + 2 is to integrate the two edge detecting flip-flops

  /* The communication packet is defined as follows:
   * msb                                                                                                  lsb
   * |  data_rx  |  frame bits  |  node id  |  frame bits  |  packet length  |   frame bits  |  valid bits  |
   *
   * valid bit is defined as "10".
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
    logic                                f2; // frame bit 2
    logic [id_width_lp - 1 : 0]          id; // node id
    logic [frame_bit_size_lp - 1 : 0]    f1; // frame bit 1
    logic [len_width_lp - 1 : 0]        len; // packet length
    logic [frame_bit_size_lp - 1 : 0]    f0; // frame bit 0
    logic [valid_bit_size_lp - 1 : 0] valid; // valid bits
  } node_packet_s;

  node_packet_s shift_n, shift_r; // shift register
  logic [id_width_lp - 1 : 0] node_id;
  logic                       cfg_reset; // configuration network reset signal
  logic                       valid; // begin of packet signal
  logic                       match; // node id match signal
  logic                       data_en; // data_r write enable
  logic                       ready_n, ready_r, ready_r2; // data_r ready and corresponding registers for clock domain crossing
                                                          // no combinational logic between ready_r2 and its destination side receiver,
                                                          // to reduce the change to go metastable

  logic [len_width_lp - 1 : 0] packet_len;
  logic [len_width_lp - 1 : 0] count_n, count_r; // bypass counter
  logic                        count_non_zero; // bypass counter is zero signal

  logic [data_rx_len_lp - 1 : 0] data_rx;
  logic [data_bits_p - 1 : 0] data_n, data_r; // data payload register

  logic [sync_shift_len_lp - 1 : 0] sync_shift_n, sync_shift_r; // clock domain crossing syncronization registers + edge detection registers

  // The following two signals are used to detect the reset posedge.
  // Suppose that apart from this configuration network the remaining part of
  // the chip resets on 1 of the reset_input, now if the configuration
  // registers are made to reset on posedge of the reset_input, it is possible
  // to configure those registers while the rest of chip is being reset,
  // reducing the chance for the chip to go metastable. The reset_input is
  // pulled down when it's safe to believe all configuration registers are
  // properly loaded and stable.
  // Here it is not necessary to reset configuration registers strictly on the
  // posedge of reset_input, therefore the following two signals are used to
  // detect a delayed posedge of reset_input.
  logic                       recovered; // registered reset, to be used with reset input to detect posedge of reset
  logic                       default_en; // derived reset-to-default in destination clock domain

  logic                       data_dst_en; // data_dst_r write enable
  logic [data_bits_p - 1 : 0] data_dst, data_dst_r; // destination side data payload register

  assign count_n = (valid) ? (packet_len - valid_bit_size_lp) : ((count_non_zero) ? (count_r - 1) : count_r);
         // Load packet length to counter at the beginning of a packet, and
         // decrease its value while it's non-zero. The node does not care
         // about content in its shift register when the counter is not zero.

  assign shift_n = {config_i.cfg_bit, shift_r[1 +: shift_width_lp - 1]};

  always_ff @ (posedge config_i.cfg_clk) begin
    if (cfg_reset) begin
      count_r <= 0;
      data_r <= default_p;
      ready_r <= 0;
      ready_r2 <= 0;
    end else begin
      count_r <= count_n;
      if (data_en) begin
        data_r <= data_n;
        ready_r <= ready_n;
      end
      ready_r2 <= ready_r;
    end

    shift_r <= shift_n;
  end

  assign ready_n = ready_r ^ data_en; // xor, invert ready signal when data_en is 1

  assign sync_shift_n = {ready_r, sync_shift_r[1 +: sync_shift_len_lp - 1]}; // clock domain crossing synchronization line

  assign default_en = reset & recovered; // (reset == 1) & (recovered == 1)

  // The NAND gate array is used as filters to clear cross clock domain data's
  // metastability when entering a new clock domain. Ths idea is based on the
  // assumption that a normal 4-transistor NAND gate (A, B -> A nand B) is
  // safe to block signal A when signal B is 0. When signal B is 1, its output
  // may hover when signal A is transitioning, and the unstable output may
  // violate the receiver register's setup time constraints.
  // In this config node context, signal data_r is from a different clock
  // domain than data_dst_en and data_dst.
  rNandMeta #(.width_p(data_bits_p))
    data_dst_filter (.data_a_i(data_r),
                     .data_b_i({data_bits_p {data_dst_en}}),
                     .nand_o(data_dst) );

  always_ff @ (posedge clk) begin
    if (reset) begin
      recovered <= 0;
    end else begin
      recovered <= 1;
    end

    if (default_en) begin
      data_dst_r <= ~default_p; // data_dst_r will be inverted in the end
    end else begin
      if (data_dst_en) data_dst_r <= data_dst; // data_dst is the inverted receiving data
    end

    sync_shift_r <= sync_shift_n;
  end

  // An inverted ready_r from config domain indicates a valid data_r word is ready to be captured.
  // If an edge occurs in ready_r, sooner or later the sync line detects it by having different bits in the least significant 2 positions.
  // This implementation depends on that the least significant 2 bits in sync line are *NOT* metastable. When they also go metastable,
  // the circuit may fail. Extend the length of sync_len_lp could increase mean time between failures.
  assign data_dst_en = sync_shift_r[0] ^ sync_shift_r[1];

  assign cfg_reset = & shift_r[0 +: reset_len_lp]; // reset sequence is an all '1' string of reset_len_lp length
  assign valid = (~count_non_zero) ? (shift_r.valid == 2'b10) : 1'b0; // shift_r.valid == "10" means a valid packet arrives
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
  assign data_o = ~data_dst_r; // data_dst_r is the inverted data_r

endmodule
