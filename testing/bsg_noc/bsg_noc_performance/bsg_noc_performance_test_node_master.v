
//
// Paul Gao 08/2020
//
//

`include "bsg_noc_links.vh"

module bsg_noc_performance_test_node_master

 #(parameter link_width_p = "inv"
  ,parameter node_id_p = "inv"
  ,parameter utilization_p = "inv"
  ,parameter len_p = 1
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(link_width_p)  
  )

  (input link_clk_i
  ,input link_reset_i
  ,input link_en_i

  ,input  [bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [bsg_ready_and_link_sif_width_lp-1:0] link_o
  );
  
  localparam lg_fifo_depth_lp = 3;
  
  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(link_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_i_cast, link_o_cast;

  assign link_i_cast = link_i;
  assign link_o      = link_o_cast;


  /********************* Master node *********************/
  
  assign link_o_cast.ready_and_rev = 1'b1;
  
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

  logic req_out_v, req_out_ready;
  logic piso_v, piso_ready;
  assign link_o_cast.data = (link_width_p)'(timestamp_r);

  bsg_parallel_in_serial_out 
 #(.width_p(link_width_p)
  ,.els_p  (len_p)
  ) piso
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.valid_i(piso_v)
  ,.data_i ('0)
  ,.ready_o(piso_ready)
  ,.valid_o(link_o_cast.v)
  ,.data_o ()
  ,.yumi_i (link_o_cast.v & link_i_cast.ready_and_rev)
  );
  
  bsg_serial_in_parallel_out_full
 #(.width_p(link_width_p)
  ,.els_p  (len_p)
  ) sipof
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.v_i    (req_out_v)
  ,.ready_o(req_out_ready)
  ,.data_i ('0)
  ,.data_o ()
  ,.v_o    (piso_v)
  ,.yumi_i (piso_v & piso_ready)
  );
  
  logic hit_r;
  
  bsg_fifo_1r1w_small
 #(.width_p(link_width_p)
  ,.els_p  (65536)
  ) queue_fifo
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)

  ,.ready_o()
  ,.v_i    (hit_r)
  ,.data_i ('0)

  ,.v_o    (req_out_v)
  ,.data_o ()
  ,.yumi_i (req_out_v & req_out_ready)
  );
  
  int i, random_number;
  
  always_ff @(posedge link_clk_i)
  begin
    if (link_reset_i)
      begin
        hit_r <= 1'b0;
      end
    else if (link_en_i)
      begin
        for (i = 0; i < node_id_p+1; i++)
          begin
            random_number = $urandom_range(999);
          end
        hit_r <= (random_number < utilization_p);
      end
  end
  
endmodule
