
`include "bsg_defines.sv"

module bsg_fifo_bypass
 #(parameter `BSG_INV_PARAM(width_p )

   , parameter logic ready_THEN_valid_p = 0
   )
  (input [width_p-1:0]          data_i  // late
   , input                      v_i     // late
   , output logic               ready_param_o // early

   , output logic [width_p-1:0] data_o // late
   , output logic               v_o    // late
   , input                      yumi_i // late

   , output logic [width_p-1:0] fifo_data_o  // late
   , output logic               fifo_v_o     // late
   , input                      fifo_ready_param_i // early

   , input [width_p-1:0]        fifo_data_i  // early
   , input                      fifo_v_i     // early
   , output                     fifo_yumi_o  // late
   );

  wire enq = ready_THEN_valid_p ? v_i : (ready_param_o & v_i);

  assign ready_param_o     = fifo_ready_param_i;
  assign fifo_data_o = data_i;
  assign fifo_v_o    = enq & (fifo_v_i | ~yumi_i);

  assign data_o      = fifo_v_i ? fifo_data_i : data_i;
  assign v_o         = fifo_v_i | enq;
  assign fifo_yumi_o = fifo_v_i & yumi_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_bypass)
