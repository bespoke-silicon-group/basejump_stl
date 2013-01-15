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

  wire [`shift_width_c - 1 : 0] shift_d; //==> config_d might need to be renamed
  reg  [`shift_width_c - 1 : 0] shift_r;

  wire [config_bits_p - 1 : 0] config_d; //==> config_d might need to be renamed
  reg  [config_bits_p - 1 : 0] config_r;
  wire [config_bits_p - 1 : 0] config_rp;

  always @ (reset) begin //change to posedge clk_i for sync reset
    if (reset == 1) begin
      config_r <= 0;
    end
  end

  assign config_d = config_r + 1;
  assign shift_d = {bit_i, shift_r[`shift_width_c - 1 : 1]};
  always @ (posedge clk_i) begin
    if (enable == 1) begin
      config_r <= config_d;
    end
    shift_r <= shift_d;
  end

  assign config_rp = config_r + 1;

  assign clk_o = clk_i;
  assign config_o = config_r;

  initial begin
    $display("\t\tCurrent Value of shift_width_c = %d\n", `shift_width_c);
    $display("\t\ttime, \tclk_i, \treset, \tenable, \tbit_i, \tshift_r,\tconfig_r, \tconfig_rp");
    $monitor("%d, \t %b, \t  %b, \t   %b, \t\t  %b \t  %b \t\t  %d \t\t   %d", $time, clk_i, reset, enable, bit_i, shift_r, config_r, config_rp);
  end
endmodule
