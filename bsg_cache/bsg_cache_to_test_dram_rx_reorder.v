/**
 *    bsg_cache_to_test_dram_rx_reorder.v
 *
 *    This module reorders dram data arriving out of order, and serializes them before feeding into vcache.
 *
 */


`include "bsg_defines.v"

module bsg_cache_to_test_dram_rx_reorder
  #(parameter data_width_p="inv"
    , parameter dma_data_width_p="inv"
    , parameter block_size_in_words_p="inv"
  
    , parameter dram_data_width_p="inv"
    , parameter dram_channel_addr_width_p="inv"
    
    , parameter num_req_lp = (block_size_in_words_p*data_width_p/dram_data_width_p)
    , parameter lg_num_req_lp = `BSG_SAFE_CLOG2(num_req_lp)

    , parameter dram_data_byte_offset_width_lp = `BSG_SAFE_CLOG2(dram_data_width_p>>3)
  )
  (
    
    input core_clk_i
    , input core_reset_i

    , input dram_v_i
    , input [dram_data_width_p-1:0] dram_data_i
    , input [dram_channel_addr_width_p-1:0] dram_ch_addr_i

    , output logic [dma_data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_ready_i
  );

  logic piso_ready_lo;
  logic piso_v_li;
  logic [dram_data_width_p-1:0] piso_data_li;

  bsg_parallel_in_serial_out #(
    .width_p(dma_data_width_p)
    ,.els_p(dram_data_width_p/dma_data_width_p)
  ) piso (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)
    
    ,.valid_i(piso_v_li)
    ,.data_i(piso_data_li)
    ,.ready_and_o(piso_ready_lo)

    ,.valid_o(dma_data_v_o)
    ,.data_o(dma_data_o)
    ,.yumi_i(dma_data_v_o & dma_data_ready_i)
  );
  
  if (num_req_lp == 1) begin: req1

    // if there is only one DRAM request, there is no need to reorder.
    assign piso_data_li = dram_data_i;
    assign piso_v_li = dram_v_i;
    wire unused = |dram_ch_addr_i; 

    // synopsys translate_off 
    always_ff @ (negedge core_clk_i) begin
      if (~core_reset_i & dram_v_i) begin
        assert(piso_ready_lo) else $fatal("piso is not ready!");
      end
    end
    // synopsys translate_on

  end
  else begin: reqn

    // reordering logic 
    // when the data arrives during its turn, go into the piso, if the piso is ready. Then, increment the counter.
    // If the piso is not ready, then go into the buffer.
    // If the piso is ready, and the data is available in the buffer, put that in piso and increment the counter.
    // when the data arrives and it's not its turn, then wait in the buffer.

    wire [lg_num_req_lp-1:0] req_num = dram_ch_addr_i[dram_data_byte_offset_width_lp+:lg_num_req_lp];

    // data that is not ready to go into piso is buffered here.
    logic [dram_data_width_p-1:0] data_buffer_r [num_req_lp-1:0];
    logic [num_req_lp-1:0] data_buffer_v_r;
    
    logic counter_clear;
    logic counter_up;
    logic [lg_num_req_lp-1:0] count_r;

    // this counts the number of DRAM data that have arrived and been fed into the piso.
    // the data is fed into the piso sequentially in address order. 
    bsg_counter_clear_up #(
      .max_val_p(num_req_lp-1)
      ,.init_val_p(0)
    ) c0 (
      .clk_i(core_clk_i)
      ,.reset_i(core_reset_i)

      ,.clear_i(counter_clear)
      ,.up_i(counter_up)

      ,.count_o(count_r)
    );

    logic clear_buffer;
    logic write_buffer;

    always_comb begin

      piso_v_li = 1'b0;
      piso_data_li = dram_data_i;
      counter_clear = 1'b0;
      counter_up = 1'b0;
      clear_buffer = 1'b0;
      write_buffer = 1'b0;
   
      if (count_r == num_req_lp-1) begin
        piso_v_li = data_buffer_v_r[count_r] | ((req_num == count_r) & dram_v_i);
        piso_data_li = data_buffer_v_r[count_r]
          ? data_buffer_r[count_r]
          : dram_data_i;
        counter_clear = piso_ready_lo & (data_buffer_v_r[count_r] | ((req_num == count_r) & dram_v_i));
        write_buffer = ~piso_ready_lo & dram_v_i;
        clear_buffer = piso_ready_lo & (data_buffer_v_r[count_r] | ((req_num == count_r) & dram_v_i));
      end
      else begin
        piso_v_li = data_buffer_v_r[count_r] | ((req_num == count_r) & dram_v_i);
        piso_data_li = data_buffer_v_r[count_r]
          ? data_buffer_r[count_r]
          : dram_data_i;
        counter_up = piso_ready_lo & (data_buffer_v_r[count_r] | ((req_num == count_r) & dram_v_i));
        write_buffer = (dram_v_i & ((req_num != count_r) | ~piso_ready_lo));
      end

    end

    always_ff @ (posedge core_clk_i) begin
      if (core_reset_i) begin
        data_buffer_v_r <= '0;
      end
      else begin
        if (clear_buffer) begin
          data_buffer_v_r <= '0;
        end
        else if (write_buffer) begin
          data_buffer_v_r[req_num] <= 1'b1;
          data_buffer_r[req_num] <= dram_data_i;
        end
      end
    end

  end


endmodule
