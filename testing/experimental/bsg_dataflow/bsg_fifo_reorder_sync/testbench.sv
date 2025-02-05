module testbench();

  parameter els_p = 16;
  parameter width_p = 32;
  parameter lg_els_lp = `BSG_SAFE_CLOG2(els_p);
  parameter num_test_p = 100000;

  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  logic fifo_alloc_v_lo;
  logic [lg_els_lp-1:0] fifo_alloc_id_lo;
  logic fifo_alloc_yumi_li;

  logic write_v_li;
  logic [lg_els_lp-1:0] write_id_li;
  logic [width_p-1:0] write_data_li;

  logic fifo_deq_v_lo;
  logic [width_p-1:0] fifo_deq_data_lo;
  logic fifo_deq_yumi_li;

  logic empty_lo;

  bsg_fifo_reorder_sync #(
    .width_p(width_p)
    ,.els_p(els_p)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.fifo_alloc_v_o(fifo_alloc_v_lo)
    ,.fifo_alloc_id_o(fifo_alloc_id_lo)
    ,.fifo_alloc_yumi_i(fifo_alloc_yumi_li)

    ,.write_v_i(write_v_li)
    ,.write_id_i(write_id_li)
    ,.write_data_i(write_data_li)

    ,.fifo_deq_v_o(fifo_deq_v_lo)
    ,.fifo_deq_data_o(fifo_deq_data_lo)
    ,.fifo_deq_yumi_i(fifo_deq_yumi_li)

    ,.empty_o(empty_lo)
  );


  logic [els_p-1:0] node_v_li;
  logic [width_p-1:0] node_data_li;
  logic [els_p-1:0] node_yumi_lo;

  logic [els_p-1:0] node_v_lo;
  logic [els_p-1:0][width_p-1:0] node_data_lo;
  logic [els_p-1:0] node_yumi_li;

  for (genvar i = 0; i < els_p; i++) begin
    remote_node #(
      .width_p(width_p)
      ,.max_delay_p(32-(i/2)) // unequal random delay
      ,.id_p(i)
    ) node0 (
      .clk_i(clk)
      ,.reset_i(reset)
      
      ,.v_i(node_v_li[i])
      ,.data_i(node_data_li)
      ,.yumi_o(node_yumi_lo[i])

      ,.v_o(node_v_lo[i])
      ,.data_o(node_data_lo[i])
      ,.yumi_i(node_yumi_li[i])
    );
  end


  // sender
  integer sent_r;

  wire send_done = (sent_r == num_test_p);
  
  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) demux0 (
    .i(fifo_alloc_id_lo)
    ,.v_i(fifo_alloc_v_lo & ~send_done)
    ,.o(node_v_li)
  );

  wire send = fifo_alloc_v_lo & node_yumi_lo[fifo_alloc_id_lo] & ~send_done; 
  assign fifo_alloc_yumi_li = send;

  always_ff @ (posedge clk) begin
    if (reset) begin
      sent_r <= 0;
    end
    else begin
      if (send) sent_r <= sent_r + 1;
    end
  end

  assign node_data_li = (width_p)'(sent_r);

  // recv
  logic rr_v_lo;
  logic rr_yumi_li;
  
  bsg_round_robin_n_to_1 #(
    .width_p(width_p)
    ,.num_in_p(els_p)
    ,.strict_p(0)
  ) rr0 (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.data_i(node_data_lo)
    ,.v_i(node_v_lo)
    ,.yumi_o(node_yumi_li)

    ,.v_o(rr_v_lo)
    ,.data_o(write_data_li)
    ,.tag_o(write_id_li)
    ,.yumi_i(rr_yumi_li)
  ); 

  //assign rr_yumi_li = rr_v_lo;
  //assign write_v_li = rr_v_lo;

  integer recv_delay_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      recv_delay_r <= 0;
    end
    else begin
      if (rr_v_lo) begin
        if (recv_delay_r == 0)
          recv_delay_r <= $urandom_range(8,0);
        else
          recv_delay_r <= recv_delay_r - 1;
      end
    end
  end

  assign rr_yumi_li = rr_v_lo & (recv_delay_r == 0);
  assign write_v_li = rr_v_lo & (recv_delay_r == 0);

  // checker
  integer check_delay_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      check_delay_r <= 0;
    end
    else begin
      if (fifo_deq_v_lo) begin
        if (check_delay_r == 0) begin
          check_delay_r <= $urandom_range(8,0);
        end
        else begin
          check_delay_r <= check_delay_r - 1;
        end
      end
    end
  end

  assign fifo_deq_yumi_li = fifo_deq_v_lo & (check_delay_r == 0);

  integer check_count_r;
  always_ff @ (posedge clk) begin
    if (reset) begin
      check_count_r <= 0 ;
    end
    else begin
      if (fifo_deq_yumi_li) begin
        check_count_r <= check_count_r + 1;
        $display("data out: %d", fifo_deq_data_lo);
        assert(check_count_r == fifo_deq_data_lo) else $fatal(1, "fail");
      end

    end
  end



  initial begin
    wait((check_count_r == num_test_p) & (sent_r == num_test_p));
    #100000;
    assert(empty_lo) else $fatal(1, "[BSG_FAIL] FIFO is not empty.");
    $finish();
  end
  

endmodule
