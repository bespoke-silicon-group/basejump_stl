`define INPUTS_P 4

module test_bsg;
  localparam cycle_time_lp = 20;
  localparam inputs_lp     = `INPUTS_P;
  localparam payload_width_lp = 2*inputs_lp;
  localparam rom_data_width_lp = payload_width_lp + 4;
  localparam rom_addr_width_lp = 6
  localparam lo_to_hi_lp   = 0; // Priority Setting

  wire clk;
  wire reset;

  bsg_nonsynth_clock_gen 
   #(.cycle_time_p(cycle_time_lp))  
   clock_gen
    (.o(clk)
    );
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
	 ,.reset_cycles_lo_p(1)
	 ,.reset_cycles_hi_p(5))  
   reset_gen
    (.clk_i(clk) 
    ,.async_reset_o(reset)
    );

  logic test_input_ready, test_input_en;
  logic [inputs_lp-1:0] test_input_reqs_r, test_input_locks_r, test_output_grants;
  logic test_output_lock;

  logic [rom_addr_width_lp-1:0] addr_to_rom;
  logic [rom_data_width_lp-1:0] data_from_rom;
  logic [payload_width_lp-1:0] data_to_dut, data_from_dut;
  logic valid_to_dut, yumi_from_dut
  logic valid_from_dut, ready_to_dut;
  logic result_true, result_false;

  initial begin
    $vcdpluson;
    $vcdplusmemon;
    $vcdplusautoflushon;
  end

  trace_rom 
   #(.width_p(rom_data_width_lp)
   ,.addr_width_p(rom_addr_width_lp))
   the_trace_rom
    (.addr_i(addr_to_rom)
    ,.data_o(data_from_rom)
    );

  bsg_trace_replay
   #(.payload_width_p(payload_width_lp) 
    ,.rom_addr_width_p(rom_addr_width_lp)) 
   the_trace_relpayer
    (.clk_i(clk)
    ,.reset_i(reset)
    ,.en_i('1)

    ,.v_i(valid_from_dut)
    ,.data_i(data_from_dut)
    ,.ready_o(ready_to_dut)

    ,.v_o(valid_to_dut)
    ,.data_o(data_to_dut)
    ,.yumi_i(yumi_from_dut)

    ,.rom_addr_o(addr_to_rom)
    ,.rom_data_i(data_from_rom)

    ,.done_o(result_true)
    ,.error_o(result_false)
      );

  bsg_dff_en
   #(.width_p=(inputs_lp))
   input_locks_register
    (.clk_i(clk)
    ,.data_i(data_to_dut[inputs_lp+:inputs_lp])
    ,.en_i(test_input_en)
    ,.data_o(test_input_locks_r)
    );

  bsg_dff_en
   #(.width_p=(inputs_lp))
   input_reqs_register
    (.clk_i(clk)
    ,.data_i(data_to_dut[0+:inputs_lp])
    ,.en_i(test_input_en)
    ,.data_o(test_input_reqs_r)
    );

  typedef enum logic [1:0] {RESET, READY, GRANT} e_state;
  e_state state_r, state_n;
    
  always_ff @(posedge clk)
    begin
      if (reset)
        state_r <= RESET;
      else
        begin
          state_r <= state_n;
        end
    end
  
  always_comb
     begin
        valid_from_dut = '0;
        data_from_dut = '0;

        yumi_from_dut = '0; 

        test_input_ready = '0
        test_input_en = '0;
        
        state_n = state_r; 
        case(state_r)
          RESET:
            begin
              state_n = READY;
            end
          READY:
            begin
              yumi_from_dut = valid_to_dut;
              test_input_en = valid_to_dut;
              state_n = valid_to_dut ? GRANT : READY;
            end
          GRANT:
            begin
              test_input_ready = 1'b1; // ready for the arbiter should keep high for a valid output
              valid_from_dut = ready_to_dut;
              data_from_dut    = {3'd0, test_output_lock, test_output_grants};
              state_n = valid_from_dut ? READY : GRANT:
            end
     end
 

  wire unused = ready_to_dut;

  bsg_locking_arb_fixed_new 
   #(.inputs_p(inputs_lp)
   ,.lo_to_hi_p(lo_to_hi_lp))
   DUT
    (.clk_i(clk)
    ,.reset_i(reset)
    ,.ready_i(test_input_ready)

    ,.locks_i(test_input_locks_r)
    ,.reqs_i(test_input_reqs_r)
    ,.grants_o(test_output_grants)
    ,.lock_o(test_output_lock)
    );  


endmodule