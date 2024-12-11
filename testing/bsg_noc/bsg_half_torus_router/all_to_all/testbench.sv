`include "bsg_defines.sv"

module testbench();

  import test_pkg::*;
  import bsg_noc_pkg::*;

  bit clk, reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(10)
  ) cg0 (.o(clk));


  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(4)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  localparam num_tiles_x_p    = 8;
  localparam num_tiles_y_p    = 8;
  localparam XY_order_p       = 1;
  localparam base_x_cord_p    = 0;
  localparam base_y_cord_p    = 0;
  localparam num_vc_p         = 2;
  localparam x_cord_width_lp  = `BSG_SAFE_CLOG2(num_tiles_x_p);
  localparam y_cord_width_lp  = `BSG_SAFE_CLOG2(num_tiles_y_p);
  localparam data_width_p     = 32;

  // print out test config;
  initial begin
    $display("TEST CONFIGURATIONS:");
    $display("num_tiles_x_p = %d", num_tiles_x_p);
    $display("num_tiles_y_p = %d", num_tiles_y_p);
  end

  
  // Instantiate test tiles;
  `declare_test_link_sif_s(data_width_p,x_cord_width_lp,y_cord_width_lp,num_vc_p);
  test_vc_link_sif_s [num_tiles_y_p-1:0][num_tiles_x_p-1:0][E:W] hor_link_li, hor_link_lo;
  test_link_sif_s [num_tiles_y_p-1:0][num_tiles_x_p-1:0][S:N] ver_link_li, ver_link_lo;
  logic [num_tiles_y_p-1:0][num_tiles_x_p-1:0] done_lo;

  for (genvar y = 0; y < num_tiles_y_p; y++) begin: ty
    for (genvar x = 0; x < num_tiles_x_p; x++) begin: tx
      test_tile #(
        .x_cord_width_p(x_cord_width_lp)
        ,.y_cord_width_p(y_cord_width_lp)
        ,.num_tiles_x_p(num_tiles_x_p)
        ,.num_tiles_y_p(num_tiles_y_p)
        ,.base_x_cord_p(base_x_cord_p)
        ,.base_y_cord_p(base_y_cord_p)
        ,.data_width_p(data_width_p)
        ,.num_vc_p(num_vc_p)
        ,.XY_order_p(XY_order_p)
      ) tile0 (
        .clk_i(clk)
        ,.reset_i(reset)

        ,.hor_link_i(hor_link_li[y][x])
        ,.hor_link_o(hor_link_lo[y][x])
        ,.ver_link_i(ver_link_li[y][x])
        ,.ver_link_o(ver_link_lo[y][x])

        ,.my_x_i(x_cord_width_lp'(x+base_x_cord_p))
        ,.my_y_i(y_cord_width_lp'(y+base_y_cord_p))

        ,.done_o(done_lo[y][x])
      );
    end
  end
  

  // Connect tiles;
  for (genvar y = 0; y < num_tiles_y_p; y++) begin
    for (genvar x = 0; x < num_tiles_x_p; x++) begin
      // west;
      if (x == 0) begin
        assign hor_link_li[y][x][W] = hor_link_lo[y][x+1][W];
      end
      else if (x == 1) begin
        assign hor_link_li[y][x][W] = hor_link_lo[y][x-1][W];
      end
      else begin
        assign hor_link_li[y][x][W] = hor_link_lo[y][x-2][E];
      end

      // east;
      if (x == num_tiles_x_p-1) begin
        assign hor_link_li[y][x][E] = hor_link_lo[y][x-1][E];
      end
      else if (x == num_tiles_x_p-2) begin
        assign hor_link_li[y][x][E] = hor_link_lo[y][x+1][E];
      end
      else begin
        assign hor_link_li[y][x][E] = hor_link_lo[y][x+2][W];
      end

      // north;
      if (y == 0) begin
        assign ver_link_li[y][x][N] = '0;
      end
      else begin
        assign ver_link_li[y][x][N] = ver_link_lo[y-1][x][S];
      end

      // south;
      if (y == num_tiles_y_p-1) begin
        assign ver_link_li[y][x][S] = '0;
      end
      else begin
        assign ver_link_li[y][x][S] = ver_link_lo[y+1][x][N];
      end
    end
  end



  // Wait for Done;
  initial begin
    wait(&done_lo);
    $display("[BSG_FINISH] test successful.");
    $finish;
  end


endmodule
