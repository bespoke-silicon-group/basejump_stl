/**
 *  bsg_wormhole_router_adapter_in.v
 */

module bsg_wormhole_router_adapter_in
  #(parameter width_p="inv"               // width of each flit
    , parameter max_packet_width_p="inv"  // maximum width of packet
    , parameter x_cord_width_p="inv"      
    , parameter y_cord_width_p="inv"
   
    , localparam padded_packet_width_lp=
      max_packet_width_p+(max_packet_width_p%width_p==0 ? 0 : (width_p-(max_packet_width_p%width_p)))
    , localparam max_len_lp=
      (max_packet_width_p/width_p) + (max_packet_width_p%width_p == 0 ? 0 : 1)    
    , localparam len_width_lp=`BSG_SAFE_CLOG2(max_len_lp)
  )
  (
    input clk_i
    , input reset_i

    , input [max_packet_width_p-1:0] data_i
    , input v_i
    , output logic ready_o

    , output logic [width_p-1:0] data_o
    , output logic v_o
    , input ready_i
  );

  typedef enum logic {
    WAIT,
    SEND
  } state_e;

  state_e state_r, state_n;
  logic [max_packet_width_p-1:0] data_r, data_n;
  logic [len_width_lp-1:0] count_r, count_n;


  logic [padded_packet_width_lp-1:0] padded_data;
  logic [len_width_lp-1:0] length;
  
  assign padded_data = {{(padded_packet_width_lp-max_packet_width_p){1'b0}}, data_r};
  assign length = padded_data[x_cord_width_p+y_cord_width_p+:len_width_lp];

  bsg_mux #(
    .width_p(width_p)
    ,.els_p(max_len_lp)
  ) mux (
    .data_i(padded_data)
    ,.sel_i(count_r)
    ,.data_o(data_o)
  );

  always_comb begin
    state_n = state_r;
    data_n = data_r;
    count_n = count_r;
    ready_o = 1'b0;
    v_o = 1'b0;

    case (state_r) 
      WAIT: begin
        ready_o = 1'b1;
        if (v_i) begin
          state_n = SEND;
          data_n = data_i; 
          count_n = '0;
        end
      end
      SEND: begin
        v_o = 1'b1;
        count_n = ready_i
          ? count_r + 1
          : count_r;
        state_n = ready_i & (count_r == length)
          ? WAIT
          : SEND;
      end
    endcase
  end

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      state_r <= WAIT;
    end
    else begin
      state_r <= state_n;
      data_r <= data_n;
    end
  end

endmodule
