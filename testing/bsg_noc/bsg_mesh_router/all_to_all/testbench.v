
`include "bsg_defines.v"

module testbench();

  import test_pkg::*;
  import bsg_noc_pkg::*;
  import bsg_mesh_router_pkg::*;

  bit clk;
  bit reset;

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


  localparam num_tiles_x_p = `NUM_X;
  localparam num_tiles_y_p = `NUM_Y;
  localparam dims_p = `DIMS_P;
  localparam ruche_factor_X_p = `RUCHE_X;
  localparam ruche_factor_Y_p = `RUCHE_Y;
  localparam XY_order_p = `XY_ORDER;
  localparam dirs_lp = (dims_p*2)+1;
  localparam data_width_p = 32;
  localparam x_cord_width_lp = `BSG_SAFE_CLOG2(num_tiles_x_p);
  localparam y_cord_width_lp = `BSG_SAFE_CLOG2(num_tiles_y_p);



  `declare_test_link_sif_s(data_width_p,x_cord_width_lp,y_cord_width_lp);
  test_link_sif_s [num_tiles_y_p-1:0][num_tiles_x_p-1:0][dirs_lp-1:W] link_li;
  test_link_sif_s [num_tiles_y_p-1:0][num_tiles_x_p-1:0][dirs_lp-1:W] link_lo;
  logic [num_tiles_y_p-1:0][num_tiles_x_p-1:0] done_lo;


  for (genvar y = 0; y < num_tiles_y_p; y++) begin: ty
    for (genvar x = 0; x < num_tiles_x_p; x++) begin: tx
      test_tile #(
        .dims_p(dims_p)
        ,.x_cord_width_p(x_cord_width_lp)
        ,.y_cord_width_p(y_cord_width_lp)
        ,.num_tiles_x_p(num_tiles_x_p)
        ,.num_tiles_y_p(num_tiles_y_p)
        ,.data_width_p(data_width_p)
        ,.ruche_factor_X_p(ruche_factor_X_p)
        ,.ruche_factor_Y_p(ruche_factor_Y_p)
        ,.XY_order_p(XY_order_p)
      ) tile (
        .clk_i(clk)
        ,.reset_i(reset)
    
        ,.link_i(link_li[y][x])
        ,.link_o(link_lo[y][x])
    
        ,.my_x_i((x_cord_width_lp)'(x))
        ,.my_y_i((y_cord_width_lp)'(y))

        ,.done_o(done_lo[y][x])
      );
    end
  end


  for (genvar y = 0; y < num_tiles_y_p; y++) begin
    for (genvar x = 0; x < num_tiles_x_p; x++) begin

      // connect local
      if (dims_p >= 2) begin
        // west
        if (x == 0) begin
          assign link_li[y][x][W] = '0;
        end
        else begin
          assign link_li[y][x][W] = link_lo[y][x-1][E];
        end

        // east
        if (x == num_tiles_x_p-1) begin
          assign link_li[y][x][E] = '0;
        end
        else begin
          assign link_li[y][x][E] = link_lo[y][x+1][W];
        end

        // north
        if (y == 0) begin
          assign link_li[y][x][N] = '0;
        end
        else begin
          assign link_li[y][x][N] = link_lo[y-1][x][S];
        end

        // south
        if (y == num_tiles_y_p-1) begin
          assign link_li[y][x][S] = '0;
        end
        else begin
          assign link_li[y][x][S] = link_lo[y+1][x][N];
        end
      end

      // connect ruche x
      if (dims_p >= 3) begin
        // RW
        if (x >= ruche_factor_X_p) begin
          assign link_li[y][x][RW] = link_lo[y][x-ruche_factor_X_p][RE];
        end
        else begin
          assign link_li[y][x][RW] = '0;
        end

        // RE
        if (x < num_tiles_x_p - ruche_factor_X_p) begin
          assign link_li[y][x][RE] = link_lo[y][x+ruche_factor_X_p][RW];
        end
        else begin
          assign link_li[y][x][RE] = '0;
        end
      end

      // connect ruche y
      if (dims_p == 4) begin
        // RN
        if (y >= ruche_factor_Y_p) begin
          assign link_li[y][x][RN] = link_lo[y-ruche_factor_Y_p][x][RS];
        end
        else begin
          assign link_li[y][x][RN] = '0;
        end

        // RS
        if (y < num_tiles_y_p - ruche_factor_Y_p) begin
          assign link_li[y][x][RS] = link_lo[y+ruche_factor_Y_p][x][RN];
        end
        else begin
          assign link_li[y][x][RS] = '0;
        end

      end

    end
  end





  initial begin
    wait(&done_lo);
    $display("[BSG_FINISH] test successful.");
    $finish;
  end


endmodule
