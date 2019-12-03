/**
 *    bsg_cache_to_ramulator_hbm_rx.v
 *
 */


module bsg_cache_to_ramulator_hbm_rx
  #(parameter num_cache_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter hbm_data_width_p="inv"

    , parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
  )
  (
    input core_clk_i
    , input core_reset_i

    , input v_i
    , input [lg_num_cache_lp-1:0] tag_i
    , output logic ready_o

    , output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input hbm_clk_i
    , input hbm_reset_i  
  
    , input hbm_data_v_i
    , input [hbm_data_width_p-1:0] hbm_data_i
  );


  //  tag fifo
  //
  logic tag_v_lo;
  logic [lg_num_cache_lp-1:0] tag_lo;
  logic tag_yumi_li;  

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(num_cache_p)
  ) tag_fifo (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.v_i(v_i)
    ,.ready_o(ready_o)
    ,.data_i(tag_i)

    ,.v_o(tag_v_lo)
    ,.data_o(tag_lo)
    ,.yumi_i(tag_yumi_li)
  );


  //  async fifo
  //
  logic afifo_full;
  logic afifo_deq;
  logic [hbm_data_width_p-1:0] afifo_data_lo;
  logic afifo_v_lo;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(4*num_cache_p))
    ,.width_p(hbm_data_width_p)
  ) data_afifo (
    .w_clk_i(hbm_clk_i)
    ,.w_reset_i(hbm_reset_i)
    ,.w_enq_i(hbm_data_v_i)
    ,.w_data_i(hbm_data_i)
    ,.w_full_o(afifo_full)
  
    ,.r_clk_i(core_clk_i) 
    ,.r_reset_i(core_reset_i)
    ,.r_deq_i(afifo_deq)
    ,.r_data_o(afifo_data_lo)
    ,.r_valid_o(afifo_v_lo)
  );


  //  serialization
  //
  logic piso_ready_lo;
  logic piso_v_lo;
  logic [data_width_p-1:0] piso_data_lo;
  logic piso_yumi_li;

  bsg_parallel_in_serial_out #(
    .width_p(data_width_p)
    ,.els_p(hbm_data_width_p/data_width_p)    
  ) piso (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.valid_i(afifo_v_lo)
    ,.data_i(afifo_data_lo)
    ,.ready_o(piso_ready_lo)

    ,.valid_o(piso_v_lo)
    ,.data_o(piso_data_lo)
    ,.yumi_i(piso_yumi_li)
  );
  
  assign afifo_deq = afifo_v_lo & piso_ready_lo;
  
  for (genvar i = 0; i < num_cache_p; i++)
    assign dma_data_o[i] = piso_data_lo;


  logic [num_cache_p-1:0] cache_sel;

  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_v_lo)
    ,.o(cache_sel)
  );

  assign dma_data_v_o = cache_sel & {num_cache_p{piso_v_lo}};
  

  logic counter_clear_li;
  logic counter_up_li;
  logic [lg_block_size_in_words_lp-1:0] count_lo;
  
  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) counter (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.clear_i(counter_clear_li)
    ,.up_i(counter_up_li)
    ,.count_o(count_lo)
  );

  assign piso_yumi_li = dma_data_ready_i[tag_lo] & piso_v_lo & tag_v_lo;

 
  always_comb begin
    if (count_lo == block_size_in_words_p-1) begin
      counter_clear_li = piso_yumi_li;
      counter_up_li = 1'b0;
      tag_yumi_li = piso_yumi_li;
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = piso_yumi_li;
      tag_yumi_li = 1'b0;
    end
  end  





  // synopsys translate_off

  always_ff @ (negedge hbm_clk_i) begin
    if (~hbm_reset_i & hbm_data_v_i)
      assert(~afifo_full) else $error("async_fifo full!");
  end

  // synopsys translate_on


endmodule
