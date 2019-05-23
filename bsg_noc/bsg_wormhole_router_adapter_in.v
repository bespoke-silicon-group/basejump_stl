/**
 *  bsg_wormhole_router_adapter_in.v
 *
 *  packet = {payload, length, y_cord, x_cord}
 */

`include "bsg_noc_links.vh"

module bsg_wormhole_router_adapter_in
  #(parameter max_num_flit_p="inv"
    , parameter max_payload_width_p="inv"
    , parameter x_cord_width_p="inv"      
    , parameter y_cord_width_p="inv"

    , localparam len_width_lp=`BSG_SAFE_CLOG2(max_num_flit_p)
    , localparam max_packet_width_lp=(x_cord_width_p+y_cord_width_p+len_width_lp+max_payload_width_p)
    , localparam width_lp=
      (max_packet_width_lp/max_num_flit_p) + ((max_packet_width_lp%max_num_flit_p) == 0 ? 0 : 1)
 
    , localparam padding_width_lp= 
      ((max_packet_width_lp%width_lp) == 0 ? 0 : (width_lp-(max_packet_width_lp%width_lp)))
    , localparam padded_packet_width_lp=
      max_packet_width_lp+padding_width_lp
    , localparam len_offset_lp=(x_cord_width_p+y_cord_width_p)

    , localparam bsg_ready_and_link_sif_width_lp=`bsg_ready_and_link_sif_width(width_lp)
  )
  (
    input clk_i
    , input reset_i

    , input [max_packet_width_lp-1:0] data_i
    , input v_i
    , output logic ready_o

    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o
    // Used for ready_i signal, the rest should be stubbed, since this an input adapter
    , input [bsg_ready_and_link_sif_width_lp-1:0] link_i 
  );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(width_lp,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  assign link_cast_i = link_i;
  assign link_o = link_cast_o;

  logic [width_lp-1:0] data_lo;
  logic v_lo, ready_li;

  assign link_cast_o.data = data_lo;
  assign link_cast_o.v    = v_lo;
  assign ready_li         = link_cast_i.ready_and_rev;

  assign link_cast_o.ready_and_rev = 1'b0;

  // Logic 
  typedef enum logic {
    WAIT,
    SEND
  } state_e;

  state_e state_r, state_n;
  logic [len_width_lp-1:0] count_r, count_n;

  logic [padded_packet_width_lp-1:0] padded_data;
  logic [len_width_lp-1:0] length;
  
  assign padded_data = {{padding_width_lp{1'b0}}, data_i};
  assign length = padded_data[len_offset_lp+:len_width_lp];

  bsg_mux #(
    .width_p(width_lp)
    ,.els_p(max_num_flit_p)
  ) mux (
    .data_i(padded_data)
    ,.sel_i(count_r)
    ,.data_o(data_lo)
  );

  always_comb begin
    state_n = state_r;
    count_n = count_r;
    ready_o = 1'b0;
    v_lo = 1'b0;

    case (state_r) 
      WAIT: begin
        if (v_i) begin
          state_n = SEND;
          count_n = '0;
        end
      end
      SEND: begin
        v_lo = 1'b1;
        count_n = ready_li
          ? count_r + 1
          : count_r;
        ready_o = ready_li & (count_r == length);
        state_n = ready_li & (count_r == length)
          ? WAIT
          : SEND;
      end
    endcase
  end

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      state_r <= WAIT;
      count_r <= '0;
    end
    else begin
      state_r <= state_n;
      count_r <= count_n;
    end
  end

  // synopsys translate_off
  initial begin
    assert(max_num_flit_p*width_lp == padded_packet_width_lp)
      else $error("padding_packet_width_lp has to be equal to number of flits * flit width");
    assert(width_lp > x_cord_width_p+y_cord_width_p+len_width_lp)
      else $error("width_lp has to be wider than header info width.");
  end

  always_ff @ (negedge clk_i) begin
    if ((state_r == SEND)) begin
      assert(length < max_num_flit_p)
        else $error("Received a packet with length [%0d] that exceeds max_num_flit_p [%0d].", length, max_num_flit_p);
    end
  end
  // synopsys translate_on

endmodule
