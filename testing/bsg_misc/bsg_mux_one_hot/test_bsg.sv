`define WIDTH_P 4
`define ELS_P   3

`include "bsg_defines.sv"

/********************************** TEST RATIONALE *************************

1. STATE SPACE

  Since the values of data inputs have little influence on the functioning 
  of DUT, they are kept constant and not varied. The select input should be 
  a one hot code and is varied from 00..1 to 10..0.

2. PARAMETERIZATION

  The parameter WIDTH_P is the width of the data input and ELS_P is the 
  number of inputs to the mux which in this case is equal to the width of the 
  select input. Since the DUT deals with the data inputs of different widths 
  similarly, an arbitrary set of tests that include edge cases would suffice. 
  So a minimum set of tests might be WIDTH_P = 1,2,3,4 and ELS_P = 2,3,4.

***************************************************************************/

module test_bsg
#(
  parameter cycle_time_p = 20,
  parameter width_p      = `WIDTH_P, // width of test input
  parameter els_p        = `ELS_P,
  parameter reset_cycles_lo_p=0,
  parameter reset_cycles_hi_p=5
);

  wire clk;
  wire reset;
  
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk)
                          );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );
  initial
  begin
    $display("\n\n\n");
    $display("===========================================================");
    $display("testing with ...");
    $display("WIDTH_P: %d", width_p);
    $display("ELS_P  : %d\n", els_p);
  end 
                                        
  logic [els_p-1:0][width_p-1:0] test_input_data;
  logic [els_p-1:0] test_input_sel;
  logic [width_p-1:0] test_output;
  logic [`BSG_SAFE_CLOG2(els_p)-1:0] addr;
  
  genvar i;
  for(i=0; i<=els_p; ++i)
    assign test_input_data[i] = width_p'(i);
  
  always_ff @(posedge clk)
  begin
    if(reset)
      test_input_sel <= els_p'(1);
    else
      begin
        test_input_sel <= (test_input_sel << 1);
        
        if(~|test_input_sel)
          begin
            $display("=============================================================\n");
            $finish;
          end
        
        assert (test_output==width_p'(addr))
          else $error("mismatch on input %x", test_input_sel);
      end
    
    /*$display("test_input_sel: %b, test_output: %b\n"
             , test_input_sel, test_output);*/
    
    
  end
  
  bsg_encode_one_hot #(  .width_p(els_p)
                      )  encode_one_hot
                      (  .i     (test_input_sel)
                       , .addr_o(addr)
                       , .v_o   ()
                      );
  
  bsg_mux_one_hot #(  .width_p (width_p)
                    , .els_p   (els_p)
                    , .harden_p()
                   )  DUT
                   (  .data_i       (test_input_data)
                    , .sel_one_hot_i(test_input_sel)
                    , .data_o       (test_output)
                   );
                                  
  /*bsg_nonsynth_ascii_writer #(  .width_p      (width_p)
                              , .values_p     (2)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("w")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i ({test_output,
                                          width_p'(addr)}
                                        )
                             );*/
                                  
endmodule