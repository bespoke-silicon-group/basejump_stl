
`include "bsg_defines.v"

`default_nettype none

program testbench #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(lg_size_p)
    , localparam els_lp = (1 << lg_size_p)
)
(
     input                      clk_i
   , output logic               reset_o

   , output logic               clr_v_o
   , output logic               deq_v_o
   , output logic               roll_v_o

   , output logic [width_p-1:0] data_o
   , output logic               v_o
   , input                      ready_i

   , input [width_p-1:0]        data_i
   , input                      v_i
   , output logic               yumi_o
);

  parameter count = 500000;
                   
  logic ready_lo;
  assign yumi_o = v_i & ready_lo;

  clocking cb @(posedge clk_i);
    input  ready_i;
    input  data_i;
    input  v_i;
  endclocking

  //***********************************************//
  //   FIFO for read history                       //
  //***********************************************//
  // extra element for distinguishing empty from full
  bit [width_p-1:0] fifo [els_lp+1]; // used for read history
  bit [lg_size_p+1-1:0] tail_idx = 0; // read end
  bit [lg_size_p+1-1:0] head_idx = 0; // write end
  bit [lg_size_p+1-1:0] read_idx = 0;
  function automatic bit fifo_tail_read_equal();
    return (tail_idx == read_idx);
  endfunction

  function automatic bit [lg_size_p+1-1:0] idx_next(
      bit [lg_size_p+1-1:0] current_idx
  );
    return (current_idx + 1'b1) % (els_lp + 1);
  endfunction

  function automatic bit fifo_roll_is_done();
    return (read_idx == head_idx);
  endfunction

  task automatic fifo_enq(input bit [width_p-1:0] elem);
    bit [lg_size_p+1-1:0] head_idx_next;
    assert(fifo_roll_is_done() == 1'b1) else $finish;
    head_idx_next = idx_next(head_idx);
    assert(head_idx_next != tail_idx) else $finish;
    fifo[head_idx] = elem;
    head_idx = head_idx_next;
    read_idx = head_idx;
  endtask

  task automatic fifo_deq();
    assert(tail_idx != head_idx) else $finish;
    assert(tail_idx != read_idx) else $finish;
    tail_idx = idx_next(tail_idx);
  endtask

  function automatic bit [width_p-1:0] fifo_read_history();
    bit [width_p-1:0] elem;
    assert(fifo_roll_is_done() == 1'b0) else $finish;
    elem = fifo[read_idx];
    read_idx = idx_next(read_idx);
    return elem;
  endfunction

  // Note: roll == 1'b1 -> v_o from rolly fifo is 1'b0
  // illegal: deq == 1'b1, rptr == rcptr, roll == 1'b1
  function automatic void fifo_roll();
    read_idx = tail_idx;
  endfunction

  //***********************************************//
  

  task automatic writer (
      input int unsigned count
  );
    int unsigned progress = 0;
    int unsigned tmp;
    while (progress != count) begin
      // write
      v_o = $urandom();
      if(v_o == 1'b1) begin
        tmp = $urandom();
        if(tmp % 32 <= 30)
          data_o = tmp * 2;
        else
          data_o = tmp;
        
      end else begin
        data_o = 'x;
      end
      @(cb);
      if(v_o & cb.ready_i) begin
        // write handshaking has completed
        progress++;
      end
    end
  endtask
  task automatic reader ();
    bit is_illegal_value = 0;
    bit roll_v_o_next = 0;
    bit [width_p-1:0] expected_read;
    ready_lo = 1'b0;
    roll_v_o = 1'b0;
    deq_v_o = 1'b0;
    forever begin
      // deq_v_o, roll_v_o, clr_v_o
      //

      roll_v_o = roll_v_o_next;
      if(is_illegal_value) begin
        clr_v_o = 1'b1;
        is_illegal_value = 1'b0;
      end else begin
        // Note: if clr_v_o needs to be random here.
        // Be aware clr_v_o cannot be high during the roll progress
        if(fifo_roll_is_done())
          clr_v_o = $urandom();
        else
          clr_v_o = 1'b0;
      end
      @(cb);

      if(cb.v_i & ready_lo) begin
        // read handshaking has completed
        assert(cb.data_i % 2 == 0) else $finish;
        if(fifo_roll_is_done())
          fifo_enq(cb.data_i);
        else begin
          expected_read = fifo_read_history();
          assert(expected_read == cb.data_i) else $finish;
        end
      end
      if(deq_v_o)
        fifo_deq();
      if(roll_v_o) begin
        fifo_roll();
        ready_lo = 1'b0;
      end else begin
        // do check only when previous roll_v_o is 0
        if(v_i) begin
          if(data_i % 2 == 1) begin
            // get the wrong value
            ready_lo = 1'b0;
            is_illegal_value = 1;
          end else begin
            // right value
            ready_lo = $urandom();
          end
        end else begin
          ready_lo = $urandom();
        end
      end
      if(roll_v_o) begin
        // roll_v_o is 1 in previous cycle, which means we cannot see 
        // the value of v_i in current cycle, as v_i depends on roll.
        if(fifo_tail_read_equal())
          // deq_v_o could be 1, but we have to be conservative here, as we don't
          // know if yumi_i is 1 or 0
          deq_v_o = 1'b0;
        else
          deq_v_o = ($urandom() % 8 == 0);
        // we avoid consecutive high roll_v_o to improve performance
        roll_v_o_next = 1'b0;
      end else begin
        roll_v_o_next = $urandom();
        if(fifo_tail_read_equal()) begin
          if((v_i & ~roll_v_o_next) == 1'b1 & ready_lo) begin
            // Read data will be read out in next cycle, so deq_v_o can be 1 even if
            // rptr == rcptr
            deq_v_o = ($urandom() % 8 ==0);
          end else begin
            deq_v_o = 1'b0;
          end
        end else begin
          deq_v_o = ($urandom() % 8 == 0);
        end
      end
    end
  endtask
  initial begin
    reset_o = 1'b1;
    v_o = 1'b0;
    ready_lo = 1'b0;
    @(cb);
    reset_o = 1'b0;
    fork
      writer(count);
      reader();
    join_any
    $display("Test completed");
    $finish;
  end

endprogram
