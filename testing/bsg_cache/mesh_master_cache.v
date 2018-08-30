/**
 *  mesh_master_cache.v
 */

`include "bsg_manycore_packet.vh"

module mesh_master_cache 
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"
    ,parameter mem_size_p="inv"
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p))
(
  input clock_i
  ,input reset_i

  ,input [link_sif_width_lp-1:0] link_sif_i
  ,output logic [link_sif_width_lp-1:0] link_sif_o

  ,input [x_cord_width_p-1:0] my_x_i
  ,input [y_cord_width_p-1:0] my_y_i
  
  ,output logic finish_o
);

  `declare_bsg_manycore_packet_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p);

  bsg_manycore_packet_s out_packet_li;
  logic out_v_li;
  logic out_ready_lo;
  logic [data_width_p-1:0] returned_data_r_lo;
  logic returned_v_r_lo;
  logic[$clog2(16+1)-1:0] out_credits_lo;
  assign out_packet_li.src_x_cord = my_x_i;
  assign out_packet_li.src_y_cord = my_y_i;
  assign out_packet_li.op_ex = 4'b1111;
  
  bsg_manycore_endpoint_standard #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.fifo_els_p(4)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
    ,.max_out_credits_p(16)
  ) dram_endpoint_standard (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    
    ,.link_sif_i(link_sif_i)
    ,.link_sif_o(link_sif_o)

    ,.in_v_o()
    ,.in_yumi_i(1'b0)
    ,.in_data_o()
    ,.in_mask_o()
    ,.in_addr_o()
    ,.in_we_o()

    ,.out_v_i(out_v_li)
    ,.out_packet_i(out_packet_li)
    ,.out_ready_o(out_ready_lo)
  
    ,.returned_data_r_o(returned_data_r_lo)
    ,.returned_v_r_o(returned_v_r_lo)

    ,.returning_data_i(data_width_p'(0))
    ,.returning_v_i(1'b0)

    ,.out_credits_o(out_credits_lo)
    ,.freeze_r_o()
    ,.reverse_arb_pr_o()

    ,.my_x_i(my_x_i)
    ,.my_y_i(my_y_i)
  );

  typedef enum logic [2:0] {
    STORE_TAG = 3'd0
    ,LOAD_TAG = 3'd1
    ,STORE_DATA = 3'd2
    ,LOAD_DATA = 3'd3
    ,SEND_DONE = 3'd4
  } send_state_e;

  typedef enum logic [2:0] {
    RECV_TAG = 3'd0
    ,RECV_DATA = 3'd1
    ,RECV_DONE = 3'd2
  } recv_state_e;

  send_state_e send_state_r, send_state_n;
  logic [31:0] send_tag_cnt_r, send_tag_cnt_n;
  logic [31:0] send_mem_cnt_r, send_mem_cnt_n;

  recv_state_e recv_state_r, recv_state_n;
  logic [31:0] recv_tag_cnt_r, recv_tag_cnt_n;
  logic [31:0] recv_mem_cnt_r, recv_mem_cnt_n;

  always_comb begin
    send_tag_cnt_n = send_tag_cnt_r;
    send_mem_cnt_n = send_mem_cnt_r;
    recv_tag_cnt_n = recv_tag_cnt_r;
    recv_mem_cnt_n = recv_mem_cnt_r;

    case (send_state_r) 
      STORE_TAG: begin
        send_state_n = (send_tag_cnt_r == ((sets_p*ways_p)-1)) & out_ready_lo
          ? LOAD_TAG
          : STORE_TAG;
        out_packet_li.op = 2'b01;
        out_packet_li.y_cord = (y_cord_width_p)'(1);
        out_packet_li.x_cord = (x_cord_width_p)'(0);
        out_packet_li.data = '0;
        out_packet_li.addr = ((addr_width_p)'(send_tag_cnt_r << 3) + (addr_width_p)'(2**25));
        out_v_li = ~reset_i;
        send_tag_cnt_n = out_ready_lo
          ? ((send_tag_cnt_r == (sets_p*ways_p-1)) ? '0 : send_tag_cnt_r + 1)
          : send_tag_cnt_r;
      end

      LOAD_TAG: begin
        send_state_n = (send_tag_cnt_r == ((sets_p*ways_p)-1)) & out_ready_lo
          ? STORE_DATA
          : LOAD_TAG;
        out_packet_li.op = 2'b00;
        out_packet_li.y_cord = (y_cord_width_p)'(1);
        out_packet_li.x_cord = (x_cord_width_p)'(0);
        out_packet_li.data = '0;
        out_packet_li.addr = (addr_width_p)'(send_tag_cnt_r << 3) + (addr_width_p)'(2**25);
        out_v_li = ~reset_i;
        send_tag_cnt_n = out_ready_lo
          ? ((send_tag_cnt_r == (sets_p*ways_p-1)) ? '0 : send_tag_cnt_r + 1)
          : send_tag_cnt_r;
      end

      STORE_DATA: begin
        send_state_n = (send_mem_cnt_r == (mem_size_p-1)) & out_ready_lo
          ? LOAD_DATA
          : STORE_DATA;
        out_packet_li.op = 2'b01;
        out_packet_li.y_cord = (y_cord_width_p)'(1);
        out_packet_li.x_cord = (x_cord_width_p)'(0);
        out_packet_li.data = send_mem_cnt_r;
        out_packet_li.addr = (addr_width_p)'(send_mem_cnt_r);
        out_v_li = ~reset_i;
        send_mem_cnt_n = out_ready_lo
          ? ((send_mem_cnt_r == (mem_size_p-1)) ? '0 : send_mem_cnt_r + 1)
          : send_mem_cnt_r;
      end

      LOAD_DATA: begin
        send_state_n = (send_mem_cnt_r == (mem_size_p-1)) & out_ready_lo
          ? SEND_DONE
          : LOAD_DATA;
        out_packet_li.op = 2'b00;
        out_packet_li.y_cord = (y_cord_width_p)'(1);
        out_packet_li.x_cord = (x_cord_width_p)'(0);
        out_packet_li.data = '0;
        out_packet_li.addr = (addr_width_p)'(send_mem_cnt_r);
        out_v_li = ~reset_i;
        send_mem_cnt_n = out_ready_lo
          ? ((send_mem_cnt_r == (mem_size_p-1)) ? '0 : send_mem_cnt_r + 1)
          : send_mem_cnt_r;
      end

      SEND_DONE: begin
        send_state_n = SEND_DONE;
        out_packet_li.op = 2'b00;
        out_packet_li.y_cord = (y_cord_width_p)'(0);
        out_packet_li.x_cord = (x_cord_width_p)'(0);
        out_packet_li.data = '0;
        out_packet_li.addr = '0;
        out_v_li = 0;
      end
    endcase

    case (recv_state_r) 
  
      RECV_TAG: begin
        recv_state_n = (recv_tag_cnt_r == (sets_p*ways_p-1)) & returned_v_r_lo
          ? RECV_DATA
          : RECV_TAG;
        recv_tag_cnt_n = returned_v_r_lo
          ? recv_tag_cnt_r + 1
          : recv_tag_cnt_r;
      end

      RECV_DATA: begin
        recv_state_n = (recv_mem_cnt_r == (mem_size_p-1)) & returned_v_r_lo
          ? RECV_DONE
          : RECV_DATA;
        recv_mem_cnt_n = returned_v_r_lo
          ? recv_mem_cnt_r + 1
          : recv_mem_cnt_r;
      end
      
      RECV_DONE: begin
        recv_state_n = RECV_DONE;
      end

    endcase

  end

  assign finish_o = (send_state_r == SEND_DONE) & (recv_state_r == RECV_DONE);

  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      send_state_r <= STORE_TAG;
      send_tag_cnt_r <= '0;
      send_mem_cnt_r <= '0;
    
      recv_state_r <= RECV_TAG;
      recv_tag_cnt_r <= '0;
      recv_mem_cnt_r <= '0;
    end
    else begin
      send_state_r <= send_state_n;
      send_tag_cnt_r <= send_tag_cnt_n;
      send_mem_cnt_r <= send_mem_cnt_n;

      recv_state_r <= recv_state_n;
      recv_tag_cnt_r <= recv_tag_cnt_n;
      recv_mem_cnt_r <= recv_mem_cnt_n;
    end
  end


  // monitor incoming and outgoing packets. 
  // synopsys translate_off
  always_ff @ (negedge clock_i) begin
    if (~reset_i & returned_v_r_lo) begin
      case (recv_state_r)
        RECV_TAG: begin
          $display("[%d] recv_tag: %d", recv_tag_cnt_r, returned_data_r_lo[2+3+:`BSG_SAFE_CLOG2(sets_p)]);
        end

        RECV_DATA: begin
          $display("[%d] recv_mem: %d", recv_mem_cnt_r, returned_data_r_lo);
        end
      endcase
    end

    /*
    if (~reset_i & out_v_li & out_ready_lo) begin
      case (send_state_r)
        STORE_TAG: begin
          $display("[%d] store tag", send_tag_cnt_r);
        end
        
        LOAD_TAG: begin
          $display("[%d] load tag", send_tag_cnt_r);
        end

        STORE_DATA: begin
          $display("[%d] store data", send_mem_cnt_r);
        end

        LOAD_DATA: begin
          $display("[%d] load data", send_mem_cnt_r);
        end

      endcase
    end
    */
  end
  // synopsys translate_on 


endmodule
