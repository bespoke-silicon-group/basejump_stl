/**
 *  bsg_cache_to_dram_ctrl.v
 *
 *  @author Tommy Jung
 *
 *  @param addr_width_p address width. (byte addressing)
 *  @param block_size_in_words_p number of words in cache block.
 *  @param cache_word_width_p bit-width of words in cache.
 *  @param burst_len_p number of bursts per request.
 *  @param burst_width_p bit-width of burst data.
 */


module bsg_cache_to_dram_ctrl
  import bsg_dram_ctrl_pkg::*;
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter cache_word_width_p="inv"
    ,parameter burst_len_p="inv"
    ,parameter burst_width_p="inv"
    ,parameter data_width_ratio_lp=burst_width_p/cache_word_width_p
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter num_req_lp=(cache_word_width_p*block_size_in_words_p)/(burst_width_p*burst_len_p)
    ,parameter block_offset_width_lp=`BSG_SAFE_CLOG2(cache_word_width_p*block_size_in_words_p/8))
(
  input clock_i
  ,input reset_i

  // DMA request channel
  ,input dma_req_ch_write_not_read_i
  ,input [addr_width_p-1:0] dma_req_ch_addr_i
  ,input dma_req_ch_v_i
  ,output logic dma_req_ch_yumi_o

  // DMA read channel (fill)
  ,output logic  [cache_word_width_p-1:0] dma_read_ch_data_o
  ,output logic dma_read_ch_v_o
  ,input dma_read_ch_ready_i

  // DMA write channel (evict)
  ,input [cache_word_width_p-1:0] dma_write_ch_data_i
  ,input dma_write_ch_v_i
  ,output logic dma_write_ch_yumi_o

  // interface with DRAM ctrl
  ,bsg_dram_ctrl_if.master dram_ctrl_if
);

  // read channel
  //
  typedef enum logic {
    RD_REQ_IDLE = 1'b0
    ,RD_REQ_SEND = 1'b1
  } rd_ch_state_e;

  // write channel
  //
  typedef enum logic {
    WR_REQ_IDLE = 1'b0
    ,WR_REQ_SEND = 1'b1
  } wr_req_state_e;

  logic rd_req_valid;
  logic [1:0] rd_ch_state_r, rd_ch_state_n;
  logic [addr_width_p-1:0] rd_addr_r, rd_addr_n;
  logic [`BSG_SAFE_CLOG2(num_req_lp)-1:0] rd_ch_req_cnt_r, rd_ch_req_cnt_n;

  logic wr_req_valid;
  logic wr_ch_state_r, wr_ch_state_n;
  logic [addr_width_p-1:0] wr_addr_r, wr_addr_n;
  logic [`BSG_SAFE_CLOG2(num_req_lp)-1:0] wr_ch_req_cnt_r, wr_ch_req_cnt_n;
  logic [`BSG_SAFE_CLOG2(burst_len_p)-1:0] wr_ch_burst_cnt_r, wr_ch_burst_cnt_n;

  logic [1:0] req_ch_rr_v_li;
  logic [1:0] req_ch_rr_yumi_lo;
  logic req_ch_rr_v_lo;
  logic [addr_width_p-1:0] req_ch_rr_data_lo;
  logic req_ch_rr_tag_lo;
  logic req_ch_rr_yumi_li;
  logic [addr_width_p-1:0] dma_req_ch_block_addr;

  logic wr_sipo_ready_lo;
  logic [data_width_ratio_lp-1:0] wr_sipo_valid_lo;
  logic [burst_width_p-1:0] wr_sipo_data_lo;
  logic [`BSG_SAFE_CLOG2(data_width_ratio_lp+1)-1:0] wr_sipo_yumi_cnt_li;
  logic dram_wren;

  logic rd_fifo_v_lo;
  logic [burst_width_p-1:0] rd_fifo_data_lo;
  logic rd_fifo_yumi_li;

  logic rd_piso_ready_lo;
  logic rd_piso_yumi_li;
  logic rd_piso_valid_lo;

  // request channel round robin
  //
  bsg_round_robin_n_to_1 #(
    .width_p(addr_width_p)
    ,.num_in_p(2)
    ,.strict_p(0)
  ) req_ch_round_robin_n_1 (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.data_i({wr_addr_r, rd_addr_r})
    ,.v_i(req_ch_rr_v_li)
    ,.yumi_o(req_ch_rr_yumi_lo)
    ,.v_o(req_ch_rr_v_lo)
    ,.data_o(req_ch_rr_data_lo)
    ,.tag_o(req_ch_rr_tag_lo)
    ,.yumi_i(req_ch_rr_yumi_li)
  );

  assign req_ch_rr_yumi_li = req_ch_rr_v_lo & dram_ctrl_if.app_rdy;


  // write data serial_in_parallel_out
  //
  bsg_serial_in_parallel_out #(
    .width_p(cache_word_width_p)
    ,.els_p(data_width_ratio_lp)
  ) wr_data_sipo (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.valid_i(dma_write_ch_v_i)
    ,.data_i(dma_write_ch_data_i)
    ,.ready_o(wr_sipo_ready_lo)
    ,.valid_o(wr_sipo_valid_lo)
    ,.data_o(wr_sipo_data_lo)
    ,.yumi_cnt_i(wr_sipo_yumi_cnt_li)
  );
  
  assign wr_sipo_yumi_cnt_li = (dram_ctrl_if.app_wdf_rdy & dram_wren)
    ? (`BSG_SAFE_CLOG2(data_width_ratio_lp+1))'(data_width_ratio_lp)
    : '0;


  //  read data fifo
  //  we have a fifo with depth of burst length, since rd channel does not have ready signal,
  //  and it must be able to sink data when it's valid.
  //  otherwise, data is lost.
  //
  bsg_fifo_1r1w_large #(
    .width_p(burst_width_p)
    ,.els_p(burst_len_p == 1 ? 2 : burst_len_p)
  ) rd_fifo_sink (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.data_i(dram_ctrl_if.app_rd_data)
    ,.v_i(dram_ctrl_if.app_rd_data_valid)
    ,.ready_o()
    ,.v_o(rd_fifo_v_lo)
    ,.data_o(rd_fifo_data_lo)
    ,.yumi_i(rd_fifo_yumi_li)
  );
    
  assign rd_fifo_yumi_li = rd_fifo_v_lo & rd_piso_ready_lo;


  //  read data parallel_in_serial_out
  //
  bsg_parallel_in_serial_out #(
    .width_p(cache_word_width_p)
    ,.els_p(data_width_ratio_lp)
  ) rd_data_piso (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.valid_i(rd_fifo_v_lo)
    ,.data_i(rd_fifo_data_lo)
    ,.ready_o(rd_piso_ready_lo)
    ,.valid_o(rd_piso_valid_lo)
    ,.data_o(dma_read_ch_data_o)
    ,.yumi_i(rd_piso_yumi_li)
  );
  
  assign rd_piso_yumi_li = rd_piso_valid_lo & dma_read_ch_ready_i;


  // dram_ctrl_if request
  //
  assign dram_ctrl_if.app_en = req_ch_rr_v_lo;
  assign dram_ctrl_if.app_cmd = req_ch_rr_tag_lo ? eAppWrite : eAppRead;
  assign dram_ctrl_if.app_hi_pri = 1'b1;
  assign dram_ctrl_if.app_addr = req_ch_rr_data_lo;

  // dram_ctrl_if write
  //
  assign dram_wren = &wr_sipo_valid_lo;
  assign dram_ctrl_if.app_wdf_wren = dram_wren;
  assign dram_ctrl_if.app_wdf_mask = '0;
  assign dram_ctrl_if.app_wdf_data = wr_sipo_data_lo;
  assign dram_ctrl_if.app_wdf_end = dram_wren & (wr_ch_burst_cnt_r == (burst_len_p-1));

  // dram_ctrl_if misc
  //
  assign dram_ctrl_if.app_ref_req = 1'b0; 
  assign dram_ctrl_if.app_zq_req = 1'b0; 
  assign dram_ctrl_if.app_sr_req = 1'b0; 

  assign dma_req_ch_yumi_o = dma_req_ch_v_i &
    ((dma_req_ch_write_not_read_i & (wr_ch_state_r == WR_REQ_IDLE))
      | (~dma_req_ch_write_not_read_i & (rd_ch_state_r == RD_REQ_IDLE)));

  assign dma_read_ch_v_o = rd_piso_valid_lo;
  assign dma_write_ch_yumi_o = dma_write_ch_v_i & wr_sipo_ready_lo;

  assign rd_req_valid = ~dma_req_ch_write_not_read_i & dma_req_ch_v_i; 
  assign wr_req_valid = dma_req_ch_write_not_read_i & dma_req_ch_v_i;

  assign dma_req_ch_block_addr = {
    dma_req_ch_addr_i[addr_width_p-1:block_offset_width_lp], (block_offset_width_lp)'(0)
  };


  // next state logic
  //
  always_comb begin
    case (wr_ch_state_r)
      WR_REQ_IDLE: begin
        req_ch_rr_v_li[1] = 1'b0;
        wr_ch_state_n = wr_req_valid
          ? WR_REQ_SEND
          : WR_REQ_IDLE;
        wr_addr_n = wr_req_valid
          ? dma_req_ch_block_addr
          : wr_addr_r;
        wr_ch_req_cnt_n = wr_req_valid
          ? '0
          : wr_ch_req_cnt_r ;
      end
    
      WR_REQ_SEND: begin
        req_ch_rr_v_li[1] = 1'b1;
        wr_ch_state_n = req_ch_rr_yumi_lo[1] & (wr_ch_req_cnt_r == (num_req_lp-1))
          ? WR_REQ_IDLE
          : WR_REQ_SEND;
        wr_ch_req_cnt_n = req_ch_rr_yumi_lo[1]
          ? wr_ch_req_cnt_r + 1
          : wr_ch_req_cnt_r;
        wr_addr_n = req_ch_rr_yumi_lo[1]
          ? wr_addr_r + (1 << `BSG_SAFE_CLOG2(burst_width_p*burst_len_p/8))
          : wr_addr_r;
        end
    endcase
    
    wr_ch_burst_cnt_n = dram_ctrl_if.app_wdf_rdy & dram_ctrl_if.app_wdf_wren
      ? (wr_ch_burst_cnt_r == (burst_len_p-1) ? '0 : wr_ch_burst_cnt_r + 1)
      : wr_ch_burst_cnt_r;

    
    case (rd_ch_state_r)
      RD_REQ_IDLE: begin
        req_ch_rr_v_li[0] = 1'b0;
        rd_ch_state_n = rd_req_valid
          ? RD_REQ_SEND
          : RD_REQ_IDLE;
        rd_addr_n = rd_req_valid
          ? dma_req_ch_block_addr
          : rd_addr_r;
        rd_ch_req_cnt_n = rd_req_valid
          ? '0 
          : rd_ch_req_cnt_r;
      end
      
      RD_REQ_SEND: begin
        req_ch_rr_v_li[0] = 1'b1;
        rd_ch_state_n = req_ch_rr_yumi_lo[0] & (rd_ch_req_cnt_r == (num_req_lp-1))
          ? RD_REQ_IDLE
          : RD_REQ_SEND;
        rd_ch_req_cnt_n = req_ch_rr_yumi_lo[0]
          ? rd_ch_req_cnt_r + 1 
          : rd_ch_req_cnt_r;
        rd_addr_n = req_ch_rr_yumi_lo[0]
          ? rd_addr_r + (1 << `BSG_SAFE_CLOG2(burst_width_p*burst_len_p/8))
          : rd_addr_r;
      end
    endcase
  end


  // sequential
  //
  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      rd_ch_state_r <= RD_REQ_IDLE;
      rd_addr_r <= '0;
      rd_ch_req_cnt_r <= '0;
      wr_ch_state_r <= WR_REQ_IDLE;
      wr_addr_r <= '0;
      wr_ch_req_cnt_r <= '0;
      wr_ch_burst_cnt_r <= '0;
    end
    else begin
      rd_ch_state_r <= rd_ch_state_n;
      rd_addr_r <= rd_addr_n;
      rd_ch_req_cnt_r <= rd_ch_req_cnt_n;
      wr_ch_state_r <= wr_ch_state_n;
      wr_addr_r <= wr_addr_n;
      wr_ch_req_cnt_r <= wr_ch_req_cnt_n;
      wr_ch_burst_cnt_r <= wr_ch_burst_cnt_n;
    end
  end

endmodule
