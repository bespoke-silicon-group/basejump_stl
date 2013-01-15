module config_node
  #(parameter
    // Parameters must have same value for all nodes
    id_width_p = -1,      // Data bits to represent the max ID in the whole chain
    info_width_p = -1,    // Data bits to represent flow control information
     // Parameters node specific
    id_p = -1,            // Unique ID of this node
    config_bits_p = -1,   // Data bits of configurable register associated with this node
    default_p = -1        // Default/Reset value of configurable register associated with this node
   )

   (// Pins connected to IO pads
    input clk_i,
    input reset, //==> to go
    input enable, //==> to go
    input bit_i,
    
    output [config_bits_p - 1 : 0] config_o,
    output clk_o
   );

  `define shift_width_c (config_bits_p + id_width_p + info_width_p + 1)

  wire [`shift_width_c - 1 : 0] shift_d; //==> shift_d might need to be renamed
  reg  [`shift_width_c - 1 : 0] shift_r;
  wire [id_width_p - 1 : 0] config_id;
  wire                      valid;
  wire                      reset_n;

  wire [info_width_p - 1 : 0] config_len;
  wire [info_width_p - 1 : 0] count_d; //==> count_d might need to be renamed
  reg  [info_width_p - 1 : 0] count_r;
  wire [info_width_p - 1 : 0] count_rp;

  wire [config_bits_p - 1 : 0] config_d; //==> config_d might need to be renamed
  reg  [config_bits_p - 1 : 0] config_r;

  always @ (~reset_n) begin //sync reset_n
    if (reset_n == 1) begin
      count_r <= 0;
      config_r <= 0;
    end
  end

  assign count_d = count_r + 1;
  assign shift_d = {bit_i, shift_r[`shift_width_c - 1 : 1]};
  always @ (posedge clk_i) begin
    if (enable == 1) begin
      count_r <= count_d;
    end
    shift_r <= shift_d;
  end

  assign reset_n = & shift_r;
  assign valid = shift_r[0];
  assign config_len = shift_r[info_width_p + 1 - 1 : 1];
  assign config_id = shift_r[id_width_p + info_width_p + 1 - 1 : info_width_p + 1];
  assign config_d = shift_r[config_bits_p + id_width_p + info_width_p + 1 - 1 : id_width_p + info_width_p + 1];

  assign count_rp = count_r + 1;

  assign clk_o = clk_i;
  assign config_o = count_r;

  initial begin
    $display("\t\tCurrent Value of shift_width_c = %d\n", `shift_width_c);
    $display("\t\ttime, \tclk_i, \treset, \tenable, \tbit_i, \tshift_r, \treset_n, \tvalid, \tconfig_len, \tconfig_id, \tconfig_d, \tconfig_r, \tcount_r, \tcount_rp");
    $monitor("%d, \t %b, \t  %b, \t   %b, \t\t  %b, \t  %b, \t  %b, \t  %b, \t  %d, \t  %d, \t  %b, \t  %b, \t  %d, \t   %d",
             $time, clk_i, reset, enable,    bit_i, shift_r, reset_n, valid, config_len, config_id, config_d, config_r, count_r, count_rp);
  end
endmodule
