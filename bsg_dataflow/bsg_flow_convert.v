//
// mbt 11/26/2014
//
// this module converts between the various link-level flow-control
// protocols.
//
// fixme: many of the cases have not been tested. naming convention might
// be better. more asserts would be good. send_v_and_ready_p does not seem to
// be implemented.  clocked versions should be handled by separate module.
//
// USAGE:
//
// 1. You need exactly one send_ parameter set and one recv parameter set.  
// 2. A parameter x_then_y says that the signal y is combinationally dependent on x.
// 3. A parameter x_and_y says that the signal x and y are not combinationally dependent.

// So for example, yumi by definition is combinationally dependent on v, 
//   since the downstream module looks at the v signal and then decides to assert yumi.  
//   Hence, v_then_yumi is appropriate.
//
// Similarly, if you have a module that asserts v, but only if the downstream
//    module indicates that it is ready, then, you would have ready_then_v. 
//
// On the other hand, if both upsteam and downstream module are supposed to
//    assert their signals in parallel, then it would be v_and_ready.
//
// Here is an example usage:
//
//   bsg_flow_convert #(.width_p(nodes_p)
//                      ,.send_v_and_ready_p(1)
//                      ,.recv_v_and_retry_p(1)
//                      ) s2b
//   (.v_i  (v_i)
//    ,.fc_o(ready_o)
//
//    ,.v_o(switch_2_blockValid)
//    ,.fc_i(switch_2_blockRetry)
//    );
//


`include "bsg_defines.v"

module bsg_flow_convert
  #(parameter send_v_and_ready_p    = 0
    , parameter send_v_then_yumi_p  = 0
    , parameter send_ready_then_v_p = 0
    , parameter send_retry_then_v_p = 0
    , parameter send_v_and_retry_p  = 0
    , parameter recv_v_and_ready_p  = 0
    , parameter recv_v_then_yumi_p  = 0
    , parameter recv_ready_then_v_p = 0
    // recv and retry are independent signals
    , parameter recv_v_and_retry_p  = 0
    // retry is dependent on retry
    , parameter recv_v_then_retry_p = 0
    , parameter width_p = 1
    )

   (input   [width_p-1:0]  v_i
    , output [width_p-1:0] fc_o

    , output [width_p-1:0] v_o
    , input [width_p-1:0]  fc_i
    );

   // if yumi needs to be made conditional on valid
   if ((send_v_then_yumi_p  & recv_v_and_ready_p)
       | (send_v_then_yumi_p & recv_ready_then_v_p)
       )
     assign fc_o = fc_i & v_i;
   // similar case but retry must be inverted
   else if (send_v_then_yumi_p & recv_v_and_retry_p)
     assign fc_o = ~fc_i & v_i;
   else if (send_ready_then_v_p & recv_v_then_yumi_p)
     // fixme fifo
     initial begin $display("### %m a unhandled case requires fifo"); $finish(); end
   else if (send_ready_then_v_p & recv_v_then_retry_p)
     // fixme fifo inverted retry
     initial begin $display("### %m unhandled case requires fifo"); $finish();
 end
   // if retry needs to be inverted to be a ready signal
   // or a ready needs to be inverted to be a retry
   else if (send_retry_then_v_p & recv_v_then_yumi_p)
     initial begin $display("### %m unhandled case requires fifo"); $finish();
 end
   else if ((send_retry_then_v_p | send_v_and_retry_p) ^ (recv_v_then_retry_p | recv_v_and_retry_p))
     assign fc_o = ~fc_i;
   else
     assign fc_o = fc_i;

   // if valid needs to be made conditional on ready
   if (recv_ready_then_v_p & ~send_ready_then_v_p)
     assign v_o = v_i & fc_i;
   else
     assign v_o = v_i;


endmodule
