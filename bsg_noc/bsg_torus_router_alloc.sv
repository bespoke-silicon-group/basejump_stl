`include "bsg_defines.sv"


module bsg_torus_router_alloc
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(num_vc_p)

    , parameter dims_p=2
    , localparam dirs_lp=(dims_p*2)+1
    , localparam dir_id_width_lp=`BSG_SAFE_CLOG2(dirs_lp)
    , localparam vc_id_width_lp=`BSG_SAFE_CLOG2(num_vc_p)
  )
  (
    input clk_i
    , input reset_i

    , input [dirs_lp-1:0][num_vc_p-1:0] vc_v_i
    , input [dirs_lp-1:0][num_vc_p-1:0][width_p-1:0] vc_data_i
    , input [dirs_lp-1:0][num_vc_p-1:0][num_vc_p-1:0] vc_sel_i
    , input [dirs_lp-1:0][num_vc_p-1:0][vc_id_width_lp-1:0] vc_sel_id_i
    , input [dirs_lp-1:0][num_vc_p-1:0][dirs_lp-1:0] dir_sel_i
    , input [dirs_lp-1:0][num_vc_p-1:0][dir_id_width_lp-1:0] dir_sel_id_i
    , output logic [dirs_lp-1:0][num_vc_p-1:0] vc_yumi_o

    , output logic [dirs_lp-1:0][width_p-1:0] xbar_data_o // input VC arbitrated data;
    , output logic [dirs_lp-1:0][dirs_lp-1:0] xbar_sel_o

    , output logic [dirs_lp-1:0][num_vc_p-1:0] link_v_o
    , input [dirs_lp-1:0][num_vc_p-1:0] link_ready_i
  );


  // which input VCs are valid and have output VC ready?
  // these VCs are good to request;
  logic [dirs_lp-1:0][num_vc_p-1:0] vc_valid_ready;

  for (genvar i = 0; i < dirs_lp; i++) begin
    for (genvar j = 0; j < num_vc_p; j++) begin
      assign vc_valid_ready[i][j] = vc_v_i[i][j] & link_ready_i[dir_sel_id_i[i][j]][vc_sel_id_i[i][j]];
    end
  end


  // SW allocation;
  logic [dirs_lp-1:0][num_vc_p-1:0][dirs_lp-1:0] dir_sel_masked; // masked by vc_valid_ready;
  for (genvar i = 0; i < dirs_lp; i++) begin
    for (genvar j = 0; j < num_vc_p; j++) begin
      assign dir_sel_masked[i][j] = dir_sel_i[i][j] & {dirs_lp{vc_valid_ready[i][j]}};
    end
  end


  // reduce dir_sel_masked by OR;
  logic [dirs_lp-1:0][dirs_lp-1:0] dir_sel_reduced;   // [in][out];
  for (genvar i = 0; i < dirs_lp; i++) begin: ip0
    bsg_transpose_reduce #(
      .or_p(1)
      ,.els_p(num_vc_p)
      ,.width_p(dirs_lp)
    ) tp0 (
      .i(dir_sel_masked[i])
      ,.o(dir_sel_reduced[i])
    );
  end


  // SW wavefront alloc;
  logic [dirs_lp-1:0][dirs_lp-1:0] sw_grant; // [in][out];
  logic alloc_update;

  bsg_alloc_wavefront #(
    .width_p(dirs_lp)
  ) alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.reqs_i(dir_sel_reduced)
    ,.grants_o(sw_grant)

    ,.yumi_i(alloc_update)
  );

  assign alloc_update = |dir_sel_reduced;


  // Which input VCs have matching sw grant?
  logic [dirs_lp-1:0][num_vc_p-1:0] vc_sw_grant_match;
  for (genvar i = 0; i < dirs_lp; i++) begin
    for (genvar j = 0; j < num_vc_p; j++) begin
      assign vc_sw_grant_match[i][j] = (dir_sel_i[i][j] == sw_grant[i]);
    end
  end


  // for each input, we want to know which VCs have output VC ready and sw grant matched;
  wire [dirs_lp-1:0][num_vc_p-1:0] vc_good_to_go = vc_valid_ready & vc_sw_grant_match;
  

  // for each input, we want to arbitrate if more than one VC are good to go;
  logic [dirs_lp-1:0][num_vc_p-1:0] vc_grant;
  logic [dirs_lp-1:0] vc_arb_update;

  for (genvar i = 0; i < dirs_lp; i++) begin: ip1
    // arbiter;
    bsg_arb_round_robin #(
      .width_p(num_vc_p)
    ) rr0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.reqs_i(vc_good_to_go[i])
      ,.grants_o(vc_grant[i])
    
      ,.yumi_i(vc_arb_update[i])
    );

    assign vc_arb_update[i] = |vc_good_to_go[i];

    // select packet to forward;
    bsg_mux_one_hot #(
      .els_p(num_vc_p)
      ,.width_p(width_p)
    ) mux0 (
      .data_i(vc_data_i[i])
      ,.sel_one_hot_i(vc_grant[i])
      ,.data_o(xbar_data_o[i])
    );

    assign vc_yumi_o[i] = vc_good_to_go[i] & vc_grant[i];
  end


  // SW select signal;
  logic [dirs_lp-1:0][dirs_lp-1:0] sw_grant_tp; // [out][in]

  bsg_transpose #(
    .els_p(dirs_lp)
    ,.width_p(dirs_lp)
  ) tp0 ( 
    .i(sw_grant)
    ,.o(sw_grant_tp)
  );

  assign xbar_sel_o = sw_grant_tp;

  


  // link_v_o; [out][vc]
  for (genvar i = 0; i < dirs_lp; i++) begin: op0

    logic [num_vc_p-1:0][num_vc_p-1:0] vc_sel_temp0; // vc_sel of granted input port;
    bsg_mux_one_hot #(
      .els_p(dirs_lp)
      ,.width_p(num_vc_p*num_vc_p)
    ) mux0 (
      .data_i(vc_sel_i)
      ,.sel_one_hot_i(sw_grant_tp[i])
      ,.data_o(vc_sel_temp0)
    );

    logic [num_vc_p-1:0] vc_grant_temp0; // vc_grant of granted input port;
    bsg_mux_one_hot #(
      .els_p(dirs_lp)
      ,.width_p(num_vc_p)
    ) mux1 (
      .data_i(vc_grant)
      ,.sel_one_hot_i(sw_grant_tp[i])
      ,.data_o(vc_grant_temp0)
    );

    logic [num_vc_p-1:0] vc_sel_final;
    bsg_mux_one_hot #(
      .els_p(num_vc_p)
      ,.width_p(num_vc_p)
    ) mux2 (
      .data_i(vc_sel_temp0)
      ,.sel_one_hot_i(vc_grant_temp0)
      ,.data_o(vc_sel_final)
    );

    assign link_v_o[i] = {num_vc_p{|sw_grant_tp[i]}} & vc_sel_final;
  end


endmodule
