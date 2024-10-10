/**
 *    bsg_alloc_wavefront.sv
 *
 *    @author Tommy Jung
 *
 *    N:N wavefront allocator;
 *
 *    Based on "Efficient microarchitecture for network-on-chip routers",
 *               Daniel U Becker, PhD Thesis, Stanford University, 2012.
 *               (Section 3.3)
 *
 *    This module coordinates an arbitration between N agents and N resources.
 *    Each agent may request for one or more resources.
 *    Given a request matrix (row=agent, col=resource), it generates a grant matrix, such that,
 *    - no resource granted for more than one agent.
 *    - no agent granted more than one resource.
 *    - no grant when there is no request.
 *    - if there is a request, which is not granted, it implies some other grant in the same column or row.
 *    It tries to maximize the number of matches between agents and resources for improved utilization.
 *
 */


`include "bsg_defines.sv"



module bsg_alloc_wavefront
  #(parameter `BSG_INV_PARAM(width_p) // Number of Agents/Resources;
  )
  (
    input clk_i
    , input reset_i

    // 2-D bit matrix;
    // [agent_idx][resource_idx] 
    , input        [width_p-1:0][width_p-1:0] reqs_i
    , output logic [width_p-1:0][width_p-1:0] grants_o

    // assert yumi_i to accept the grant matrix;
    , input yumi_i
  );


  // Rotate reqs_i so that diagonal elements end up in the same row;
  logic [width_p-1:0][width_p-1:0] reqs_rotate;

  for (genvar i = 0; i < width_p; i++) begin
    for (genvar j = 0; j < width_p; j++) begin
      assign reqs_rotate[i][j] = reqs_i[(width_p+i-j)%width_p][j];
    end
  end
  

  // priority diagonal signal;;
  logic [width_p-1:0] priority_diag;


  // cell array;
  logic [(2*width_p)-1-1:0][width_p-1:0] y_li, x_li, priority_li, req_li, y_lo, x_lo, grant_lo;

  for (genvar i = 0; i < (2*width_p)-1; i++) begin: y
    for (genvar j = 0; j < width_p; j++) begin: x
      // wavefront cell;
      bsg_alloc_wavefront_cell cell0 (
        .x_i          (x_li[i][j])
        ,.y_i         (y_li[i][j])
        ,.priority_i  (priority_li[i][j])
        ,.req_i       (req_li[i][j])
        ,.y_o         (y_lo[i][j])
        ,.x_o         (x_lo[i][j])
        ,.grant_o     (grant_lo[i][j])
      );

      // connect y;
      if (i == 0) begin
        assign y_li[i][j] = 1'b0;
      end
      else begin
        assign y_li[i][j] = y_lo[i-1][j];
      end
      
      // connect x;
      if (i == 0) begin
        assign x_li[i][j]  = 1'b0;
      end
      else begin
        if (j == 0) begin
          assign x_li[i][j]  = x_lo[i-1][width_p-1];
        end
        else begin
          assign x_li[i][j]  = x_lo[i-1][j-1];
        end
      end

      // connect priority;
      if (i < width_p) begin
        assign priority_li[i][j] = priority_diag[i];
      end
      else begin
        assign priority_li[i][j] = 1'b0;
      end
      
      // connect req;
      assign req_li[i][j] = reqs_rotate[i%width_p][j];
    end    
  end
 
  



  // Priority diagonal generator;
  logic [width_p-1:0] rr_reqs;

  // OR reduce;
  for (genvar i = 0; i < width_p; i++) begin
    assign rr_reqs[i] = |reqs_rotate[i];
  end

  bsg_arb_round_robin #(
    .width_p(width_p)
  ) rr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.reqs_i(rr_reqs)
    ,.grants_o(priority_diag)
    ,.yumi_i(yumi_i)
  );


  ////////////////////////
  // Connect grant output;
  ////////////////////////
  
  // transpose grant_lo;
  logic [width_p-1:0][(2*width_p)-1-1:0] grants_tp;
  bsg_transpose #(
    .width_p(width_p)
    ,.els_p((2*width_p)-1)
  ) tp0 (
    .i(grant_lo)
    ,.o(grants_tp)
  );
  
  // Apply OR;
  logic [width_p-1:0][width_p-1:0] grants_or;
  for (genvar i = 0; i < width_p; i++) begin
    assign grants_or[i] = grants_tp[i][0+:width_p] | {1'b0, grants_tp[i][width_p+:width_p-1]};
  end

  // rotate;
  logic [width_p-1:0][width_p-1:0] grants_rotate;
  for (genvar i = 0; i < width_p; i++) begin
    assign grants_rotate[i] = width_p'({grants_or[i], grants_or[i]} >> i);
  end

  
  // transpose it back;
  bsg_transpose #(
    .width_p(width_p)
    ,.els_p(width_p)
  ) tp1 (
    .i(grants_rotate)
    ,.o(grants_o)
  );



endmodule


`BSG_ABSTRACT_MODULE(bsg_alloc_wavefront)
