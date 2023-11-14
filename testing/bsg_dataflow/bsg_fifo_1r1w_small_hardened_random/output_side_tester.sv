module output_side_tester
  #(width_p=32, test_els_p=100)
  (
    input clk_i
    , input reset_i

    , input v_i
    , output logic yumi_o
    , input [width_p-1:0] data_i
  );

  
  // yumi random gen
  logic ready_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      ready_r <= 1'b1;
    end
    else begin
      ready_r <= ($urandom_range(0,31) < 16);
    end
  end

  assign yumi_o = v_i & ready_r;

  always @ (posedge clk_i) begin
    if (yumi_o & v_i) begin
      //$display("[OUTPUT] data = %d", data_i);
    end
  end

  // curr data
  logic [width_p-1:0] curr_data_r;
  logic error_r;
  always @ (negedge clk_i) begin
    if (reset_i) begin
      curr_data_r <= 0;
      error_r <= 0;
    end
    else begin
      if (v_i & yumi_o) begin
        assert(curr_data_r == data_i) else begin
          $error("[Error] expected: %d, actual: %d", curr_data_r, data_i);
          error_r <= 1;
        end
        curr_data_r <= curr_data_r + 1;
      end
      if (curr_data_r == test_els_p) begin
        if (error_r) $error("\nFAIL...\n");
        else $display("\nPASS!\n");
        $finish();
      end
    end
  end
  

endmodule
