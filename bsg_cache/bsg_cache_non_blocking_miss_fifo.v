/**
 *    bsg_cache_non_blocking_miss_fifo.v
 *
 *    Special Miss FIFO
 *
 *    @author tommy
 *
 */



module bsg_cache_non_blocking_miss_fifo
  import bsg_cache_non_blocking_pkg::*;
  #(parameter width_p="inv"
    ,parameter els_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input [width_p-1:0] data_i
    , input v_i
    , output logic ready_o

    , output logic v_o
    , output logic [width_p-1:0] data_o
    , input yumi_i
    , input bsg_cache_non_blocking_miss_fifo_op_e yumi_op_i
    , input scan_not_dq_i // SCAN or DEQUEUE mode

    , output logic empty_o
    , input rollback_i
  );


  // localparam
  //
  localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p);
  localparam read_inc_width_lp = $clog2(els_p);


  // valid bits
  //
  logic [els_p-1:0] valid_r, valid_n;

  bsg_dff_reset #(
    .width_p(els_p)
  ) valid_dff (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(valid_n)
    ,.data_o(valid_r)
  );


  // read pointer
  //
  logic [read_inc_width_lp-1:0] read_inc;
  logic [lg_els_lp-1:0] read_ptr;
  
  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(els_p-1)
  ) read_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(read_inc)
    ,.o(read_ptr)
  );

  wire read_ptr_valid = valid_r[read_ptr];


  // write pointer
  //
  logic write_inc;
  logic [lg_els_lp-1:0] write_ptr;

  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(1)
  ) write_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(write_inc)
    ,.o(write_ptr)
  );


  // checkpoint pointer
  //
  logic cp_inc;
  logic [lg_els_lp-1:0] cp_ptr;

  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(1)
  ) cp_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(cp_inc)
    ,.o(cp_ptr)
  );

  wire cp_ptr_valid = valid_r[cp_ptr];

  // 1r1w mem
  //
  logic enque, deque;

  bsg_mem_1r1w #(
    .width_p(width_p)
    ,.els_p(els_p)
    ,.read_write_same_addr_p(0)
  ) mem_1r1w (
    .w_clk_i(clk_i)
    ,.w_reset_i(reset_i)
    
    ,.w_v_i(enque)
    ,.w_addr_i(write_ptr)
    ,.w_data_i(data_i)
  
    ,.r_v_i(read_ptr_valid)
    ,.r_addr_i(read_ptr) 
    ,.r_data_o(data_o)
  );

  
  logic inval;
  logic [els_p-1:0] inval_decode;
  logic [els_p-1:0] enque_decode;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) enque_dec (
    .i(write_ptr)
    ,.v_i(enque)
    ,.o(enque_decode)
  );

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) inval_dec (
    .i(read_ptr)
    ,.v_i(inval)
    ,.o(inval_decode)
  );

  always_comb begin
    for (integer i = 0; i < els_p; i++) begin
      if (inval_decode[i])
        valid_n[i] = 1'b0;
      else if (enque_decode[i])
        valid_n[i] = 1'b1;
      else
        valid_n[i] = valid_r[i];
    end
  end

  // FIFO logic
  //
  logic enque_r;
  logic deque_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      enque_r <= 1'b0;
      deque_r <= 1'b1;
    end
    else begin

      if (cp_inc | enque) begin
        enque_r <= enque;
      end

      if (rollback_i) begin
        deque_r <= ~cp_ptr_valid;
      end
      else begin
        if (enque | deque) begin
          deque_r <= deque;
        end
      end

    end
  end

  logic full;
  logic empty;

  assign full = enque_r & (cp_ptr == write_ptr);
  assign empty = deque_r & (read_ptr == write_ptr);

  // empty_o and v_o cannot be both high.
  assign v_o = read_ptr_valid & ~empty;
  assign empty_o = empty;
  assign ready_o = ~full;

  assign enque = ready_o & v_i;
  assign write_inc = enque; 


  always_comb begin

    deque = 1'b0;

    if (rollback_i) begin
      // only rollback when empty_o=1
      cp_inc = 1'b0;
      inval = 1'b0;
      read_inc = (cp_ptr >= read_ptr)
        ? (read_inc_width_lp)'(cp_ptr - read_ptr)
        : (read_inc_width_lp)'(els_p + cp_ptr - read_ptr);
    end
    else begin
      if (v_o) begin
        if (yumi_i) begin
          case (yumi_op_i)
            e_miss_fifo_dequeue: begin
              deque = 1'b1;
              inval = 1'b1;
              cp_inc = 1'b1;
              read_inc = (read_inc_width_lp)'(1);
            end
            e_miss_fifo_skip: begin
              deque = 1'b1;
              inval = 1'b0;
              cp_inc = 1'b0;
              read_inc = (read_inc_width_lp)'(1);
            end
            e_miss_fifo_invalidate: begin
              deque = 1'b1;
              inval = 1'b1;
              cp_inc = 1'b0;
              read_inc = (read_inc_width_lp)'(1);
            end
            default: begin
              // this should never happen.
              inval = 1'b0;
              cp_inc = 1'b0;
              read_inc = (read_inc_width_lp)'(0);
            end
          endcase
        end
        else begin
          inval = 1'b0;
          cp_inc = 1'b0;
          read_inc = (read_inc_width_lp)'(0);
        end
      end
      else begin
        inval = 1'b0;
        cp_inc = empty
          ? 1'b0
          : ~scan_not_dq_i;
        read_inc = empty
          ? (read_inc_width_lp)'(0)
          : (read_inc_width_lp)'(1);
        deque = empty
          ? 1'b0
          : 1'b1;
      end
    end
  end

endmodule
