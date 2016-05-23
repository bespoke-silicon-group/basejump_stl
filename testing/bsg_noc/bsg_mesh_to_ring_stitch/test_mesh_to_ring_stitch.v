// this test was yanked from another file and may require
// a few syntax error fixes.
//

module test_mesh_to_ring_stitch;

   import bsg_noc_pkg   ::*; // {P=0, W, E, N, S}

   localparam num_tiles_x_lp = 8;
   localparam num_tiles_y_lp = 8;
   
   localparam cycle_time_lp   = 20;

  // clock and reset generation
  wire clk;
  wire reset;

  bsg_nonsynth_clock_gen #( .cycle_time_p(cycle_time_lp)
                          ) clock_gen
                          ( .o(clk)
                          );

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(10)
                          )  reset_gen
                          (  .clk_i        (clk)
                           , .async_reset_o(reset)
                          );

   localparam b_lp = 1;
   localparam f_lp = 1;
   localparam x_lp = (num_tiles_x_lp);
   localparam y_lp = (num_tiles_y_lp);

   logic [x_lp-1:0][y_lp-1:0][$clog2(x_lp*y_lp)-1:0] ids;
   logic [x_lp-1:0][y_lp-1:0][b_lp-1:0] back_in, back_out;
   logic [x_lp-1:0][y_lp-1:0][f_lp-1:0] fwd_in, fwd_out;

   bsg_mesh_to_ring_stitch #(.y_max_p(y_lp)
                             ,.x_max_p(x_lp)
                             ,.width_back_p(b_lp)
                             ,.width_fwd_p(f_lp)
                             ) m2r
     (.id_o            (ids     )
      ,.back_data_in_o (back_in )
      ,.back_data_out_i(back_out)
      ,.fwd_data_in_o  (fwd_in  )
      ,.fwd_data_out_i (fwd_out )
      );

   always @(posedge clk)
     begin
        if (reset)
          begin
             back_out <= $bits(back_in) ' (1);
             fwd_out <= $bits(fwd_in) ' (1);
          end
          else
            begin
               back_out <= back_in;
               fwd_out <= fwd_in;
            end
     end
   integer xx,yy;

   always @(negedge clk)
     begin
        for (yy = 0; yy < y_lp; yy=yy+1)
          begin
             for (xx = 0; xx < x_lp; xx=xx+1)
               $write("%b", fwd_in[xx][yy]);
	     $write(" ");
             for (xx = 0; xx < x_lp; xx=xx+1)
               $write("%b", back_in[xx][yy]);
             $write("\n");
          end
	$write("\n");
     end
endmodule
