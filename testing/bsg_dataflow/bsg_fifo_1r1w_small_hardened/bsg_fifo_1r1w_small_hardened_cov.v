
module bsg_fifo_1r1w_small_hardened_cov

  #(parameter width_p = "inv"
  )

  (input clk_i
  ,input reset_i

  // interface signals
  ,input v_i
  ,input ready_o
  ,input v_o
  ,input yumi_i

  // control signals
  ,input enque
  ,input deque
  ,input full
  ,input empty
  ,input read_write_same_addr_r
  ,input read_write_same_addr_n
  );

  // reset
  covergroup cg_reset @(negedge clk_i);
    coverpoint reset_i;
  endgroup

  // interface
  covergroup cg_input_output @(negedge clk_i iff ~reset_i);

    coverpoint v_i;
    coverpoint ready_o;
    coverpoint v_o;
    coverpoint yumi_i;

    cross v_i, ready_o, v_o, yumi_i {
      ignore_bins n_v_o =
        binsof(v_o) intersect {1'b0} &&
        binsof(yumi_i) intersect {1'b1};
    }

  endgroup 

  // fifo empty
  covergroup cg_fifo_empty @ (negedge clk_i iff ~reset_i & empty & ~full);

    coverpoint enque;
    coverpoint deque;
    coverpoint read_write_same_addr_r;
    coverpoint read_write_same_addr_n;

    cross enque, deque, read_write_same_addr_r, read_write_same_addr_n {
      // cannot deque when empty
      ignore_bins ig0 =
        binsof(deque) intersect {1'b1};
      // cannot read write same address when not writing
      ignore_bins ig1 =
        binsof(enque) intersect {1'b0} &&
        binsof(read_write_same_addr_n) intersect {1'b1};
      // fifo cannot be empty if write happened in previous cycle
      ignore_bins ig2 =
        binsof(read_write_same_addr_r) intersect {1'b1};
    }

  endgroup

  // fifo full
  covergroup cg_fifo_full @ (negedge clk_i iff ~reset_i & ~empty & full);

    coverpoint enque;
    coverpoint deque;
    coverpoint read_write_same_addr_r;
    coverpoint read_write_same_addr_n;

    cross enque, deque, read_write_same_addr_r, read_write_same_addr_n {
      // cannot enque when full
      ignore_bins ig0 =
        binsof(enque) intersect {1'b1};
      // cannot read write same address when not writing
      ignore_bins ig1 =
        binsof(enque) intersect {1'b0} &&
        binsof(read_write_same_addr_n) intersect {1'b1};
      // fifo cannot be full if read happened in previous cycle
      ignore_bins ig2 =
        binsof(read_write_same_addr_r) intersect {1'b1};
    }

  endgroup

  // fifo normal
  covergroup cg_fifo_normal @ (negedge clk_i iff ~reset_i & ~empty & ~full);

    coverpoint enque;
    coverpoint deque;
    coverpoint read_write_same_addr_r;
    coverpoint read_write_same_addr_n;

    cross enque, deque, read_write_same_addr_r, read_write_same_addr_n {
      // cannot read write same address when not writing
      ignore_bins ig0 =
        binsof(enque) intersect {1'b0} &&
        binsof(read_write_same_addr_n) intersect {1'b1};
    }

  endgroup

  initial
  begin
    cg_reset reset = new;
    cg_input_output input_output = new;
    cg_fifo_empty fifo_empty = new;
    cg_fifo_full fifo_full = new;
    cg_fifo_normal fifo_normal = new;
  end

endmodule
