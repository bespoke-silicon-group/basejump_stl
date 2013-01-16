module config_node
  #(parameter
    // Parameters must have same value for all nodes ==> to be local
    id_width_p = -1,      // Number of bits to represent the ID of a node, should be able to keep the max ID in the whole chain
    len_width_p = -1,     // Number of bits to represent #bits in the configuration packet, excluding the valid bit
     // node specific parameters 
    id_p = -1,            // Unique ID of this node
    data_bits_p = -1,     // Number of bits of configurable register associated with this node
    default_p = -1        // Default/Reset value of configurable register associated with this node
   )

   (input clk_i,
    input bit_i,
    
    output [data_bits_p - 1 : 0] data_o,
    output clk_o,
    output bit_o
   );


  `define shift_width_c (data_bits_p + id_width_p + len_width_p + 1) //==> config-> data info->len


  wire [`shift_width_c - 1 : 0] shift_n;
  reg  [`shift_width_c - 1 : 0] shift_r;
  wire [id_width_p - 1 : 0]     node_id;
  wire                          reset;

  wire                          valid;
  wire                          match;
  wire                          data_en;

  wire [len_width_p - 1 : 0] packet_len;
  wire [len_width_p - 1 : 0] count_n;
  reg  [len_width_p - 1 : 0] count_r;
  wire                       count_ld;
  wire                       count_non_zero;

  wire [data_bits_p - 1 : 0] data_n;
  reg  [data_bits_p - 1 : 0] data_r;


  always @ (reset) begin // async reset
    if (reset == 1) begin
      count_r <= 0;
      data_r <= default_p;
    end
  end


  assign count_n = (count_ld == 1) ? packet_len : ((count_non_zero == 1) ? (count_r - 1) : count_r);
  assign shift_n = {bit_i, shift_r[`shift_width_c - 1 : 1]};

  always @ (posedge clk_i) begin
    count_r <= count_n;
    data_r <= data_n;
    shift_r <= shift_n;
  end


  assign reset = & shift_r;
  assign valid = (count_non_zero == 0) ? (~shift_r[0]) : 1'b0;
  assign packet_len = shift_r[len_width_p + 1 - 1 : 1];
  assign node_id = shift_r[id_width_p + len_width_p + 1 - 1 : len_width_p + 1];
  assign data_n = (data_en == 1) ? shift_r[data_bits_p + id_width_p + len_width_p + 1 - 1 : id_width_p + len_width_p + 1] : data_r;

  assign match = (node_id == id_p) ? 1'b1 : 1'b0;
  assign data_en = valid & match;
  assign count_ld =  valid & (~match);
  assign count_non_zero = | count_r;

  assign data_o = count_r;
  assign clk_o = clk_i;
  assign bit_o = shift_r[0];

//synopsys translate_off
  initial begin
    $display("\t\ttime, \tclk_i, \tbit_i, \tshift_r, \treset, \tvalid, \tpacket_len, \tnode_id, \tdata_n, \tmatch, \tdata_en, \tdata_r, \tcount_ld, \tcount_r");
    $monitor("%d,   \t %b, \t  %b, \t  %b,  \t  %b, \t  %b, \t  %b, \t  %d,     \t  %d,  \t %b, \t %b,   \t  %b, \t  %b, \t  %b,   \t   %d",
             $time, clk_i, bit_i,  shift_r, bit_o,  reset,  valid,  packet_len, node_id, match, data_en, data_n, data_r, count_ld, count_r);
  end
//synopsys translate_on
endmodule
