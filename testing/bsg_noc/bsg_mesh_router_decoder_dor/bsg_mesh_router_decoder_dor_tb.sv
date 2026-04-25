
module decoder_tb ();

    localparam x_cord_width_p   = 5; // Supports up to 32 columns
    localparam y_cord_width_p   = 5; // Supports up to 32 rows
    localparam dims_p           = 2;
    localparam XY_order_p       = 1;
    localparam ruche_factor_X_p = 0;
    localparam ruche_factor_Y_p = 0;
    localparam dirs_lp          = 5;

    logic mc_x, mc_y;
    logic [x_cord_width_p-1:0] x_dirs_i, my_x_i;
    logic [y_cord_width_p-1:0] y_dirs_i, my_y_i;
    logic [dirs_lp-1:0] req_o;

    bsg_mesh_router_decoder_dor_mc #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.ruche_factor_X_p(ruche_factor_X_p)
      ,.ruche_factor_Y_p(ruche_factor_Y_p)
      ,.dims_p(dims_p)
      ,.XY_order_p(XY_order_p)
      // if in_dirs_lp > out_dirs_lp, then for the purposes of dimension 
      // ordered routing only, we treat the extra directions as "P"			  
      ,.from_p(5'b00010) // One-hot bit for index W (1)
      ,.depopulated_p(0)
      ,.debug_p(0)
    ) dor_decoder (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.mc_x(mc_x)
      ,.mc_y(mc_y)
      ,.x_dirs_i(x_dirs_i)
      ,.y_dirs_i(y_dirs_i)
      ,.my_x_i(my_x_i)
      ,.my_y_i(my_y_i)

      ,.req_o(req_o)
    );

    initial begin
        clk_i = 0; reset_i = 1;
        mc_x = 0; mc_y = 0;
        my_x_i = 0; my_y_i = 0;  // my location is 0, 0
        x_dirs_i = 0; y_dirs_i = 0;   #10; 
        reset_i = 0;                        #10;

        // Standard Unicast to the East
        #10 x_dirs_i = 5; y_dirs_i = 0; mc_x = 0; mc_y = 0;
        #1 $display("Unicast East: req_o=%b (Expected: 00100)", req_o);

        // Multicast Range targeting East and Local (X-then-Y routing)
        #10 x_dirs_i = 10; y_dirs_i = 10; mc_x = 1; mc_y = 1;
        #1 $display("Multicast: req_o=%b (Expected: 10101)", req_o);

        // No multicasting in X direction, only Y direction (X-then-Y routing)
        #10 x_dirs_i = 10; y_dirs_i = 10; mc_x = 0; mc_y = 1;
        #1 $display("Multicast: req_o=%b (Expected: 10100)", req_o);

        // changing my location to 10,0 and keeping the same multicast request (X-then-Y routing)
        #10 my_x_i = 10; my_y_i = 0;
        // traverse downwards in Y direction, sending data to 10,1
        #10 x_dirs_i = 10; y_dirs_i = 10; mc_x = 0; mc_y = 1;
        #1 $display("Multicast: req_o=%b (Expected: 10101)", req_o);


        #10 $stop;
    end

endmodule