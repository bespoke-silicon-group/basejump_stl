`ifndef CORE_0_PERIOD
`define CORE_0_PERIOD 20
`endif

`ifndef IO_MASTER_0_PERIOD
`define IO_MASTER_0_PERIOD 14
`endif

`ifndef IO_MASTER_1_PERIOD
`define IO_MASTER_1_PERIOD 2
`endif


`ifndef CORE_1_PERIOD
`define CORE_1_PERIOD 2
`endif



  // three separate clocks: I/O, and the two cores communicating with each other
   localparam core_0_period_lp      = `CORE_0_PERIOD;
   localparam core_1_period_lp      = `CORE_1_PERIOD;

   localparam io_master_0_period_lp =  `IO_MASTER_0_PERIOD;  // 1
   localparam io_master_1_period_lp =  `IO_MASTER_1_PERIOD;  // 1000;


   localparam slowest_period_lp
     = (core_1_period_lp > core_0_period_lp)
       ? ((io_master_1_period_lp > core_1_period_lp)
          ?  io_master_1_period_lp
          :  core_1_period_lp
          )
       : ((io_master_1_period_lp > core_0_period_lp)
          ?  io_master_1_period_lp
          :  core_0_period_lp
          );

   localparam master_to_slave_speedup_lp
     =  (slowest_period_lp + io_master_0_period_lp - 1)
       / io_master_0_period_lp;

 initial begin
      $vcdpluson;
      $vcdplusmemon;
      end
