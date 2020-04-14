// take some random amount of time before taking and returning data.

module remote_node 
  #(parameter width_p="inv"
    , parameter max_delay_p="inv"
    , parameter id_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [width_p-1:0] data_i
    , output yumi_o

    , output logic v_o
    , output logic [width_p-1:0] data_o
    , input yumi_i
  );


  logic v_r;
  logic [width_p-1:0] data_r;
  integer return_count_r;
  integer take_count_r;


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      return_count_r <= $urandom(id_p+$time) % max_delay_p;
      take_count_r <= $urandom(id_p+$time) % max_delay_p;
      data_r <= '0;
      v_r <= 1'b0;
    end
    else begin
      if (v_r) begin
        return_count_r <= (return_count_r == 0)
          ? (yumi_i
            ? ($urandom(id_p+$time) % max_delay_p)
            : return_count_r)
          : return_count_r - 1;

        v_r <= (return_count_r == 0) & yumi_i
          ? 1'b0
          : v_r;
      end
      else begin
        take_count_r <= (take_count_r == 0)
          ? (v_i 
            ? ($urandom(id_p+$time) % max_delay_p)
            : take_count_r)
          : (v_i
            ? take_count_r - 1
            : take_count_r);
        data_r <= v_i & (take_count_r == 0)
          ? data_i
          : data_r;
        v_r <= v_i & (take_count_r == 0);
      end
    end
  end

  assign yumi_o = v_i & (take_count_r == 0) & ~v_r;
  assign data_o = data_r;
  assign v_o = v_r & (return_count_r == 0);

endmodule
