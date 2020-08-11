
//
// Paul Gao 08/2020
//
//

`include "bsg_noc_links.vh"

module bsg_noc_performance_test_node_client

 #(parameter link_width_p = "inv"
  ,parameter node_id_p = "inv"
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(link_width_p)  
  )

  (input link_clk_i
  ,input link_reset_i
  ,input link_en_i
  ,output link_done_o

  ,input  [bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [bsg_ready_and_link_sif_width_lp-1:0] link_o
  );
  
  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(link_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_i_cast, link_o_cast;

  assign link_i_cast = link_i;
  assign link_o      = link_o_cast;


  /********************* Client node *********************/
  
  assign link_o_cast.ready_and_rev = 1'b1;
  assign link_o_cast.v = 1'b0;
  assign link_o_cast.data = '0;
  
  logic [31:0] timestamp_r;
  bsg_counter_clear_up
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ) timestamp_count
  (.clk_i  (link_clk_i)
  ,.reset_i(~link_en_i)
  ,.clear_i(1'b0)
  ,.up_i   (1'b1)
  ,.count_o(timestamp_r)
  );

  logic [31:0] received_r;
  bsg_counter_clear_up
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ) received_count
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (link_i_cast.v)
  ,.count_o(received_r)
  );
  
  logic [31:0] total_delay_r;
  bsg_counter_up_down 
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ,.max_step_p(1<<16-1)
  ) total_delay_count
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.up_i   ((link_i_cast.v && (received_r >= 10000))? 16'(timestamp_r - 32'(link_i_cast.data)) : '0)
  ,.down_i ('0)
  ,.count_o(total_delay_r)
  );
  
  logic done_r;
  assign link_done_o = done_r;
  
  real timestamp_f, received_f, total_delay_f;
  assign timestamp_f   = timestamp_r;
  assign received_f    = received_r;
  assign total_delay_f = total_delay_r;
  
  always_ff @(posedge link_clk_i)
  begin
    if (link_reset_i)
      begin
        done_r <= 1'b0;
      end
    else
      begin
        if ((received_r == 50000) & ~done_r)
          begin
            done_r <= 1'b1;
            $display("\n");
            $display("Node %d finished\n", node_id_p);
            $display("Total received: %d\n", received_r);
            $display("Timestamp: %d\n", timestamp_r);
            $display("Total delay cycles: %d\n", total_delay_r);
            
            $display("Average throughput: %f\n", received_f/timestamp_f);
            $display("Average delay: %f\n", total_delay_f/(received_f-10000));
          end
      end
  end

endmodule
