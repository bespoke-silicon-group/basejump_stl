module bsg_nonsynth_random_yumi_gen 
  #(parameter yumi_min_delay_p="inv"
    , parameter yumi_max_delay_p="inv"
  )
  (
    input clk_i
    , input reset_i
    
    , input v_i
    , output logic yumi_o
  );


  integer yumi_count_r;
  
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      yumi_count_r <= $urandom_range(yumi_max_delay_p,yumi_min_delay_p);
    end
    else begin
      if (v_i) begin
        if (yumi_count_r == 0)
          yumi_count_r <= $urandom_range(yumi_max_delay_p,yumi_min_delay_p);
        else
          yumi_count_r <= yumi_count_r - 1;
      end
    end
  end

  assign yumi_o = v_i & (yumi_count_r == 0);
  

endmodule
