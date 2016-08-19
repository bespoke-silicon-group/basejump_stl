// This counter will counter down from val_i to 0. When the counter
// hits 0, the output clk_r_o will invert. The number of bits wide
// the counter is can be set with the width_p parameter.
//
module bsg_counter_clock_downsample #(parameter width_p = "inv")
    (input                clk_i
    ,input                reset_i
    ,input  [width_p-1:0] val_i
    ,output logic         clk_r_o
    );

logic [width_p-1:0] ctr_n, ctr_r;   // counter logic
logic               is_ctr_zero;    // set if the counter is 0

// Determine if the counter is 0
//
wire is_ctr_zero = ~(|ctr_r);

// Counter register
//
always_ff @(posedge clk_i)
  begin
    if (reset_i | is_ctr_zero)
      ctr_r <= val_i;
    else
      ctr_r <= ctr_r - 1'b1;
  end

// Clock output register
//
always_ff @(posedge clk_i)
  begin
    if (reset_i)
      clk_r_o <= 1'b0;
    else if (is_ctr_zero)
      clk_r_o <= ~clk_r_o;
  end

endmodule
