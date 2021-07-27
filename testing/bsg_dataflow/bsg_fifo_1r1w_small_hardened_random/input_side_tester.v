module input_side_tester 
  #(width_p=32, test_els_p=100)
  (
    input clk_i
    , input reset_i

    , output logic v_o
    , input ready_i
    , output logic [width_p-1:0] data_o
  );
  
  // data gen. it just increments each time data is enque'd.
  logic [width_p-1:0] data_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      data_r <= '0;
    end
    else begin
      if (v_o & ready_i) begin
        data_r <= data_r + 1;
        $display("[INPUT] data=%d",data_r);
      end
    end
  end

  assign data_o = data_r;

  // valid gen
  integer count_r;
  logic v_r;
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_r <= 1'b0;
      count_r <= 0;
    end
    else begin
      if (count_r == 0) begin
        v_r <= ~v_r;
        if (v_r)
          count_r <=  $urandom_range(0,32);
        else
          count_r <=  $urandom_range(0,4);
      end
      else begin
        count_r <= count_r - 1;
      end
    end
  end

  assign v_o = (data_r < test_els_p)
    ? v_r
    : 1'b0;


endmodule
