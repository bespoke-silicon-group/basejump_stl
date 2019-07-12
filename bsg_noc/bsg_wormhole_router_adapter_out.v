/**
 *  bsg_wormhole_router_adapter_out.v
 *
 *  packet = {payload, length, y_cord, x_cord}
 */

`include "bsg_noc_links.vh"

module bsg_wormhole_router_adapter_out
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

    , input [bsg_ready_and_link_sif_width_lp-1:0] link_i 
    // Used for ready_o signal, the rest should be stubbed, since this an output adapter
    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o

    , output logic [max_packet_width_lp-1:0] data_o
    , output logic v_o
    , input ready_i
  );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(width_lp,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  assign link_cast_i = link_i;
  assign link_o = link_cast_o;

  logic [width_lp-1:0] data_li;
  logic v_li, ready_lo;

  assign data_li = link_cast_i.data;
  assign v_li    = link_cast_i.v;

  assign link_cast_o.ready_and_rev = ready_lo;
  // Should be unused, stub
  assign link_cast_o.data          = '0;
  assign link_cast_o.v             = '0;

  // Logic
  typedef enum logic [1:0] {
    WAIT_HEADER,
    WAIT_BODY,
    VALID_OUT
  } state_e;

  state_e state_r, state_n;
  logic [len_width_lp-1:0] count_r, count_n;
  logic [max_num_flit_p-1:0][width_lp-1:0] data_r;
  logic we;
  logic clear;

  logic [padded_packet_width_lp-1:0] data_1d;
  assign data_1d = data_r;
  assign data_o = data_1d[0+:max_packet_width_lp];

  always_comb begin
    state_n = state_r;
    count_n = count_r;
    ready_lo = 1'b0;
    v_o = 1'b0;
    we = 1'b0;
    clear = 1'b0;

    case (state_r) 

      WAIT_HEADER: begin
        ready_lo = 1'b1;
        if (v_li) begin
          we = 1'b1;
          count_n = count_r + 1;
          state_n = (data_li[len_offset_lp+:len_width_lp] == 0)
            ? VALID_OUT
            : WAIT_BODY;
        end
      end

      WAIT_BODY: begin
        ready_lo = 1'b1;
        if (v_li) begin
          we = 1'b1;
          count_n = count_r + 1;
          state_n = (data_1d[len_offset_lp+:len_width_lp] == count_r)
            ? VALID_OUT
            : WAIT_BODY;
        end
      end

      VALID_OUT: begin
        v_o = 1'b1;
        if (ready_i) begin
          state_n = WAIT_HEADER;
          count_n = '0;
          we = 1'b1;
          clear = 1'b1;
        end
      end

      // we should never enter this state, but if we do return to reset state.
      default: begin
        state_n = WAIT_HEADER;
      end

    endcase
  end

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      state_r <= WAIT_HEADER;
      count_r <= '0;
    end
    else begin
      state_r <= state_n;
      count_r <= count_n;
      if (we) begin
        if (clear) begin
          data_r <= '0;
        end
        else begin
          data_r[count_r] <= data_li;
        end
      end
    end
  end

  // synopsys translate_off
  initial begin
    assert(max_num_flit_p*width_lp == padded_packet_width_lp)
      else $error("padding_packet_width_lp has to be equal to number of flits * flit width");
    assert(width_lp > x_cord_width_p+y_cord_width_p+len_width_lp)
      else $error("width_lp has to be wider than header info width.");
  end
  // synopsys translate_on

endmodule
