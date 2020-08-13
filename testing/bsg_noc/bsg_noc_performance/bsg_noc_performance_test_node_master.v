
//
// Paul Gao 08/2020
//
//

`include "bsg_noc_links.vh"

module bsg_noc_performance_test_node_master

 #(parameter link_width_p = "inv"
  ,parameter node_id_p = "inv"
  ,parameter utilization_p = "inv"
  ,parameter utilization_ratio_p = "inv"
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
  always_ff @(posedge link_clk_i)
  begin
    timestamp_r <= $time;
  end

  logic hit_r;
  logic piso_v_li, piso_ready_lo;
  logic piso_v_lo, piso_ready_li;

  bsg_fifo_1r1w_small
 #(.width_p(link_width_p)
  ,.els_p  (65536)
  ) queue_fifo
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)

  ,.ready_o(piso_ready_li)
  ,.v_i    (piso_v_lo)
  ,.data_i ((link_width_p)'(timestamp_r))

  ,.v_o    (link_o_cast.v)
  ,.data_o (link_o_cast.data)
  ,.yumi_i (link_o_cast.v & link_i_cast.ready_and_rev)
  );

  bsg_parallel_in_serial_out 
 #(.width_p(link_width_p)
  ,.els_p  (len_p)
  ) piso
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.valid_i(piso_v_li)
  ,.data_i ('0)
  ,.ready_o(piso_ready_lo)
  ,.valid_o(piso_v_lo)
  ,.data_o ()
  ,.yumi_i (piso_v_lo & piso_ready_li)
  );
  
  bsg_serial_in_parallel_out_full
 #(.width_p(link_width_p)
  ,.els_p  (len_p)
  ) sipof
  (.clk_i  (link_clk_i)
  ,.reset_i(link_reset_i)
  ,.v_i    (hit_r)
  ,.ready_o()
  ,.data_i ('0)
  ,.data_o ()
  ,.v_o    (piso_v_li)
  ,.yumi_i (piso_v_li & piso_ready_lo)
  );
  
  int i, random_number;
  logic [7:0] ratio_counter_r;
  
  always_ff @(posedge link_clk_i)
  begin
    if (link_reset_i)
      begin
        hit_r <= 1'b0;
        ratio_counter_r <= '0;
      end
    else if (ratio_counter_r == utilization_ratio_p-1)
      begin
        for (i = 0; i < node_id_p+1; i++)
          begin
            random_number = $urandom_range(100-1);
          end
        hit_r <= (random_number < utilization_p) & link_en_i;
        ratio_counter_r <= '0;
      end
    else
      begin
        hit_r <= 1'b0;
        ratio_counter_r <= ratio_counter_r + 1'b1;
      end
  end
  
endmodule
