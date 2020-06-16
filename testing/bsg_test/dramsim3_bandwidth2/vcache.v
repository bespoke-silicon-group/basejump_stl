module vcache 
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter dma_data_width_p="inv"
    , parameter num_subcache_p="inv"
  
 
    , parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p) 
    , parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i
    
    , input [bsg_cache_pkt_width_lp-1:0] cache_pkt_i
    , input v_i
    , output logic yumi_o

    , output logic [data_width_p-1:0] data_o
    , output logic v_o
    , input yumi_i

    , output logic [num_subcache_p-1:0][bsg_cache_dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic [num_subcache_p-1:0] dma_pkt_v_o
    , input [num_subcache_p-1:0] dma_pkt_yumi_i

    , input [num_subcache_p-1:0][dma_data_width_p-1:0] dma_data_i
    , input [num_subcache_p-1:0] dma_data_v_i
    , output logic [num_subcache_p-1:0] dma_data_ready_o
  
    , output logic [num_subcache_p-1:0][dma_data_width_p-1:0] dma_data_o
    , output logic [num_subcache_p-1:0] dma_data_v_o
    , input [num_subcache_p-1:0] dma_data_yumi_i 
  );


  localparam lg_num_subcache_lp=`BSG_SAFE_CLOG2(num_subcache_p);
  localparam data_mask_width_lp=(data_width_p>>3);
  localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp);
  localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam rfifo_els_lp=(num_subcache_p*block_size_in_words_p);
  localparam rfifo_id_width_lp=`BSG_SAFE_CLOG2(rfifo_els_lp);

  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  `declare_bsg_cache_dma_pkt_s(addr_width_p);

  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;


  // reorder fifo
  logic rfifo_alloc_v_lo;
  logic [rfifo_id_width_lp-1:0] rfifo_alloc_id_lo;
  logic rfifo_alloc_yumi_li;

  logic rfifo_write_v_li;
  logic [rfifo_id_width_lp-1:0] rfifo_write_id_li;
  logic [data_width_p-1:0] rfifo_write_data_li;

  bsg_fifo_reorder #(
    .width_p(data_width_p)
    ,.els_p(rfifo_els_lp)
  ) rfifo0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.fifo_alloc_v_o(rfifo_alloc_v_lo)
    ,.fifo_alloc_id_o(rfifo_alloc_id_lo)
    ,.fifo_alloc_yumi_i(rfifo_alloc_yumi_li)

    ,.write_v_i(rfifo_write_v_li)
    ,.write_id_i(rfifo_write_id_li)
    ,.write_data_i(rfifo_write_data_li)

    ,.fifo_deq_v_o(v_o)
    ,.fifo_deq_data_o(data_o)
    ,.fifo_deq_yumi_i(yumi_i)

    ,.empty_o()
  ); 


  // select subcache
  logic [lg_num_subcache_lp-1:0] subcache_id;
  logic [num_subcache_p-1:0] subcache_sel; 

  if (num_subcache_p == 1) begin
    assign subcache_id = 1'b0;
  end
  else begin
    assign subcache_id = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_num_subcache_lp];
  end

  bsg_decode_with_v #(
    .num_out_p(num_subcache_p)
  ) dv0 (
    .i(subcache_id)
    ,.v_i(v_i & rfifo_alloc_v_lo)
    ,.o(subcache_sel)
  );
  
  bsg_cache_pkt_s subcache_pkt;
  assign subcache_pkt.opcode = cache_pkt.opcode;
  assign subcache_pkt.data = cache_pkt.data;
  assign subcache_pkt.mask = cache_pkt.mask;
  if (num_subcache_p == 1) begin
    assign subcache_pkt.addr = cache_pkt.addr;
  end
  else begin
    assign subcache_pkt.addr = {
      {lg_num_subcache_lp{1'b0}},
      cache_pkt.addr[addr_width_p-1:lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_num_subcache_lp],
      cache_pkt.addr[0+:lg_data_mask_width_lp+lg_block_size_in_words_lp]
    };
  end
 
 
  // request fifo for each subcache
  logic [num_subcache_p-1:0] req_fifo_ready_lo;

  logic [num_subcache_p-1:0] req_fifo_v_lo;
  logic [num_subcache_p-1:0] req_fifo_yumi_li;
  logic [num_subcache_p-1:0][rfifo_id_width_lp-1:0] req_fifo_id_lo;
  bsg_cache_pkt_s [num_subcache_p-1:0] req_fifo_subcache_pkt_lo;

  for (genvar i = 0; i < num_subcache_p; i++) begin
    bsg_fifo_1r1w_small #(
      .width_p($bits(bsg_cache_pkt_s)+rfifo_id_width_lp)
      ,.els_p(block_size_in_words_p)
    ) req_fifo0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i(subcache_sel[i])
      ,.ready_o(req_fifo_ready_lo[i])
      ,.data_i({rfifo_alloc_id_lo, subcache_pkt})

      ,.v_o(req_fifo_v_lo[i])
      ,.data_o({req_fifo_id_lo[i], req_fifo_subcache_pkt_lo[i]})
      ,.yumi_i(req_fifo_yumi_li[i])
    );
  end

  assign rfifo_alloc_yumi_li = rfifo_alloc_v_lo & v_i & req_fifo_ready_lo[subcache_id];
  assign yumi_o = rfifo_alloc_v_lo & v_i & req_fifo_ready_lo[subcache_id];
    

  // instantiate subcache
  logic [num_subcache_p-1:0] subcache_ready_lo;

  logic [num_subcache_p-1:0][data_width_p-1:0] subcache_data_lo;
  logic [num_subcache_p-1:0] subcache_v_lo;
  logic [num_subcache_p-1:0] subcache_yumi_li;

  logic [num_subcache_p-1:0] subcache_v_we_lo;

  for (genvar i = 0; i < num_subcache_p; i++) begin
    bsg_cache #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
      ,.ways_p(ways_p)
      ,.dma_data_width_p(dma_data_width_p)
    ) subcache0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
    
      ,.cache_pkt_i(req_fifo_subcache_pkt_lo[i])
      ,.v_i(req_fifo_v_lo[i])
      ,.ready_o(subcache_ready_lo[i])

      ,.data_o(subcache_data_lo[i])
      ,.v_o(subcache_v_lo[i])
      ,.yumi_i(subcache_yumi_li[i])

      ,.dma_pkt_o(dma_pkt_o[i])
      ,.dma_pkt_v_o(dma_pkt_v_o[i])
      ,.dma_pkt_yumi_i(dma_pkt_yumi_i[i])

      ,.dma_data_i(dma_data_i[i])
      ,.dma_data_v_i(dma_data_v_i[i])
      ,.dma_data_ready_o(dma_data_ready_o[i])

      ,.dma_data_o(dma_data_o[i])
      ,.dma_data_v_o(dma_data_v_o[i])
      ,.dma_data_yumi_i(dma_data_yumi_i[i])

      ,.v_we_o(subcache_v_we_lo[i])
    );

    assign req_fifo_yumi_li[i] = req_fifo_v_lo[i] & subcache_ready_lo[i];
  end

  logic [num_subcache_p-1:0][rfifo_id_width_lp-1:0] tl_id_r;
  logic [num_subcache_p-1:0][rfifo_id_width_lp-1:0] tv_id_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      tl_id_r <= '0;
      tv_id_r <= '0;
    end
    else begin
      for (integer i = 0; i < num_subcache_p; i++) begin

        if (req_fifo_v_lo[i] & req_fifo_yumi_li[i]) begin
          tl_id_r[i] <= req_fifo_id_lo[i];
        end

        if (subcache_v_we_lo[i]) begin
          tv_id_r[i] <= tl_id_r[i];
        end

      end
    end
  end


  // output rr
  typedef struct packed {
    logic [rfifo_id_width_lp-1:0] id;
    logic [data_width_p-1:0] data;
  } subcache_output_s;

  subcache_output_s rr_data_lo;
  subcache_output_s [num_subcache_p-1:0] rr_data_li;
  for (genvar i = 0 ; i < num_subcache_p; i++) begin
    assign rr_data_li[i].id = tv_id_r[i];
    assign rr_data_li[i].data = subcache_data_lo[i];
  end

  bsg_round_robin_n_to_1 #(
    .width_p(data_width_p+rfifo_id_width_lp)
    ,.num_in_p(num_subcache_p)
    ,.strict_p(0)
  ) output_rr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i(rr_data_li)
    ,.v_i(subcache_v_lo)
    ,.yumi_o(subcache_yumi_li)

    ,.v_o(rfifo_write_v_li)
    ,.data_o(rr_data_lo)
    ,.tag_o()
    ,.yumi_i(rfifo_write_v_li)
  );

  assign rfifo_write_data_li = rr_data_lo.data;
  assign rfifo_write_id_li = rr_data_lo.id;


endmodule
