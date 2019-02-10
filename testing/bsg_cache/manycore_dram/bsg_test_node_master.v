/**
 *  bsg_test_node_master.v
 */

`include "bsg_manycore_packet.vh"

module bsg_test_node_master
  #(parameter id_p="inv"
    ,parameter link_addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter sets_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter load_id_width_p="inv"
    ,parameter num_test_word_p="inv"

    ,parameter ways_p=2

    ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
    ,parameter lg_num_test_word_lp=`BSG_SAFE_CLOG2(num_test_word_p)
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter link_sif_width_lp=
    `bsg_manycore_link_sif_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input [link_sif_width_lp-1:0] link_sif_i
    ,output logic [link_sif_width_lp-1:0] link_sif_o

    ,output logic done_o
  );

  `declare_bsg_manycore_packet_s(link_addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p, load_id_width_p);
  bsg_manycore_packet_s out_packet_li;
  logic out_v_li;
  logic out_ready_lo;

  logic [data_width_p-1:0] returned_data_r_lo;
  logic returned_v_r_lo;
  logic returned_yumi_li;
  
  bsg_manycore_endpoint_standard #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(link_addr_width_p)
    ,.fifo_els_p(4)
    ,.max_out_credits_p(16)
    ,.load_id_width_p(load_id_width_p)
  ) dram_endpoint_standard (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.link_sif_i(link_sif_i)
    ,.link_sif_o(link_sif_o)

    ,.in_v_o()
    ,.in_yumi_i(1'b0)
    ,.in_data_o()
    ,.in_mask_o()
    ,.in_addr_o()
    ,.in_we_o()
    ,.in_src_x_cord_o()
    ,.in_src_y_cord_o()

    ,.returning_data_i('0)
    ,.returning_v_i(1'b0)

    ,.out_v_i(out_v_li)
    ,.out_packet_i(out_packet_li)
    ,.out_ready_o(out_ready_lo)
  
    ,.returned_data_r_o(returned_data_r_lo)
    ,.returned_load_id_r_o()
    ,.returned_v_r_o(returned_v_r_lo)
    ,.returned_fifo_full_o()
    ,.returned_yumi_i(returned_yumi_li)

    ,.out_credits_o()

    ,.my_x_i((x_cord_width_p)'(id_p))
    ,.my_y_i((y_cord_width_p)'(0))
  );

  assign out_packet_li.src_x_cord = (x_cord_width_p)'(id_p);
  assign out_packet_li.src_y_cord = (y_cord_width_p)'(0);
  assign out_packet_li.x_cord = (x_cord_width_p)'(id_p);  // dest x cord
  assign out_packet_li.y_cord = (y_cord_width_p)'(1);     // dest y cord
  assign out_packet_li.op_ex = 4'b1111; // store mask

  typedef enum logic [2:0] {
    STORE_DATA
    ,LOAD_DATA
    ,SEND_DONE
  } send_state_e;

  typedef enum logic [2:0] {
    RECV_DATA
    ,RECV_DONE
  } recv_state_e;

  send_state_e send_state_r, send_state_n;
  logic [lg_num_test_word_lp-1:0] send_mem_cnt_r, send_mem_cnt_n;

  recv_state_e recv_state_r, recv_state_n;
  logic [lg_num_test_word_lp-1:0] recv_mem_cnt_r, recv_mem_cnt_n;

  always_comb begin
    send_mem_cnt_n = send_mem_cnt_r;
    out_packet_li.addr = '0;
  
    case (send_state_r) 
      STORE_DATA: begin
        send_state_n = (send_mem_cnt_r == num_test_word_p-1) & out_ready_lo
          ? LOAD_DATA
          : STORE_DATA;
        out_packet_li.op = 2'b01;
        out_packet_li.payload = send_mem_cnt_r + (id_p << lg_num_test_word_lp);
        out_packet_li.addr = (link_addr_width_p)'(send_mem_cnt_r);
        out_v_li = ~reset_i;
        send_mem_cnt_n = out_ready_lo
          ? ((send_mem_cnt_r == (num_test_word_p-1)) ? '0 : send_mem_cnt_r + 1)
          : send_mem_cnt_r;
      end

      LOAD_DATA: begin
        send_state_n = (send_mem_cnt_r == (num_test_word_p-1)) & out_ready_lo
          ? SEND_DONE
          : LOAD_DATA;
        out_packet_li.op = 2'b00;
        out_packet_li.payload = '0;
        out_packet_li.addr = (link_addr_width_p)'(send_mem_cnt_r);
        out_v_li = ~reset_i;
        send_mem_cnt_n = out_ready_lo
          ? ((send_mem_cnt_r == (num_test_word_p-1)) ? '0 : send_mem_cnt_r + 1)
          : send_mem_cnt_r;
      end

      SEND_DONE: begin
        send_state_n = SEND_DONE;
        out_packet_li.op = 2'b00;
        out_packet_li.payload = '0;
        out_packet_li.addr = '0;
        out_v_li = 0;
      end
    endcase

  end
  
  // receiver
  //
  always_comb begin
    recv_mem_cnt_n = recv_mem_cnt_r;
    returned_yumi_li = 1'b0;

    case (recv_state_r) 
      RECV_DATA: begin
        recv_state_n = (recv_mem_cnt_r == (num_test_word_p-1)) & returned_v_r_lo
          ? RECV_DONE
          : RECV_DATA;
        recv_mem_cnt_n = returned_v_r_lo
          ? recv_mem_cnt_r + 1
          : recv_mem_cnt_r;
        returned_yumi_li = returned_v_r_lo;
      end
      RECV_DONE: begin
        recv_state_n = RECV_DONE;
      end
    endcase
  end

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      send_state_r <= STORE_DATA;
      send_mem_cnt_r <= '0;
    
      recv_state_r <= RECV_DATA;
      recv_mem_cnt_r <= '0;
    end
    else begin
      send_state_r <= send_state_n;
      send_mem_cnt_r <= send_mem_cnt_n;

      recv_state_r <= recv_state_n;
      recv_mem_cnt_r <= recv_mem_cnt_n;
    end
  end


  // monitor incoming packets. 
  //
  always_ff @ (negedge clk_i) begin
    if (~reset_i & returned_v_r_lo) begin
      case (recv_state_r)
        RECV_DATA: begin
          if ((32)'(recv_mem_cnt_r) + (id_p << lg_num_test_word_lp) == returned_data_r_lo) begin
            $display("[%0d] recv_mem. expected: %d, actual: %d",
              id_p,
              (32)'(recv_mem_cnt_r) + (id_p << lg_num_test_word_lp),
              returned_data_r_lo);
          end
          else begin
            $display("[%0d] recv_mem. expected: %d, actual: %d (NOT MATCHED)",
              id_p,
              (32)'(recv_mem_cnt_r) + (id_p << lg_num_test_word_lp),
              returned_data_r_lo);
          end
        end
      endcase
    end
  end

  assign done_o = (send_state_r == SEND_DONE) & (recv_state_r == RECV_DONE);

endmodule
