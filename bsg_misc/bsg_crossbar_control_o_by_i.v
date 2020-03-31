/* bank mem banked crossbar */
/* high order bits determine bank # */


/*********************************
* bsg_crossbar_control_o_by_i
**********************************/

module bsg_crossbar_control_o_by_i #( parameter i_els_p     = -1
                                      ,parameter o_els_p     = -1
                                      // 0 = fixed hi,    1 = fixed lo,
                                      // 2 = round robin, 3 = round robin hold
                                      // 4 = round robin reset
                                      // 5 = dynamic change on FIFO status
                                      ,parameter rr_lo_hi_p  = "inv"
                                      ,parameter lg_o_els_lp = `BSG_SAFE_CLOG2(o_els_p)
                                      )
  ( input                                clk_i
   ,input                                reset_i

   //the reverse the priority for the dynamic scheme
   ,input                                reverse_pr_i
   // crossbar inputs
   ,input [i_els_p-1:0]                  valid_i
   ,input [i_els_p-1:0][lg_o_els_lp-1:0] sel_io_i
   ,output [i_els_p-1:0]                 yumi_o

   // crossbar outputs
   ,input [o_els_p-1:0]                  ready_i
   ,output [o_els_p-1:0]                 valid_o
   ,output [o_els_p-1:0][i_els_p-1:0]    grants_oi_one_hot_o
  );

  logic [i_els_p-1:0][o_els_p-1:0] sel_io_one_hot, grants_io_one_hot;
  logic [o_els_p-1:0][i_els_p-1:0] sel_oi_one_hot;

  genvar i;

  for (i = 0; i < i_els_p; i++) begin
    assign sel_io_one_hot[i] = valid_i[i]
      ? (o_els_p)'(1<<sel_io_i[i])
      : (o_els_p)'(0);
  end

   bsg_transpose #( .width_p(o_els_p)
                  ,.els_p  (i_els_p)
                 ) transpose0
                 ( .i(sel_io_one_hot)
                  ,.o(sel_oi_one_hot) // requets for each output
                 );

   for(i=0; i<o_els_p; i=i+1)
     begin: arb
        if (rr_lo_hi_p == 3 || rr_lo_hi_p == 4 )
          begin: rr
            bsg_round_robin_arb #( .inputs_p    (i_els_p)
                                  ,.hold_on_sr_p(rr_lo_hi_p == 3)
                                  ,.reset_on_sr_p(rr_lo_hi_p == 4)
                                   ) round_robin_arb
              ( .clk_i(clk_i)
                ,.reset_i(reset_i)
                ,.grants_en_i (ready_i[i])

                ,.reqs_i  (sel_oi_one_hot[i])
                ,.grants_o(grants_oi_one_hot_o[i])
                ,.sel_one_hot_o()

                ,.v_o   (valid_o[i])
                ,.tag_o ()
                ,.yumi_i(valid_o[i] & ready_i[i] )
                );
          end
       else if (rr_lo_hi_p == 5) begin: dynamic
            wire [1:0][i_els_p-1:0]   grants_oi_one_hot;

             bsg_arb_fixed #(.inputs_p(i_els_p)
                             ,.lo_to_hi_p( 1'b0 )
                             ) fixed_arb_low
              (.ready_i (ready_i[i])
               ,.reqs_i  (sel_oi_one_hot[i])
               ,.grants_o( grants_oi_one_hot[0] )
               );

             bsg_arb_fixed #(.inputs_p(i_els_p)
                             ,.lo_to_hi_p( 1'b1 )
                             ) fixed_arb_high
              (.ready_i (ready_i[i])
               ,.reqs_i  (sel_oi_one_hot[i])
               ,.grants_o( grants_oi_one_hot[1] )
               );

            assign grants_oi_one_hot_o[i] = reverse_pr_i
                        ? grants_oi_one_hot[1]
                        : grants_oi_one_hot[0];

            assign valid_o[i] = | grants_oi_one_hot_o[i];
       end else
          begin : fixed
             bsg_arb_fixed #(.inputs_p(i_els_p)
                             ,.lo_to_hi_p(rr_lo_hi_p&1'b1)
                             ) fixed_arb
              (.ready_i (ready_i[i])
               ,.reqs_i  (sel_oi_one_hot[i])
               ,.grants_o(grants_oi_one_hot_o[i])
               );

             assign valid_o[i] = | grants_oi_one_hot_o[i];
          end
     end // block: arb

  bsg_transpose #( .width_p(i_els_p)
                  ,.els_p  (o_els_p)
                 ) transpose1
                 ( .i(grants_oi_one_hot_o)
                  ,.o(grants_io_one_hot)
                 );

  for(i=0; i<i_els_p; i=i+1)
    assign yumi_o[i] = valid_i[i] & (| grants_io_one_hot[i]);

endmodule // bsg_crossbar_control_o_by_i
