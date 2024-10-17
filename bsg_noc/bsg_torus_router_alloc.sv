`include "bsg_defines.sv"


module bsg_torus_router_alloc
  import bsg_torus_router_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(num_vc_p)

    , parameter dims_p=2
    , localparam sw_dirs_lp=(dims_p*2)+1
    , localparam vc_dirs_lp=(dims_p*2*num_vc_p)+1

    , localparam bit [vc_dirs_lp-1:0][vc_dirs_lp-1:0] vc_matrix_lp = TorusXY
    //, localparam dir_id_width_lp=`BSG_SAFE_CLOG2(dirs_lp)
    //, localparam vc_id_width_lp=`BSG_SAFE_CLOG2(num_vc_p)
  )
  (
    input clk_i
    , input reset_i

    , input [vc_dirs_lp-1:0] vc_v_i
    , input [vc_dirs_lp-1:0][width_p-1:0] vc_data_i
    , input [vc_dirs_lp-1:0][vc_dirs_lp-1:0] vc_dir_sel_i
    , input [vc_dirs_lp-1:0][sw_dirs_lp-1:0] sw_dir_sel_i
    , output logic [vc_dirs_lp-1:0] vc_yumi_o

    , output logic [sw_dirs_lp-1:0][width_p-1:0] xbar_data_o // input VC arbitrated data;
    , output logic [sw_dirs_lp-1:0][sw_dirs_lp-1:0] xbar_sel_o

    , output logic [vc_dirs_lp-1:0] link_v_o
    , input [vc_dirs_lp-1:0] link_ready_i
  );


  // which input VCs are valid and have output VC ready?
  // these VCs are good to request;
  logic [vc_dirs_lp-1:0] vc_valid_ready;

  for (genvar i = 0; i < vc_dirs_lp; i++) begin: vcvr
    localparam output_els_lp = `BSG_COUNTONES_SYNTH(vc_matrix_lp[i]);
  
    logic [output_els_lp-1:0] link_ready_conc, vc_sel_conc;

    bsg_concentrate_static #(
      .pattern_els_p(vc_matrix_lp[i])
    ) conc0 (
      .i(link_ready_i)
      ,.o(link_ready_conc)
    );
  
    bsg_concentrate_static #(
      .pattern_els_p(vc_matrix_lp[i])
    ) conc1 (
      .i(vc_dir_sel_i[i])
      ,.o(vc_sel_conc)
    );

    assign vc_valid_ready[i] = vc_v_i[i] & (|(link_ready_conc & vc_sel_conc));
  end


  // mask dir_sel_i by which of them are vc_valid_ready;
  logic [vc_dirs_lp-1:0][sw_dirs_lp-1:0] dir_sel_masked; // masked by vc_valid_ready;
  for (genvar i = 0; i < vc_dirs_lp; i++) begin
    assign dir_sel_masked[i] = sw_dir_sel_i[i] & {sw_dirs_lp{vc_valid_ready[i]}};
  end


  // Reduce dir_sel_masked by OR;
  logic [sw_dirs_lp-1:0][sw_dirs_lp-1:0] dir_sel_reduced;

  for (genvar i = 0; i < sw_dirs_lp-1; i++) begin: reduce0
    bsg_transpose_reduce #(
      .or_p(1)
      ,.els_p(num_vc_p)
      ,.width_p(sw_dirs_lp)
    ) tp0 (
      .i(dir_sel_masked[1+(num_vc_p*i)+:num_vc_p])
      ,.o(dir_sel_reduced[1+i]) // SNEW;
    );
  end

  assign dir_sel_reduced[0] = dir_sel_masked[0];  // Proc;


  // SW wavefront alloc;
  logic [sw_dirs_lp-1:0][sw_dirs_lp-1:0] sw_grant; // [in][out];
  logic alloc_update;

  bsg_alloc_wavefront #(
    .width_p(sw_dirs_lp)
  ) alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.reqs_i(dir_sel_reduced)
    ,.grants_o(sw_grant)

    ,.yumi_i(alloc_update)
  );

  assign alloc_update = |dir_sel_reduced;


  // Which input VCs have matching sw grant?
  logic [vc_dirs_lp-1:0] vc_sw_grant_match;
  
  for (genvar i = 0; i < vc_dirs_lp; i++) begin
    localparam sw_id_lp = (i == 0) ? 0 : (i+1)/2;
    assign vc_sw_grant_match[i] = sw_dir_sel_i[i] == sw_grant[sw_id_lp];
  end


  // for each input, we want to know which VCs have output VC ready and sw grant matched;
  wire [vc_dirs_lp-1:0] vc_good_to_go = vc_valid_ready & vc_sw_grant_match;
  

  // for each input, we want to arbitrate if more than one VC are good to go;
  logic [sw_dirs_lp-2:0][num_vc_p-1:0] vc_grant;
  logic [sw_dirs_lp-2:0] vc_arb_update;

  for (genvar i = 0; i < sw_dirs_lp-1; i++) begin: ip1
    // arbiter;
    bsg_arb_round_robin #(
      .width_p(num_vc_p)
    ) rr0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.reqs_i(vc_good_to_go[1+(num_vc_p*i)+:num_vc_p])
      ,.grants_o(vc_grant[i])
    
      ,.yumi_i(vc_arb_update[i])
    );

    assign vc_arb_update[i] = |vc_good_to_go[1+(num_vc_p*i)+:num_vc_p];

    // select packet to forward;
    bsg_mux_one_hot #(
      .els_p(num_vc_p)
      ,.width_p(width_p)
    ) vcmux0 (
      .data_i(vc_data_i[1+(num_vc_p*i)+:num_vc_p])
      ,.sel_one_hot_i(vc_grant[i])
      ,.data_o(xbar_data_o[1+i])
    );

    assign vc_yumi_o[1+(num_vc_p*i)+:num_vc_p] = vc_good_to_go[1+(num_vc_p*i)+:num_vc_p] & vc_grant[i];
  end

  assign xbar_data_o[0] = vc_data_i[0];
  assign vc_yumi_o[0] = vc_good_to_go[0];



  // SW select signal;
  logic [sw_dirs_lp-1:0][sw_dirs_lp-1:0] sw_grant_tp; // [out][in] for each output, which input is selected?

  bsg_transpose #(
    .els_p(sw_dirs_lp)
    ,.width_p(sw_dirs_lp)
  ) tp0 ( 
    .i(sw_grant)
    ,.o(sw_grant_tp)
  );

  assign xbar_sel_o = sw_grant_tp;


  // Assign link_v_o;
  logic [vc_dirs_lp-1:0][vc_dirs_lp-1:0] vc_dir_sel_masked; // mask vc_dir_sel_i with vc_yumi_o;

  for (genvar i = 0; i < vc_dirs_lp; i++) begin
    for (genvar j = 0; j < vc_dirs_lp; j++) begin
      if (vc_matrix_lp[i][j]) begin
        assign vc_dir_sel_masked[i][j] = vc_yumi_o[i] & vc_dir_sel_i[i][j];
      end
      else begin
        assign vc_dir_sel_masked[i][j] = 1'b0;
      end
    end
  end


  // transpose vc_dir_sel_masked; this gives for each output vc, which input vc selected this output vc.
  logic [vc_dirs_lp-1:0][vc_dirs_lp-1:0] vc_dir_sel_masked_tp;

  bsg_transpose_reduce #(
    .els_p(vc_dirs_lp)
    ,.width_p(vc_dirs_lp)
    ,.or_p(1)
  ) tp2 (
    .i(vc_dir_sel_masked)
    ,.o(link_v_o)
  );


endmodule
