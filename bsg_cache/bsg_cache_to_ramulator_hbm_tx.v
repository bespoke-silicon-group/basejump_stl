/**
 *    bsg_cache_to_ramulator_hbm_tx.v
 *
 */


module bsg_cache_to_ramulator_hbm_tx
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
      
    , input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o

    , input hbm_clk_i
    , input hbm_reset_i

    , output logic hbm_data_v_o
    , output logic [hbm_data_width_p-1:0] hbm_data_o
    , input hbm_data_yumi_i
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


  //  de-serialization
  //
  logic sipo_v_li;
  logic sipo_ready_lo;
  logic [data_width_p-1:0] sipo_data_li;

  logic sipo_v_lo;
  logic [hbm_data_width_p-1:0] sipo_data_lo;
  logic sipo_yumi_li;

  bsg_serial_in_parallel_out_full #(
    .width_p(data_width_p)
    ,.els_p(hbm_data_width_p/data_width_p)
  ) sipo (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.v_i(sipo_v_li)
    ,.data_i(sipo_data_li)
    ,.ready_o(sipo_ready_lo)

    ,.v_o(sipo_v_lo)
    ,.data_o(sipo_data_lo)
    ,.yumi_i(sipo_yumi_li)
  ); 
  
  logic [num_cache_p-1:0] cache_sel;
  
  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_v_lo)
    ,.o(cache_sel)
  );

  assign sipo_data_li = dma_data_i[tag_lo];
  assign sipo_v_li = tag_v_lo & dma_data_v_i[tag_lo];
  assign dma_data_yumi_o = cache_sel & dma_data_v_i & {num_cache_p{sipo_ready_lo}};

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

  always_comb begin
    if (count_lo == block_size_in_words_p-1) begin
      counter_clear_li = sipo_v_li & sipo_ready_lo;
      counter_up_li = 1'b0;
      tag_yumi_li = sipo_v_li & sipo_ready_lo;
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = sipo_v_li & sipo_ready_lo;
      tag_yumi_li = 1'b0;
    end
  end

 
  // async fifo
  //
  logic afifo_full;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(4*num_cache_p))
    ,.width_p(hbm_data_width_p)
  ) data_afifo (
    .w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)
    ,.w_enq_i(sipo_v_lo)
    ,.w_data_i(sipo_data_lo)
    ,.w_full_o(afifo_full)
  
    ,.r_clk_i(hbm_clk_i) 
    ,.r_reset_i(hbm_reset_i)
    ,.r_deq_i(hbm_data_yumi_i)
    ,.r_data_o(hbm_data_o)
    ,.r_valid_o(hbm_data_v_o)
  );

  assign sipo_yumi_li = sipo_v_lo & ~afifo_full;


endmodule
