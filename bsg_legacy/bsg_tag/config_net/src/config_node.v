`include "bsg_defines.v"

`include "config_defs.v"

// fixme: label all signals with clock prefix, and use bsg_ip_cores macros to hardplace CDC regions
// and rNandMeta

module config_node
  #(parameter             // node specific parameters
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    default_p = -1        // default/reset value of configurable register associated with this node
   )
   (
    // this includes the config clock and a single config data line
    input config_s config_i, // from IO pads

    // all of these signals are relative to the destination clock domain
    input clk, // destination side clock from pins
    input reset, // destination side reset from pins

    // whether data_o is new
    output logic data_new_r_o,
    output [data_bits_p - 1 : 0] data_r_o
   );

   localparam debug_lp = 0;

  localparam data_rx_len_lp     = (data_bits_p + (data_bits_p / data_frame_len_lp) + frame_bit_size_lp);
                                      // + frame_bit_size_lp means the end, or msb of received data is always framing bits
                                      // if data_bits_p is a multiple of data_frame_len_lp, "00" is expected at the end of received data

  localparam shift_width_lp     = (data_rx_len_lp + frame_bit_size_lp +
                                   id_width_lp + frame_bit_size_lp +
                                   len_width_lp + frame_bit_size_lp +
                                   valid_bit_size_lp);
                                  // shift register width of this node


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
  logic                       ready_n, ready_r; // data_r ready and corresponding registers for clock domain crossing
                                                // no combinational logic between ready_r and its destination side receiver,
                                                // to reduce the change to go metastable
  logic                       ready_synced;     // ready signal which is passed through the bsg_launch_sync_sync to
                                                // cross clock domains

  logic [len_width_lp - 1 : 0] packet_len;
  logic [$bits(integer) - 1 : 0] count_n_int; // to avoid type casting warnings from Lint
  logic [len_width_lp - 1 : 0] count_n, count_r; // bypass counter
  logic                        count_non_zero; // bypass counter is zero signal


  logic [data_rx_len_lp - 1 : 0] data_rx;
  logic [data_bits_p - 1 : 0] data_n, data_r; // data payload register

  logic [1 : 0] sync_shift_n, sync_shift_r;   // edge detection registers


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
  logic                       r_e_s_e_t_r; // registered reset, to be used with reset input to detect posedge of reset
  logic                       default_en; // derived reset-to-default in destination clock domain

  logic                       data_dst_en; // data_dst_r write enable
  logic [data_bits_p - 1 : 0] data_dst_n, data_dst_r; // destination side data payload register

  assign count_n_int = (valid) ? (packet_len - 1) : ((count_non_zero) ? (count_r - 1) : count_r);
  assign count_n = count_n_int[0 +: len_width_lp];
         // Load packet length to counter at the beginning of a packet, and
         // decrease its value while it's non-zero. The node does not care
         // about content in its shift register when the counter is not zero.

  assign shift_n = {config_i.cfg_bit, shift_r[1 +: shift_width_lp - 1]};


  // synopsys translate_off

   // non-synthesizeable helper message
  always @(negedge config_i.cfg_clk)
    begin
       if (cfg_reset)
         $display("## I: CONFIG NODE (id=%-d,default=%-d'b%-b,packet_size=%-d) received reset packet (%m)",id_p,data_bits_p,default_p,$bits(node_packet_s));
    end

  // synopsys translate_on

   // we break up the config register into three parts because it is too tall

   // receive register for config net's data portion
   // this is separated out so because it aligns with the data synchronization registers
   bsg_dff_gatestack #(.width_p(data_rx_len_lp)
                       ,.harden_p(1)
                       ) shift_reg_data
     (
      .i0 (shift_n.rx)        // D
      ,.i1({ data_rx_len_lp {config_i.cfg_clk}})  // CLK
      ,.o (shift_r.rx)        // Q
      );

   // receive register for config net's len portion
   // this is separated out so because it aligns with the data synchronization registers
   bsg_dff_gatestack #(.width_p(len_width_lp)
                       ,.harden_p(1)
                       ) shift_reg_len
     (
      .i0 (shift_n.len     )
      ,.i1({ len_width_lp  {config_i.cfg_clk}})
      ,.o (shift_r.len)
      );

   bsg_dff_gatestack #(.width_p(id_width_lp)
                       ,.harden_p(1)
                       ) shift_reg_id
     (
      .i0 (shift_n.id     )
      ,.i1({ id_width_lp  {config_i.cfg_clk}})
      ,.o (shift_r.id)
      );

   initial assert (data_rx_len_lp+1+id_width_lp+frame_bit_size_lp+len_width_lp+frame_bit_size_lp+valid_bit_size_lp == $bits(node_packet_s))
     else
       $error("%m likely missing component in config_node flops");

   localparam remainder_lp = $bits(node_packet_s)-id_width_lp-data_rx_len_lp-len_width_lp;

   // receive register for config net
   bsg_dff_gatestack #(.width_p(remainder_lp)
             ,.harden_p(1)
             ) shift_reg_remain
     (
      .i0 ({shift_n.f2, shift_n.f1, shift_n.f0, shift_n.valid})
      ,.i1({ remainder_lp {config_i.cfg_clk}})
      ,.o ({shift_r.f2, shift_r.f1, shift_r.f0, shift_r.valid})
      );

   bsg_dff_reset #(.width_p(len_width_lp)
                   ,.harden_p(1)
                   ) count_reg
     (.clk_i(config_i.cfg_clk)
      ,.data_i(count_n)
      ,.data_o(count_r)
      ,.reset_i(cfg_reset)
      );

  always_ff @ (posedge config_i.cfg_clk) begin
    if (cfg_reset) begin
      ready_r <= 0;
    end else begin
      if (data_en) begin
        ready_r <= ready_n;
      end
    end
  end

  assign ready_n = ready_r ^ data_en; // xor, invert ready signal when data_en is 1

  assign default_en = reset & (~ r_e_s_e_t_r); // (reset == 1) & (r_e_s_e_t_r == 0)

  // This bsg_launch_sync_sync module is used to cross the clock domains for
  // the ready signal
  bsg_launch_sync_sync #( .width_p(1)
                                         , .use_negedge_for_launch_p(0)
                       ) synchronizer

    ( .iclk_i(config_i.cfg_clk)
    , .iclk_reset_i(1'b0)  // mbt: was incorrectly set to reset; which is wrong clock domain
    , .oclk_i(clk)
    , .iclk_data_i(ready_r ^ cfg_reset)
    , .iclk_data_o()
    , .oclk_data_o(ready_synced)
    );

   if (default_p==0)
     begin: def
        bsg_dff_reset_en #(.width_p(data_bits_p),.harden_p(1'b1))
        data_r_reg
          (.clk_i(config_i.cfg_clk)
           ,.reset_i(cfg_reset)
           ,.en_i(data_en)
           ,.data_i(data_n)
           ,.data_o(data_r)
           );

        bsg_dff_reset_en #(.width_p(data_bits_p),.harden_p(1'b1))
        data_dst_reg
          (.clk_i(clk)
           ,.data_i(data_r)
           ,.en_i(data_dst_en)
           ,.reset_i(default_en)
           ,.data_o(data_dst_r)
           );
     end
   else
     begin: def
        // source register for crossing clock domains
        bsg_dff_en #(.width_p(data_bits_p),.harden_p(1'b1))
        data_r_reg
          (.clock_i(config_i.cfg_clk)
           ,.en_i(cfg_reset | data_en)
           ,.data_i(cfg_reset ? default_p : data_n)
           ,.data_o(data_r)
           );

        bsg_mux #(.width_p(data_bits_p)
                  ,.harden_p(1)
                  ,.els_p(2)
                  ) data_dst_mux
          (
           .sel_i(default_en)
           ,.data_i( { data_bits_p '(default_p), data_r})
           ,.data_o(data_dst_n)
           );

        bsg_dff_en #(.width_p(data_bits_p)
                     ,.harden_p(1)
                     ) data_dst_reg
          (.clock_i(clk)
           ,.data_i(data_dst_n)
           ,.en_i(default_en | data_dst_en)
           ,.data_o(data_dst_r)
           );
     end

  // Register for edge detection
  assign sync_shift_n = {ready_synced, sync_shift_r[1]};

  always_ff @ (posedge clk) begin
    if (reset) begin
      r_e_s_e_t_r <= 1;
    end else begin
      r_e_s_e_t_r <= 0;
    end

    data_new_r_o <= data_dst_en | default_en;
    sync_shift_r <= sync_shift_n;
  end

   if (debug_lp)
   always @(negedge clk)
     begin
        if (default_en)
          $display("## I: CONFIG NODE (id=%-d) dest_clk setting default: %x (%m)",id_p, default_p);
        if (data_new_r_o)
          $display("## I: CONFIG NODE (id=%-d) dest_clk received data: %x (%m)",id_p, data_dst_r);
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
  assign data_r_o = data_dst_r; // data_dst_r is the inverted data_r

endmodule
