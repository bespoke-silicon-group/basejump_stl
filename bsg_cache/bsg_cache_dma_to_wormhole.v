/**
 *    bsg_cache_dma_to_wormhole.v
 *
 *    this module interfaces cache DMA to wormhole router.
 *    when this module receives a write dma packet from the cache, it sends
 *    write header flit with evict data following.
 *    for read dma packets, it sends the read header flit, and receives the fill data asynchronously.
 */

`include "bsg_noc_links.vh"


module bsg_cache_dma_to_wormhole
  import bsg_cache_pkg::*;
  #(parameter dma_addr_width_p="inv" // cache addr width (byte addr)
    , parameter dma_burst_len_p="inv" // num of data beats in dma transfer

    // flit width should match the cache dma width.
    , parameter wh_flit_width_p="inv"
    , parameter wh_cid_width_p="inv"
    , parameter wh_len_width_p="inv"
    , parameter wh_cord_width_p="inv"

    , parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(dma_addr_width_p)
    , parameter wh_link_sif_width_lp=`bsg_ready_and_link_sif_width(wh_flit_width_p)
    , parameter dma_data_width_lp=wh_flit_width_p
  )
  (
    input clk_i
    , input reset_i

    , input [dma_pkt_width_lp-1:0] dma_pkt_i
    , input dma_pkt_v_i
    , output dma_pkt_yumi_o

    , output logic [dma_data_width_lp-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_ready_i

    , input [dma_data_width_lp-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_yumi_o

    , input  [wh_link_sif_width_lp-1:0] wh_link_sif_i
    , output [wh_link_sif_width_lp-1:0] wh_link_sif_o

    , input [wh_cord_width_p-1:0] my_wh_cord_i
    , input [wh_cord_width_p-1:0] dest_wh_cord_i
    , input [wh_cid_width_p-1:0] my_wh_cid_i
    , input [wh_cid_width_p-1:0] dest_wh_cid_i
  );

  `declare_bsg_cache_dma_pkt_s(dma_addr_width_p);
  `declare_bsg_ready_and_link_sif_s(wh_flit_width_p, wh_link_sif_s);
  wh_link_sif_s wh_link_sif_in;
  wh_link_sif_s wh_link_sif_out;
  assign wh_link_sif_in = wh_link_sif_i;
  assign wh_link_sif_o = wh_link_sif_out;

  // dma pkt fifo
  logic dma_pkt_ready_lo;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;
  bsg_cache_dma_pkt_s dma_pkt_lo;

  bsg_two_fifo #(
    .width_p(dma_pkt_width_lp)
  ) dma_pkt_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(dma_pkt_v_i)
    ,.data_i(dma_pkt_i)
    ,.ready_o(dma_pkt_ready_lo)

    ,.v_o(dma_pkt_v_lo)
    ,.data_o(dma_pkt_lo)
    ,.yumi_i(dma_pkt_yumi_li)
  );

  assign dma_pkt_yumi_o = dma_pkt_ready_lo & dma_pkt_v_i;

  // FIFO for wormhole flits coming back to vcache.
  logic return_fifo_v_lo;
  logic [wh_flit_width_p-1:0] return_fifo_data_lo;
  logic return_fifo_yumi_li;

  bsg_two_fifo #(
    .width_p(wh_flit_width_p)
  ) return_fifo (
    .clk_i      (clk_i)
    ,.reset_i   (reset_i)

    ,.v_i       (wh_link_sif_in.v)
    ,.data_i    (wh_link_sif_in.data)
    ,.ready_o   (wh_link_sif_out.ready_and_rev)

    ,.v_o       (return_fifo_v_lo)
    ,.data_o    (return_fifo_data_lo)
    ,.yumi_i    (return_fifo_yumi_li)
  );


  // counter
  localparam count_width_lp = `BSG_SAFE_CLOG2(dma_burst_len_p);
  logic send_clear_li;
  logic send_up_li;
  logic [count_width_lp-1:0] send_count_lo;

  bsg_counter_clear_up #(
    .max_val_p(dma_burst_len_p-1)
    ,.init_val_p(0)
  ) send_count (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(send_clear_li)
    ,.up_i(send_up_li)
    ,.count_o(send_count_lo)
  );

  // send FSM
  typedef enum logic [1:0] {
    SEND_RESET
    , SEND_READY
    , SEND_ADDR
    , SEND_DATA
  } send_state_e;


  send_state_e send_state_r, send_state_n;
  logic wh_flit_valid;
  logic [wh_flit_width_p-1:0] wh_flit_out;
  assign wh_link_sif_out.v = wh_flit_valid;
  assign wh_link_sif_out.data = wh_flit_out;

  `declare_bsg_cache_wh_header_flit_s(wh_flit_width_p,wh_cord_width_p,wh_len_width_p,wh_cid_width_p);

  bsg_cache_wh_header_flit_s header_flit;
  assign header_flit.unused = '0;
  assign header_flit.write_not_read = dma_pkt_lo.write_not_read;
  assign header_flit.src_cid = my_wh_cid_i;
  assign header_flit.src_cord = my_wh_cord_i;
  assign header_flit.len = dma_pkt_lo.write_not_read
    ? wh_len_width_p'(1+dma_burst_len_p)  // header + addr + data
    : wh_len_width_p'(1);  // header + addr
  assign header_flit.cord = dest_wh_cord_i;
  assign header_flit.cid = dest_wh_cid_i;


  always_comb begin

    send_state_n = send_state_r;
    dma_pkt_yumi_li = 1'b0;
    send_clear_li = 1'b0;
    send_up_li = 1'b0;
    wh_flit_valid = 1'b0;
    wh_flit_out = dma_data_i;
    dma_data_yumi_o = 1'b0;

    case (send_state_r)
      SEND_RESET: begin
        send_state_n = SEND_READY;
      end

      SEND_READY: begin
        wh_flit_out = header_flit;
        if (dma_pkt_v_lo) begin
          wh_flit_valid = 1'b1;
          send_state_n = wh_link_sif_in.ready_and_rev
            ? SEND_ADDR
            : SEND_READY;
        end
      end

      SEND_ADDR: begin
        wh_flit_out = wh_flit_width_p'(dma_pkt_lo.addr);
        if (dma_pkt_v_lo) begin
          wh_flit_valid = 1'b1;
          dma_pkt_yumi_li = wh_link_sif_in.ready_and_rev;
          send_state_n = wh_link_sif_in.ready_and_rev
            ? (dma_pkt_lo.write_not_read ? SEND_DATA : SEND_READY)
            : SEND_ADDR;
        end
      end

      SEND_DATA: begin
        wh_flit_out = dma_data_i;
        if (dma_data_v_i) begin
          wh_flit_valid = 1'b1;
          send_up_li = (send_count_lo != dma_burst_len_p-1) & wh_link_sif_in.ready_and_rev;
          send_clear_li = (send_count_lo == dma_burst_len_p-1) & wh_link_sif_in.ready_and_rev;
          dma_data_yumi_o = wh_link_sif_in.ready_and_rev;
          send_state_n = (send_count_lo == dma_burst_len_p-1) & wh_link_sif_in.ready_and_rev
            ? SEND_READY
            : SEND_DATA;
        end
      end

      // should never happen
      default: begin
        send_state_n = SEND_READY;
      end
    endcase
  end




  // receiver FSM
  logic recv_clear_li;
  logic recv_up_li;
  logic [count_width_lp-1:0] recv_count_lo;

  bsg_counter_clear_up #(
    .max_val_p(dma_burst_len_p-1)
    ,.init_val_p(0)
  ) recv_count (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(recv_clear_li)
    ,.up_i(recv_up_li)
    ,.count_o(recv_count_lo)
  );

  typedef enum logic [1:0] {
    RECV_RESET
    , RECV_READY
    , RECV_DATA
  } recv_state_e;

  recv_state_e recv_state_r, recv_state_n;


  always_comb begin
    recv_state_n = recv_state_r;
    recv_clear_li = 1'b0;
    recv_up_li = 1'b0;
    return_fifo_yumi_li = 1'b0;
    dma_data_v_o = 1'b0;
    dma_data_o = return_fifo_data_lo;

    case (recv_state_r)
      RECV_RESET: begin
        recv_state_n = RECV_READY;
      end

      RECV_READY: begin
        return_fifo_yumi_li = return_fifo_v_lo;
        recv_state_n = return_fifo_v_lo
          ? RECV_DATA
          : RECV_READY;
      end

      RECV_DATA: begin
        return_fifo_yumi_li = return_fifo_v_lo & dma_data_ready_i;
        dma_data_v_o = return_fifo_v_lo;
        recv_clear_li = return_fifo_v_lo & dma_data_ready_i & (recv_count_lo == dma_burst_len_p-1);
        recv_up_li = return_fifo_v_lo & dma_data_ready_i & (recv_count_lo != dma_burst_len_p-1);
        recv_state_n = return_fifo_v_lo & dma_data_ready_i & (recv_count_lo == dma_burst_len_p-1)
          ? RECV_READY
          : RECV_DATA;
      end

      default: begin
        recv_state_n = RECV_READY;
      end
    endcase
  end




  // sequential logic
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      send_state_r <= SEND_RESET;
      recv_state_r <= RECV_RESET;
    end
    else begin
      send_state_r <= send_state_n;
      recv_state_r <= recv_state_n;
    end
  end

  //synopsys translate_off
  if (wh_flit_width_p != dma_data_width_lp)
    $error("WH flit width must be equal to DMA data width");
  if (wh_flit_width_p < dma_addr_width_p)
    $error("WH flit width must be larger than address width");
  if (wh_len_width_p < `BSG_WIDTH(dma_burst_len_p+1))
    $error("WH len width %d must be large enough to hold the dma transfer size %d", wh_len_width_p, `BSG_WIDTH(dma_burst_len_p+1));
  //synopsys translate_on

endmodule
