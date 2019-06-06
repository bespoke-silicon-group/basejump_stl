//
// Paul Gao 06/2019
//

module bsg_counter_generic

 #(parameter width_p        = "inv"
  ,parameter max_step_p     = "inv"
  ,parameter init_val_p     = "inv"
  ,parameter count_on_set_p = 0 // Just to minimize hardware
  ,localparam step_width_lp = `BSG_WIDTH(max_step_p)
  )

  (input                      clk_i
  ,input                      reset_i
  ,input                      en_i
  ,input                      set_i
  ,input  [step_width_lp-1:0] up_i
  ,input  [step_width_lp-1:0] down_i
  ,input  [width_p-1:0]       set_val_i
  ,output logic [width_p-1:0] cur_val_r_o
  );
  
  always_ff @ (posedge clk_i)
    if (reset_i)
        cur_val_r_o <= init_val_p;
    else if (en_i)
        if (set_i)
            if (count_on_set_p == 0)
                cur_val_r_o <= set_val_i;
            else
                cur_val_r_o <= set_val_i + width_p'(up_i) - width_p'(down_i);
        else
            cur_val_r_o <= cur_val_r_o + width_p'(up_i) - width_p'(down_i);

endmodule