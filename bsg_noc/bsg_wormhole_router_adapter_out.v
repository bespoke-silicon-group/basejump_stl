/**
 *  bsg_wormhole_router_adapter_out.v
 *
 *  packet = {payload, length, y_cord, x_cord}
 */

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
  )
  (
    input clk_i
    , input reset_i

    , input [width_lp-1:0] data_i
    , input v_i
    , output logic ready_o

    , output logic [max_packet_width_lp-1:0] data_o
    , output logic v_o
    , input ready_i
  );

  typedef enum logic [1:0] {
    WAIT_HEADER,
    WAIT_BODY,
    VALID_OUT
  } state_e;

  state_e state_r, state_n;
  logic [len_width_lp-1:0] count_r, count_n;
  logic [max_num_flit_p-1:0][width_lp-1:0] data_r;
  logic we;

  logic [padded_packet_width_lp-1:0] data_1d;
  assign data_1d = data_r;
  assign data_o = data_1d[0+:max_packet_width_lp];

  always_comb begin
    state_n = state_r;
    count_n = count_r;
    ready_o = 1'b0;
    v_o = 1'b0;
    we = 1'b0;

    case (state_r) 

      WAIT_HEADER: begin
        ready_o = 1'b1;
        if (v_i) begin
          we = 1'b1;
          count_n = count_r + 1;
          state_n = (data_i[len_offset_lp+:len_width_lp] == 0)
            ? VALID_OUT
            : WAIT_BODY;
        end
      end

      WAIT_BODY: begin
        ready_o = 1'b1;
        if (v_i) begin
          we = 1'b1;
          count_n = count_r + 1;
          state_n = (data_r[len_offset_lp+:len_width_lp] == count_r)
            ? VALID_OUT
            : WAIT_BODY;
        end
      end

      VALID_OUT: begin
        v_o = 1'b1;
        if (ready_i) begin
          state_n = WAIT_HEADER;
          count_n = '0;
        end
      end

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
        data_r[count_r] <= data_i;
      end
    end
  end

  // synopsys translate_off
  initial begin
    assert(max_num_flit_p*width_lp == padded_packet_width_lp);
    assert(width_lp > x_cord_width_p+y_cord_width_p+len_width_lp)
      else $error("width_lp has to be wider than header info width.");
  end

  always_ff @ (negedge clk_i) begin
    if ((state_r == WAIT_BODY)) begin
      assert(data_r[len_offset_lp+:len_width_lp] < max_num_flit_p)
        else $error("Received a packet with length [%0d] that exceeds max_num_flit_p [%0d].",
                    data_r[len_offset_lp+:len_width_lp], max_num_flit_p);
    end
  end
  // synopsys translate_on

endmodule
