module torus_router_profiler
  #(parameter `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)
    , parameter num_vc_p=2
    , parameter dims_p=2
    , localparam dirs_lp=(dims_p*2)+1
    , parameter tracefile_p="torus_router_stat.csv"
  )
  (
    input clk_i
    , input reset_i
    
    , input [dirs_lp-1:0][num_vc_p-1:0] vc_v_lo
    , input [dirs_lp-1:0][num_vc_p-1:0][dirs_lp-1:0] dir_sel_lo

    , input [dirs_lp-1:0][num_vc_p-1:0] alloc_link_v_lo
    , input [dirs_lp-1:0][num_vc_p-1:0] alloc_link_ready_li

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );


  // For each output;
  typedef struct packed {
    integer idle;
    integer utilized;
    integer stalled;
  } router_stat_s;

  router_stat_s [dirs_lp-1:0] stat_r;
  integer total_r;

  // Is there any request?
  logic [dirs_lp-1:0][num_vc_p-1:0][dirs_lp-1:0] dir_sel_masked;
  logic [dirs_lp-1:0] has_req;

  for (genvar i = 0; i < dirs_lp; i++) begin
    for (genvar j = 0; j < num_vc_p; j++) begin
      assign dir_sel_masked[i][j] = {dirs_lp{vc_v_lo[i][j]}} & dir_sel_lo[i][j];
    end
  end

  bsg_transpose_reduce #(
    .els_p(dirs_lp*num_vc_p)
    ,.width_p(dirs_lp)
    ,.or_p(1)
  ) tpr0 (
    .i(dir_sel_masked)
    ,.o(has_req)
  );


  // Is utilized
  wire [dirs_lp-1:0][num_vc_p-1:0] utilized = alloc_link_v_lo & alloc_link_ready_li;
  

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      stat_r <= '0;
      total_r <= '0;
    end
    else begin
      total_r <= total_r + 1;
      for (integer i = 0; i < dirs_lp; i++) begin
        stat_r[i].idle <= stat_r[i].idle + (has_req[i] ? 0 : 1);
        stat_r[i].utilized <= stat_r[i].utilized + (|utilized[i]);
      end
    end
  end


  // print header;
  integer fd;

  always @ (negedge reset_i) begin
    if ((my_x_i == '0) && (my_y_i == '0)) begin
      fd = $fopen(tracefile_p, "w");
      $fwrite(fd, "x,y,dirs,idle,utilized,stalled\n");
      $fclose(fd);
    end
  end

  final begin
    fd = $fopen(tracefile_p, "a");
    for (integer i = 0; i < dirs_lp; i++) begin
      $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d\n", my_x_i, my_y_i, i, stat_r[i].idle, stat_r[i].utilized, total_r - stat_r[i].idle - stat_r[i].utilized);
    end
    $fclose(fd);
  end


endmodule
