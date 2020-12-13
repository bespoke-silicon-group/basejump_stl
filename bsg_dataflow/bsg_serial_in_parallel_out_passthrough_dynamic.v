/**
 * bsg_serial_in_parallel_out_passthrough_dynamic.v
 *
 * len_i signal must be valid when v_i and ready_and_o signals are asserted, 
 * together with the first data word of each transaction.
 *
 */

`include "bsg_defines.v"

module bsg_serial_in_parallel_out_passthrough_dynamic

 #(parameter width_p       = "inv"
  ,parameter max_els_p     = "inv"
  ,parameter lg_max_els_lp = `BSG_SAFE_CLOG2(max_els_p)
  )

  (input                               clk_i
  ,input                               reset_i

  ,input                               v_i
  ,input  [width_p-1:0]                data_i
  ,input  [lg_max_els_lp-1:0]          len_i
  ,output                              ready_and_o
  ,output                              len_ready_o

  ,output                              v_o
  ,output [max_els_p-1:0][width_p-1:0] data_o
  ,input                               ready_and_i
  );

  if (max_els_p == 1)
  begin : single_word

    assign v_o         = v_i;
    assign data_o      = data_i;
    assign ready_and_o = ready_and_i;

  end
  else
  begin : multi_word

    logic [lg_max_els_lp-1:0] count_r, len_r;
    logic is_zero_cnt, is_last_cnt, is_zero_len, is_waiting;
    logic en_li, clear_li, up_li;
    logic [max_els_p-1:0][width_p-1:0] data_lo;
    logic [max_els_p-1:0] data_en_li;

    bsg_dff_reset_en
   #(.width_p    (lg_max_els_lp)
    ,.reset_val_p(0            )
    ) len_dff
    (.clk_i      (clk_i        )
    ,.reset_i    (reset_i      )
    ,.data_i     (len_i        )
    ,.en_i       (en_li        )
    ,.data_o     (len_r        )
    );

    bsg_counter_clear_up
   #(.max_val_p (max_els_p-1)
    ,.init_val_p(0          )
    ) ctr
    (.clk_i     (clk_i      )
    ,.reset_i   (reset_i    )
    ,.clear_i   (clear_li   )
    ,.up_i      (up_li      )
    ,.count_o   (count_r    )
    );

    assign is_zero_cnt = (count_r == (lg_max_els_lp)'(0));
    assign is_last_cnt = ~is_zero_cnt & (count_r == len_r);
    assign is_waiting  = ~is_zero_cnt & (len_r == (lg_max_els_lp)'(0));
    assign is_zero_len = v_i & (len_i == (lg_max_els_lp)'(0));

    assign en_li       = v_i & ready_and_o & is_zero_cnt;
    assign up_li       = v_i & ready_and_o & ~clear_li;
    assign clear_li    = v_o & ready_and_i;

    assign v_o         = (v_i & is_last_cnt) | is_zero_len | is_waiting;
    assign ready_and_o = (ready_and_i | ~is_last_cnt) & ~is_waiting;
    assign len_ready_o = is_zero_cnt;

    bsg_decode_with_v
   #(.num_out_p(max_els_p        )
    ) bdwv
    (.i        (count_r          )
    ,.v_i      (v_i & ~is_waiting)
    ,.o        (data_en_li       )
    );

    for (genvar i = 0; i < max_els_p-1; i++)
      begin: rof
        bsg_dff_en_bypass
       #(.width_p(width_p      )
        ) data_dff
        (.clk_i  (clk_i        )
        ,.data_i (data_i       )
        ,.en_i   (data_en_li[i])
        ,.data_o (data_o    [i])
        );
      end
    assign data_o[max_els_p-1] = data_i;

  end

endmodule
