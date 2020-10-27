/**
 *    bsg_cache_non_blocking_miss_fifo.v
 *
 *    Special Miss FIFO
 *
 *    @author tommy
 *
 */


`include "bsg_defines.v"

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
  localparam rptr_inc_width_lp = $clog2(els_p);


  // valid bits array
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
  logic [rptr_inc_width_lp-1:0] rptr_inc;
  logic [lg_els_lp-1:0] rptr_r, rptr_n;
  
  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(els_p-1)
  ) read_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(rptr_inc)
    ,.o(rptr_r)
    ,.n_o(rptr_n)
  );

  wire [lg_els_lp-1:0] rptr_plus1 = (els_p-1 == rptr_r)
    ? (lg_els_lp)'(0)
    : (lg_els_lp)'(rptr_r+1);

  wire [lg_els_lp-1:0] rptr_plus2 = (els_p-1 == rptr_plus1)
    ? (lg_els_lp)'(0)
    : (lg_els_lp)'(rptr_plus1+1);

  // write pointer
  //
  logic wptr_inc;
  logic [lg_els_lp-1:0] wptr_r;

  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(1)
  ) write_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(wptr_inc)
    ,.o(wptr_r)
    ,.n_o()
  );

  // checkpoint pointer
  //
  logic cptr_inc;
  logic [lg_els_lp-1:0] cptr_r;

  bsg_circular_ptr #(
    .slots_p(els_p)
    ,.max_add_p(1)
  ) cp_ptr0 (
    .clk(clk_i)
    ,.reset_i(reset_i)
    ,.add_i(cptr_inc)
    ,.o(cptr_r)
    ,.n_o()
  );

  wire rptr_valid = valid_r[rptr_r];
  wire rptr_plus1_valid = valid_r[rptr_plus1];
  wire rptr_plus2_valid = valid_r[rptr_plus2];
  wire cptr_valid = valid_r[cptr_r];
  wire read_write_same_addr = (rptr_n == wptr_r);

  // 1r1w mem
  //
  logic enque, deque;
  logic mem_read_en;
  logic [width_p-1:0] mem_data_lo;
  logic [lg_els_lp-1:0] mem_read_addr;

  bsg_mem_1r1w_sync #(
    .width_p(width_p)
    ,.els_p(els_p)
    ,.harden_p(1)
    ,.read_write_same_addr_p(0)
    ,.disable_collision_warning_p(0)
  ) mem_1r1w (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.w_v_i(enque)
    ,.w_addr_i(wptr_r)
    ,.w_data_i(data_i)
  
    ,.r_v_i(mem_read_en)
    ,.r_addr_i(mem_read_addr) 
    ,.r_data_o(mem_data_lo)
  );

  logic mem_read_en_r;
  logic [lg_els_lp-1:0] mem_read_addr_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      mem_read_en_r <= 1'b0;
      mem_read_addr_r <= '0;
    end
    else begin
      mem_read_en_r <= mem_read_en;
      if (mem_read_en)
        mem_read_addr_r <= mem_read_addr;      
    end
  end

  logic [width_p-1:0] data_r, data_n;
  logic v_r, v_n;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      data_r <= '0;
      v_r <= 1'b0;
    end
    else begin
      data_r <= data_n;
      v_r <= v_n;
    end
  end
 
  assign v_o = v_r;
  assign data_o = data_r; 
 
  // next state logic for valid bit array
  //
  logic inval;
  logic [els_p-1:0] inval_decode;
  logic [els_p-1:0] enque_decode;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) enque_dec (
    .i(wptr_r)
    ,.v_i(enque)
    ,.o(enque_decode)
  );

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) inval_dec (
    .i(rptr_r)
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

      if (cptr_inc | enque) begin
        enque_r <= enque;
      end

      if (rollback_i) begin
        deque_r <= ~cptr_valid;
      end
      else begin
        if (enque | deque) begin
          deque_r <= deque;
        end
      end

    end
  end

  wire full = enque_r & (cptr_r == wptr_r);
  wire empty = deque_r & (rptr_r == wptr_r);

  assign empty_o = empty;
  assign ready_o = ~full;

  assign enque = ready_o & v_i;
  assign wptr_inc = enque; 


  always_comb begin


    if (rollback_i) begin
      // only rollback when empty_o=1
      deque = 1'b0;
      cptr_inc = 1'b0;
      inval = 1'b0;
      rptr_inc = (cptr_r >= rptr_r)
        ? (rptr_inc_width_lp)'(cptr_r - rptr_r)
        : (rptr_inc_width_lp)'(els_p + cptr_r - rptr_r);

      mem_read_en = cptr_valid;
      mem_read_addr = rptr_n; 
      v_n = v_r;
      data_n = data_r;
      
    end
    else begin
      // output valid
      if (v_r) begin
        // output taken
        if (yumi_i) begin

          mem_read_addr = ((rptr_n == mem_read_addr_r) & mem_read_en_r)
            ? rptr_plus2
            : rptr_plus1;
          mem_read_en = ~read_write_same_addr & ((rptr_n == mem_read_addr_r) & mem_read_en_r
            ? rptr_plus2_valid
            : rptr_plus1_valid);

          v_n = read_write_same_addr
            ? enque
            : mem_read_en_r;
          data_n = read_write_same_addr
            ? (enque ? data_i : data_r)
            : (mem_read_en_r ? mem_data_lo : data_r);

          case (yumi_op_i)
            e_miss_fifo_dequeue: begin
              deque = 1'b1;
              inval = 1'b1;
              cptr_inc = 1'b1;
              rptr_inc = (rptr_inc_width_lp)'(1);

            end
            e_miss_fifo_skip: begin
              deque = 1'b1;
              inval = 1'b0;
              cptr_inc = 1'b0;
              rptr_inc = (rptr_inc_width_lp)'(1);
            end
            e_miss_fifo_invalidate: begin
              deque = 1'b1;
              inval = 1'b1;
              cptr_inc = 1'b0;
              rptr_inc = (rptr_inc_width_lp)'(1);
            end
            default: begin
              // this should never happen.
              deque = 1'b0;
              inval = 1'b0;
              cptr_inc = 1'b0;
              rptr_inc = (rptr_inc_width_lp)'(0);

              mem_read_en = 1'b0;
              mem_read_addr = (lg_els_lp)'(0); 
              v_n = v_r;
              data_n = data_r;
            end
          endcase
        end
        // output valid, but not taken.
        else begin
          deque = 1'b0;
          inval = 1'b0;
          cptr_inc = 1'b0;
          rptr_inc = (rptr_inc_width_lp)'(0);

          mem_read_en = rptr_plus1_valid;
          mem_read_addr = rptr_plus1;
          v_n = v_r;
          data_n = data_r;
        end
      end
      // output not valid.
      else begin
        deque = empty
          ? 1'b0
          : ~rptr_valid;
        inval = 1'b0;
        cptr_inc = empty
          ? 1'b0
          : (rptr_valid
            ? 1'b0
            : ~scan_not_dq_i);
        rptr_inc = empty
          ? (rptr_inc_width_lp)'(0)
          : (rptr_valid 
            ? 1'b0
            : (rptr_inc_width_lp)'(1));

        mem_read_en = mem_read_en_r
          ? rptr_plus1_valid
          : rptr_valid;
        mem_read_addr = mem_read_en_r
          ? rptr_plus1
          : rptr_r;

        v_n = empty
          ? enque 
          : mem_read_en_r;
        data_n = empty
          ? (enque ? data_i : data_r)
          : (mem_read_en_r ? mem_data_lo : data_r);
      end
    end
  end



  // synopsys translate_off

  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      if (rollback_i) assert(empty_o) else $error("[BSG_ERROR] rollback_i called when fifo is not empty_o.");
    end
  end

  // synopsys translate_on

endmodule
