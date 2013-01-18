module config_node
  #(parameter             // node specific parameters 
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    default_p = -1        // default/reset value of configurable register associated with this node
   )
   (input clk_i,
    input bit_i,
    
    output [data_bits_p - 1 : 0] data_o,
    output bit_o
   );

  // local parameters same for all nodes in the configuration chain
  localparam id_width_lp        = 8;    // number of bits to represent the ID of a node, should be able to keep the max ID in the whole chain
  localparam len_width_lp       = 8;    // number of bits to represent #bits in the configuration packet, excluding the valid bit

  localparam frame_bit_size_lp  = 1;    // 
  localparam data_frame_len_lp  = 8;    // bit '0' is inserted every data_frame_len_lp in data bits
  localparam data_packet_len_lp = (data_bits_p + (data_bits_p / data_frame_len_lp) + frame_bit_size_lp);
                                        // + frame_bit_size_lp means the end, or msb of a data_packet is always framing bits
                                        // if data_bits_p is a multiple of data_frame_len_lp, "00" is expected at the end of a packet

  localparam shift_width_lp     =  (data_packet_len_lp + frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp); // shift register width of this node

  logic [shift_width_lp - 1 : 0] shift_n, shift_r;
  logic [id_width_lp - 1 : 0]    node_id;
  logic                          reset;
  logic                          valid;
  logic                          match;
  logic                          data_en;

  logic [len_width_lp - 1 : 0] packet_len;
  logic [len_width_lp - 1 : 0] count_n, count_r;
  logic                        count_non_zero;

  logic [data_packet_len_lp - 1 : 0] data_packet;
  logic [data_bits_p - 1 : 0] data_n, data_r;


  assign count_n = (valid) ? packet_len : ((count_non_zero) ? (count_r - 1) : count_r);
  assign shift_n = {bit_i, shift_r[shift_width_lp - 1 : 1]};

  always_ff @ (posedge clk_i) begin
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


  assign reset = & shift_r[frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp - 1 : 0];
  assign valid = (~count_non_zero) ? (~shift_r[0]) : 1'b0;
  assign packet_len = shift_r[len_width_lp + frame_bit_size_lp - 1 : frame_bit_size_lp];
  assign node_id = shift_r[id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp - 1 : frame_bit_size_lp + len_width_lp + frame_bit_size_lp];
  assign data_packet = shift_r[shift_width_lp - 1 : frame_bit_size_lp + id_width_lp + frame_bit_size_lp + len_width_lp + frame_bit_size_lp];

  genvar i;
  generate
    for(i = 0; i < data_packet_len_lp - frame_bit_size_lp; i++) begin // the end, or msb of a data_packet is always '0' which is discarded
      if((i + 1) % (data_frame_len_lp + frame_bit_size_lp)) begin
        assign data_n[i - i / (data_frame_len_lp + frame_bit_size_lp)] = data_packet[i];
      end
    end
  endgenerate

  assign match = node_id == id_p;
  assign data_en = valid & match;
  assign count_non_zero = | count_r;

  assign data_o = data_r;
  assign bit_o = shift_r[0];

//synopsys translate_off
  initial begin
    $display("\t\tshift_width_lp = %d\n", shift_width_lp);
    $display("\t\t\t\ttime, \tclk_i, \tbit_i, \tshift_r, \treset, \tvalid, \tpacket_len, \tnode_id, \tdata_n, \tmatch, \tdata_en, \tdata_r, \tcount_r");
    $monitor("%d,   \t %b, \t  %b, \t  %b,  \t  %b, \t  %b, \t  %b, \t  %d,     \t  %d,  \t %b, \t %b,   \t  %b, \t  %b, \t   %d",
             $time, clk_i, bit_i,  shift_r, bit_o,  reset,  valid,  packet_len, node_id, match, data_en, data_n, data_r, count_r);
  end
//synopsys translate_on
endmodule
