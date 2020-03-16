module bsg_dmc_controller
  import bsg_dmc_pkg::bsg_dmc_s;
 #(parameter  ui_addr_width_p      = "inv"
  ,parameter  ui_data_width_p      = "inv"
  ,parameter  burst_data_width_p   = "inv"
  ,parameter  dfi_data_width_p     = "inv"
  ,parameter  ui_burst_length_lp   = burst_data_width_p / ui_data_width_p
  ,localparam ui_mask_width_lp     = ui_data_width_p >> 3
  ,localparam dfi_mask_width_lp    = dfi_data_width_p >> 3
  ,localparam dfi_burst_length_lp  = burst_data_width_p / dfi_data_width_p)
  // User interface clock and reset
  (input                              ui_clk_i
  ,input                              ui_clk_sync_rst_i
  // User interface signals
  ,input        [ui_addr_width_p-1:0] app_addr_i
  ,input                        [2:0] app_cmd_i
  ,input                              app_en_i
  ,output                             app_rdy_o
  ,input                              app_wdf_wren_i
  ,input        [ui_data_width_p-1:0] app_wdf_data_i
  ,input       [ui_mask_width_lp-1:0] app_wdf_mask_i
  ,input                              app_wdf_end_i
  ,output                             app_wdf_rdy_o
  ,output                             app_rd_data_valid_o
  ,output       [ui_data_width_p-1:0] app_rd_data_o
  ,output reg                         app_rd_data_end_o
  ,input                              app_ref_req_i
  ,output                             app_ref_ack_o
  ,input                              app_zq_req_i
  ,output                             app_zq_ack_o
  ,input                              app_sr_req_i
  ,output                             app_sr_active_o
  // Status signal
  ,output reg                         init_calib_complete_o
  // DDR PHY interface clock and reset
  ,input                              dfi_clk_i
  ,input                              dfi_clk_sync_rst_i
  // DDR PHY interface signals
  ,output reg                   [2:0] dfi_bank_o
  ,output reg                  [15:0] dfi_address_o
  ,output reg                         dfi_cke_o
  ,output reg                         dfi_cs_n_o
  ,output reg                         dfi_ras_n_o
  ,output reg                         dfi_cas_n_o
  ,output reg                         dfi_we_n_o
  ,output reg                         dfi_reset_n_o
  ,output reg                         dfi_odt_o
  ,output reg                         dfi_wrdata_en_o
  ,output reg  [dfi_data_width_p-1:0] dfi_wrdata_o
  ,output reg [dfi_mask_width_lp-1:0] dfi_wrdata_mask_o
  ,output reg                         dfi_rddata_en_o
  ,input       [dfi_data_width_p-1:0] dfi_rddata_i
  ,input                              dfi_rddata_valid_i
  // Control and Status Registers
  ,input bsg_dmc_s                    dmc_p_i);

  typedef enum logic [1:0] {IDLE, INIT, REFR, LDST} state;

  localparam  LMR    = 4'b0000,
              REF    = 4'b0001,
              PRE    = 4'b0010,
              ACT    = 4'b0011,
              WRITE  = 4'b0100,
              READ   = 4'b0101,
              BST    = 4'b0110,
              NOP    = 4'b0111,
              //
              ERROR  = 4'b1111;

  integer i;
  genvar k;

  logic                                                                cmd_afifo_wclk,     cmd_afifo_rclk;
  logic                                                                cmd_afifo_wrst,     cmd_afifo_rrst;
  logic                                                                cmd_afifo_winc,     cmd_afifo_rinc;
  logic                                                                cmd_afifo_wfull,    cmd_afifo_rvalid;
  logic                                          [ui_addr_width_p+2:0] cmd_afifo_wdata,    cmd_afifo_rdata;

  logic                                                                cmd_sfifo_winc,     cmd_sfifo_rinc;
  logic                                                                cmd_sfifo_ready,    cmd_sfifo_valid;
  logic                                                         [27:0] cmd_sfifo_wdata,    cmd_sfifo_rdata;

  logic                                                                wrdata_afifo_wclk,  wrdata_afifo_rclk;
  logic                                                                wrdata_afifo_wrst,  wrdata_afifo_rrst;
  logic                                                                wrdata_afifo_winc,  wrdata_afifo_rinc;
  logic                                                                wrdata_afifo_wfull, wrdata_afifo_rvalid;
  logic                         [ui_data_width_p+ui_mask_width_lp-1:0] wrdata_afifo_wdata, wrdata_afifo_rdata;

  logic                                                                rddata_afifo_wclk,  rddata_afifo_rclk;
  logic                                                                rddata_afifo_wrst,  rddata_afifo_rrst;
  logic                                                                rddata_afifo_winc,  rddata_afifo_rinc;
  logic                                                                rddata_afifo_wfull, rddata_afifo_rvalid;
  logic                                         [dfi_data_width_p-1:0] rddata_afifo_wdata, rddata_afifo_rdata;

  logic                                                                tx_sipo_valid_li;
  logic                         [ui_mask_width_lp+ui_data_width_p-1:0] tx_sipo_data_li;
  logic                                                                tx_sipo_ready_lo;
  logic                                       [ui_burst_length_lp-1:0] tx_sipo_valid_lo;
  logic [ui_burst_length_lp-1:0][ui_mask_width_lp+ui_data_width_p-1:0] tx_sipo_data_lo;
  logic                                 [$clog2(ui_burst_length_lp):0] tx_sipo_yumi_cnt_li;

  logic                                                                tx_data_piso_valid_li;
  logic                [dfi_burst_length_lp-1:0][dfi_data_width_p-1:0] tx_data_piso_data_li;
  logic                                                                tx_data_piso_ready_lo;
  logic                                                                tx_data_piso_valid_lo;
  logic                                         [dfi_data_width_p-1:0] tx_data_piso_data_lo;
  logic                                                                tx_data_piso_yumi_li;

  logic                                                                tx_mask_piso_valid_li;
  logic               [dfi_burst_length_lp-1:0][dfi_mask_width_lp-1:0] tx_mask_piso_data_li;
  logic                                                                tx_mask_piso_ready_lo;
  logic                                                                tx_mask_piso_valid_lo;
  logic                                        [dfi_mask_width_lp-1:0] tx_mask_piso_data_lo;
  logic                                                                tx_mask_piso_yumi_li;

  logic [(dfi_data_width_p+dfi_mask_width_lp)*dfi_burst_length_lp-1:0] tx_data_mask;
  logic                     [dfi_data_width_p*dfi_burst_length_lp-1:0] tx_data;
  logic                    [dfi_mask_width_lp*dfi_burst_length_lp-1:0] tx_mask;

  logic                                                                rx_piso_valid_li;
  logic                  [ui_burst_length_lp-1:0][ui_data_width_p-1:0] rx_piso_data_li;
  logic                                                                rx_piso_ready_lo;
  logic                                                                rx_piso_valid_lo;
  logic                                          [ui_data_width_p-1:0] rx_piso_data_lo;
  logic                                                                rx_piso_yumi_li;

  logic                                                                rx_sipo_valid_li;
  logic                                         [dfi_data_width_p-1:0] rx_sipo_data_li;
  logic                                                                rx_sipo_ready_lo;
  logic                                      [dfi_burst_length_lp-1:0] rx_sipo_valid_lo;
  logic                [dfi_burst_length_lp-1:0][dfi_data_width_p-1:0] rx_sipo_data_lo;
  logic                                [$clog2(dfi_burst_length_lp):0] rx_sipo_yumi_cnt_li;

  logic                     [dfi_data_width_p*dfi_burst_length_lp-1:0] rx_data;

  logic [31:0] row_col_addr;
  logic [15:0] row_addr, col_addr;
  logic  [2:0] bank_addr;
  logic        ap;

  logic  [7:0] cmd_tick;
  logic  [7:0] cmd_act_tick;
  logic  [7:0] cmd_wr_tick, cmd_rd_tick;

  logic        cwd_valid;
  logic  [7:0] cwd_tick;
  logic        wburst_valid;
  logic  [7:0] wburst_tick;

  logic        cas_valid;
  logic  [7:0] cas_tick;
  logic  [7:0] rburst_tick;

  state        cstate, nstate;

  logic  [3:0] p_cmd;
  logic  [3:0] c_cmd, n_cmd;
  logic        shoot;
  logic  [7:0] open_bank;
  logic [15:0] open_row [0:7];

  logic  [3:0] init_tick;
  logic        push_init_cmd;
  logic [27:0] init_cmd;
  logic        init_done;

  logic [15:0] ref_tick;
  logic  [1:0] refr_tick;
  logic        push_refr_cmd;
  logic [27:0] refr_cmd;
  logic        refr_req;
  logic        refr_ack;

  logic  [1:0] ldst_tick;
  logic        push_ldst_cmd;
  logic [27:0] ldst_cmd;

  logic  [3:0] tbl;

  logic [15:0] tick_refi;
  logic  [3:0] tick_mrd;
  logic  [3:0] tick_rfc;
  logic  [3:0] tick_rc;
  logic  [3:0] tick_rp;
  logic  [3:0] tick_ras;
  logic  [3:0] tick_rrd;
  logic  [3:0] tick_rcd;
  logic  [3:0] tick_wr;
  logic  [3:0] tick_wtr;
  logic  [3:0] tick_rtp;
  logic  [3:0] tick_cas;


  assign app_ref_ack_o = app_ref_req_i & ~app_wdf_end_i;
  assign app_zq_ack_o = app_zq_req_i;
  assign app_sr_active_o = app_sr_req_i;

  assign tbl = 4'($clog2(dfi_burst_length_lp << 1));

  assign app_rdy_o = ~cmd_afifo_wfull;

  assign cmd_afifo_wclk  = ui_clk_i;
  assign cmd_afifo_wrst  = ui_clk_sync_rst_i;
  assign cmd_afifo_winc  = app_en_i & app_rdy_o;
  assign cmd_afifo_wdata = {app_cmd_i, app_addr_i};

  assign cmd_afifo_rclk  = dfi_clk_i;
  assign cmd_afifo_rrst  = dfi_clk_sync_rst_i;
  assign cmd_afifo_rinc  = cmd_afifo_rvalid & cmd_sfifo_ready & (cstate == LDST && ldst_tick == 0);

  bsg_async_fifo #
    (.width_p   ( ui_addr_width_p+3 )
    ,.lg_size_p ( 3                 ))
  cmd_afifo
    (.r_data_o  ( cmd_afifo_rdata   )
    ,.w_full_o  ( cmd_afifo_wfull   )
    ,.r_valid_o ( cmd_afifo_rvalid  )
    ,.w_data_i  ( cmd_afifo_wdata   )
    ,.w_enq_i   ( cmd_afifo_winc    )
    ,.w_clk_i   ( cmd_afifo_wclk    )
    ,.w_reset_i ( cmd_afifo_wrst    )
    ,.r_deq_i   ( cmd_afifo_rinc    )
    ,.r_clk_i   ( cmd_afifo_rclk    )
    ,.r_reset_i ( cmd_afifo_rrst    ));

  assign wrdata_afifo_wclk  = ui_clk_i;
  assign wrdata_afifo_wrst  = ui_clk_sync_rst_i;
  assign wrdata_afifo_winc  = app_wdf_wren_i & ~wrdata_afifo_wfull;
  assign wrdata_afifo_wdata = {app_wdf_mask_i,app_wdf_data_i};
  assign wrdata_afifo_rclk  = dfi_clk_i;
  assign wrdata_afifo_rrst  = dfi_clk_sync_rst_i;
  assign wrdata_afifo_rinc  = tx_sipo_ready_lo & wrdata_afifo_rvalid;

  assign app_wdf_rdy_o = ~wrdata_afifo_wfull;

  bsg_async_fifo #
    (.width_p   ( ui_data_width_p+ui_mask_width_lp )
    ,.lg_size_p ( 6                                ))
  wrdata_afifo
    (.r_data_o  ( wrdata_afifo_rdata               )
    ,.w_full_o  ( wrdata_afifo_wfull               )
    ,.r_valid_o ( wrdata_afifo_rvalid              )
    ,.w_data_i  ( wrdata_afifo_wdata               )
    ,.w_enq_i   ( wrdata_afifo_winc                )
    ,.w_clk_i   ( wrdata_afifo_wclk                )
    ,.w_reset_i ( wrdata_afifo_wrst                )
    ,.r_deq_i   ( wrdata_afifo_rinc                )
    ,.r_clk_i   ( wrdata_afifo_rclk                )
    ,.r_reset_i ( wrdata_afifo_rrst                ));

  assign tx_sipo_valid_li = wrdata_afifo_rvalid;
  assign tx_sipo_data_li = wrdata_afifo_rdata;
  assign tx_sipo_yumi_cnt_li = ($clog2(ui_burst_length_lp)+1)'((shoot&&cmd_sfifo_rdata[23:20]==WRITE)? ui_burst_length_lp: 0);

  bsg_serial_in_parallel_out #
    (.width_p    ( ui_data_width_p+ui_mask_width_lp )
    ,.els_p      ( ui_burst_length_lp               ))
  tx_sipo
    (.clk_i      ( dfi_clk_i                        )
    ,.reset_i    ( dfi_clk_sync_rst_i               )
    ,.valid_i    ( tx_sipo_valid_li                 )
    ,.data_i     ( tx_sipo_data_li                  )
    ,.ready_o    ( tx_sipo_ready_lo                 ) 
    ,.valid_o    ( tx_sipo_valid_lo                 )
    ,.data_o     ( tx_sipo_data_lo                  )
    ,.yumi_cnt_i ( tx_sipo_yumi_cnt_li              ));

  //assign col_addr  = 16'(((1 << dmc_p_i.col_width) - 1) & cmd_afifo_rdata[ui_addr_width_p-1:0]);
  //assign row_addr  = 16'(((1 << dmc_p_i.row_width) - 1) & (cmd_afifo_rdata[ui_addr_width_p-1:0] >> dmc_p_i.col_width));
  //assign bank_addr = 3'(((1 << dmc_p_i.bank_width) - 1) & (cmd_afifo_rdata[ui_addr_width_p-1:0] >> ( {1'b0,dmc_p_i.col_width} + {1'b0,dmc_p_i.row_width})));
  //assign row_col_addr = ((cmd_afifo_rdata[ui_addr_width_p-1:0] >> (dmc_p_i.bank_pos + dmc_p_i.bank_width)) << dmc_p_i.bank_pos) | (((1 << dmc_p_i.col_width) - 1) & cmd_afifo_rdata[ui_addr_width_p-1:0]);
  assign row_col_addr = ((cmd_afifo_rdata[ui_addr_width_p-1:0] >> (dmc_p_i.bank_pos + dmc_p_i.bank_width)) << dmc_p_i.bank_pos) | (((1 << dmc_p_i.bank_pos) - 1) & cmd_afifo_rdata[ui_addr_width_p-1:0]);
  assign col_addr     = 16'(((1 << dmc_p_i.col_width) - 1) & row_col_addr[ui_addr_width_p-1:0]);
  assign row_addr     = 16'(((1 << dmc_p_i.row_width) - 1) & (row_col_addr >> dmc_p_i.col_width));
  assign bank_addr    = 3'(((1 << dmc_p_i.bank_width) - 1) & (cmd_afifo_rdata[ui_addr_width_p-1:0] >> dmc_p_i.bank_pos));
  assign ap           = cmd_afifo_rdata[ui_addr_width_p+1];

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      init_calib_complete_o <= 0;
    else if(init_done)
      init_calib_complete_o <= 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      init_tick <= 0;
    else if(cstate == IDLE && nstate == INIT)
      init_tick <= dmc_p_i.init_cmd_cnt;
    else if(cstate == INIT && init_tick != 0 && push_init_cmd)
      init_tick <= init_tick - 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      init_done <= 0;
    else if(cstate == INIT && nstate == IDLE)
      init_done <= 1;

  always @(*) begin
    if(cstate == INIT)
      case(init_tick)
        'd5:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, NOP, 20'h0};
                  end
        'd4:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, PRE, 20'h400};
                  end
        'd3:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, REF, 20'h0};
                  end
        'd2:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, REF, 20'h0};
                  end
        'd1:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, LMR, 4'h0, 4'h0, 4'h0, dmc_p_i.tcas, tbl};
                  end
        'd0:      begin
                    push_init_cmd = cmd_sfifo_ready;
                    init_cmd = {4'h2, LMR, 4'h2, 16'h0};
                  end
         default: begin
                    push_init_cmd = 0;
                    init_cmd = 28'h0;
                  end
      endcase
    else begin
      init_cmd = 28'h0;
      push_init_cmd = 0;
    end
  end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      ref_tick <= 0;
    else if(init_done)
      if(ref_tick == dmc_p_i.trefi)
        ref_tick <= 0;
      else if(!refr_req)
        ref_tick <= ref_tick + 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      refr_req <= 0;
    else if(init_done)
      if(refr_ack)
        refr_req <= 0;
      else if(ref_tick == dmc_p_i.trefi)
        refr_req <= 1;

  assign refr_ack = (cstate == REFR) & push_refr_cmd & (refr_tick == 0);

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      refr_tick <= 0;
    else if(cstate == IDLE && nstate == REFR)
      if(|open_bank)
        refr_tick <= 1;
      else
        refr_tick <= 0;
    else if(cstate == REFR && refr_tick != 0 && push_refr_cmd)
      refr_tick <= refr_tick - 1;

  always @(*) begin
    if(cstate == REFR)
      case(refr_tick)
        'd1:      begin
                    push_refr_cmd = cmd_sfifo_ready;
                    refr_cmd = {4'h2, PRE, 20'h400};
                  end
        'd0:      begin
                    push_refr_cmd = cmd_sfifo_ready;
                    refr_cmd = {4'h2, REF, 20'h0};
                  end
         default: begin
                    push_refr_cmd = 0;
                    refr_cmd = 28'h0;
                  end
      endcase
    else begin
      push_refr_cmd = 0;
      refr_cmd = 28'h0;
    end
  end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      ldst_tick <= 0;
    else if(cstate == IDLE && nstate == LDST) begin
      if(open_bank[bank_addr] && open_row[bank_addr] == row_addr)
        ldst_tick <= 0;
      else if(open_bank[bank_addr])
        ldst_tick <= 2;
      else
        ldst_tick <= 1;
    end
    else if(cstate == LDST && ldst_tick != 0 && push_ldst_cmd)
      ldst_tick <= ldst_tick - 1;

  always @(*) begin
    if(cstate == LDST)
      case(ldst_tick)
        'd2:     begin
                   push_ldst_cmd = cmd_sfifo_ready;
                   ldst_cmd = {4'h2, PRE, {1'b0, bank_addr}, open_row[bank_addr]};
                 end
        'd1:     begin
                   push_ldst_cmd = cmd_sfifo_ready;
                   ldst_cmd = {4'h2, ACT, {1'b0, bank_addr}, row_addr};
                 end
        'd0:     begin
                   push_ldst_cmd = cmd_sfifo_ready;
                   if(cmd_afifo_rdata[ui_addr_width_p])
                     ldst_cmd = {4'h2, READ,  {1'b0, bank_addr}, {col_addr[14:10], ap, col_addr[9:0]}};
                   else
                     ldst_cmd = {4'h2, WRITE, {1'b0, bank_addr}, {col_addr[14:10], ap, col_addr[9:0]}};
                 end
        default: begin
                   push_ldst_cmd = 0;
                   ldst_cmd = 28'h0;
                 end
      endcase
    else begin
      ldst_cmd = 28'h0;
      push_ldst_cmd = 0;
    end
  end

  always @(*) begin
    nstate = IDLE;
    case(cstate)
      IDLE: if(!init_done)                      nstate = INIT;
            else if(refr_req)                   nstate = REFR;
            else if(cmd_afifo_rvalid)           nstate = LDST;
            else                                nstate = cstate;
      INIT: if(init_tick == 0 && push_init_cmd) nstate = IDLE;
            else                                nstate = cstate;
      REFR: if(refr_tick == 0 && push_refr_cmd) nstate = IDLE;
            else                                nstate = cstate;
      LDST: if(ldst_tick == 0 && push_ldst_cmd) nstate = IDLE;
            else                                nstate = cstate;
      default:                                  nstate = IDLE;
    endcase
  end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      cstate <= IDLE;
    else
      cstate <= nstate;

  assign cmd_sfifo_winc  = push_init_cmd | push_refr_cmd | push_ldst_cmd;
  assign cmd_sfifo_wdata = push_init_cmd? init_cmd: (push_refr_cmd? refr_cmd: (push_ldst_cmd? ldst_cmd: 28'hx));
  assign cmd_sfifo_rinc  = shoot;

  bsg_fifo_1r1w_small #
    (.width_p            ( 28                 )
    ,.els_p              ( 4                  )
    ,.ready_THEN_valid_p ( 1                  ))
  cmd_sfifo
    (.clk_i              ( dfi_clk_i          )
    ,.reset_i            ( dfi_clk_sync_rst_i )
    ,.v_i                ( cmd_sfifo_winc     )
    ,.ready_o            ( cmd_sfifo_ready    )
    ,.data_i             ( cmd_sfifo_wdata    )
    ,.v_o                ( cmd_sfifo_valid    )
    ,.data_o             ( cmd_sfifo_rdata    )
    ,.yumi_i             ( cmd_sfifo_rinc     ));

  always @(*) begin
    if(cmd_sfifo_valid)
      case(p_cmd)
	LMR:   shoot = cmd_tick >= dmc_p_i.tmrd;
	REF:   shoot = cmd_tick >= dmc_p_i.trfc;
	PRE:   shoot = (n_cmd==ACT)? (cmd_tick >= dmc_p_i.trp && cmd_act_tick >= dmc_p_i.tras): cmd_tick >= dmc_p_i.trp;
	ACT:   case(n_cmd)
                 PRE:     shoot = cmd_tick >= dmc_p_i.tras;
                 ACT:     shoot = cmd_tick >= dmc_p_i.trrd;
                 WRITE:   shoot = (cmd_tick >= dmc_p_i.trcd) & (cmd_rd_tick >= dmc_p_i.tcas+tbl) & (&tx_sipo_valid_lo);
                 READ:    shoot = (cmd_tick >= dmc_p_i.trcd) & (cmd_wr_tick >= dmc_p_i.twtr);
	         default: shoot = 1'b1;
               endcase
        WRITE: case(n_cmd)
                 PRE:     shoot = (cmd_tick >= dmc_p_i.twr) & (cmd_act_tick >= dmc_p_i.tras);
                 WRITE:   shoot = (cmd_tick >= tbl) & (&tx_sipo_valid_lo);
                 READ:    shoot = cmd_tick >= dmc_p_i.twtr;
                 //ACT:     shoot = cmd_act_tick >= dmc_p_i.trc;
                 ACT:     shoot = (cmd_act_tick >= dmc_p_i.trc) & (cmd_tick >= dmc_p_i.twr + dmc_p_i.trp);
	         default: shoot = 1'b1;
               endcase
        READ:  case(n_cmd)
                 PRE:     shoot = (cmd_tick >= dmc_p_i.trtp) & (cmd_act_tick >= dmc_p_i.tras);
                 WRITE:   shoot = (cmd_tick >= tbl+dmc_p_i.tcas) & (&tx_sipo_valid_lo);
                 READ:    shoot = cmd_tick >= tbl;
                 //ACT:     shoot = cmd_act_tick >= dmc_p_i.trc;
                 ACT:     shoot = (cmd_act_tick >= dmc_p_i.trc) & (cmd_tick >= dmc_p_i.trtp + dmc_p_i.trp);
	         default: shoot = 1'b1;
               endcase
	default: shoot = 1'b1;
      endcase
    else
      shoot = 1'b0;
  end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      cmd_tick <= 0;
    else if(shoot)
      cmd_tick <= 0;
    else if(cmd_tick != 8'hf)
      cmd_tick <= cmd_tick + 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      cmd_act_tick <= 0;
    else if(shoot && n_cmd == ACT)
      cmd_act_tick <= 0;
    else if(cmd_act_tick != 8'hf)
      cmd_act_tick <= cmd_act_tick + 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      cmd_wr_tick <= 0;
    else if(shoot && n_cmd == WRITE)
      cmd_wr_tick <= 0;
    else if(cmd_tick != 8'hf)
      cmd_wr_tick <= cmd_wr_tick + 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      cmd_rd_tick <= 0;
    else if(shoot && n_cmd == READ)
      cmd_rd_tick <= 0;
    else if(cmd_tick != 8'hf)
      cmd_rd_tick <= cmd_rd_tick + 1;

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      p_cmd <= NOP;
    else if(shoot)
      p_cmd <= n_cmd;

  assign c_cmd = {dfi_cs_n_o, dfi_ras_n_o, dfi_cas_n_o, dfi_we_n_o};
  assign n_cmd = cmd_sfifo_rdata[23:20];

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i) begin
      cwd_tick <= 0;
      cwd_valid <= 0;
    end
    else if(shoot && cmd_sfifo_rdata[23:20] == WRITE) begin
      cwd_tick <= dmc_p_i.tcas - 2;
      cwd_valid <= 1;
    end
    else if(cwd_valid) begin
      cwd_tick <= cwd_tick - 1;
      if(cwd_tick == 0) cwd_valid <= 0;
    end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i) begin
      wburst_tick <= 0;
      wburst_valid <= 0;
    end
    //else if((shoot && cmd_sfifo_rdata[23:20] == WRITE) || (cwd_valid && cwd_tick == 0)) begin
    else if((shoot && cmd_sfifo_rdata[23:20] == WRITE) ) begin
      case(tbl)
        8'h01:   wburst_tick <= 0;
        8'h02:   wburst_tick <= 1;
        8'h03:   wburst_tick <= 3;
        8'h04:   wburst_tick <= 7;
        default: wburst_tick <= 0;
      endcase
      wburst_valid <= 1;
    end
    else if(wburst_valid) begin
      wburst_tick <= wburst_tick - 1;
      if(wburst_tick == 0) wburst_valid <= 0;
    end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i) begin
      cas_tick <= 0;
      cas_valid <= 0;
    end
    else if(shoot && cmd_sfifo_rdata[23:20] == READ) begin
      cas_tick <= dmc_p_i.tcas - 1;
      cas_valid <= 1;
    end
    else if(cas_valid) begin
      cas_tick <= cas_tick - 1;
      if(cas_tick == 0) cas_valid <= 0;
    end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i) begin
      rburst_tick <= 0;
      dfi_rddata_en_o <= 0;
    end
    else if(cas_valid && cas_tick == 0) begin
      case(tbl)
        8'h01:   rburst_tick <= 0;
        8'h02:   rburst_tick <= 1;
        8'h03:   rburst_tick <= 3;
        8'h04:   rburst_tick <= 7;
        default: rburst_tick <= 0;
      endcase
      dfi_rddata_en_o <= 1;
    end
    else if(dfi_rddata_en_o) begin
      rburst_tick <= rburst_tick - 1;
      if(rburst_tick == 0) dfi_rddata_en_o <= 0;
    end

  always @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      dfi_bank_o <= 3'b000;
      dfi_address_o <= 16'h0000;
      dfi_cke_o <= 1'b0;
      dfi_cs_n_o <= 1'b1;
      dfi_ras_n_o <= 1'b1;
      dfi_cas_n_o <= 1'b1;
      dfi_we_n_o <= 1'b1;
      dfi_reset_n_o <= 1'b1;
      dfi_odt_o <= 1'b1;
    end
    else if(shoot)begin
      dfi_bank_o <= cmd_sfifo_rdata[18:16];
      dfi_address_o <= cmd_sfifo_rdata[15:0];
      dfi_cke_o <= cmd_sfifo_rdata[25];
      dfi_cs_n_o <= cmd_sfifo_rdata[23];
      dfi_ras_n_o <= cmd_sfifo_rdata[22];
      dfi_cas_n_o <= cmd_sfifo_rdata[21];
      dfi_we_n_o <= cmd_sfifo_rdata[20];
    end
    else begin
      dfi_cs_n_o <= 1'b1;
      dfi_ras_n_o <= 1'b1;
      dfi_cas_n_o <= 1'b1;
      dfi_we_n_o <= 1'b1;
      dfi_reset_n_o <= 1'b1;
      dfi_odt_o <= 1'b1;
    end
  end

  always @(posedge dfi_clk_i)
    if(dfi_clk_sync_rst_i)
      open_bank <= 0;
    else if(cmd_sfifo_winc && cmd_sfifo_wdata[25]) begin
      case(cmd_sfifo_wdata[23:20])
        ACT: begin
               open_bank[cmd_sfifo_wdata[18:16]] <= 1'b1;
               open_row[cmd_sfifo_wdata[18:16]] <= cmd_sfifo_wdata[15:0];
             end
        WRITE,
        READ: open_bank[cmd_sfifo_wdata[18:16]] <= ~ap;
        PRE: begin
               if(cmd_sfifo_wdata[10])
                 open_bank <= 0;
               else
                 open_bank[cmd_sfifo_wdata[18:16]] <= 1'b0;
             end
      endcase
    end

/*
      if(cmd_sfifo_wdata[23:20] == ACT) begin
        open_bank[cmd_sfifo_wdata[18:16]] <= 1'b1;
        open_row[cmd_sfifo_wdata[18:16]] <= cmd_sfifo_wdata[15:0];
      end
      else if(cmd_sfifo_wdata[23:20] == PRE)
        if(cmd_sfifo_wdata[10])
          open_bank <= 0;
        else
          open_bank[cmd_sfifo_wdata[18:16]] <= 1'b0;
*/


  for(k=0;k<ui_burst_length_lp;k++) begin: tx_flatten
    assign tx_data[k*ui_data_width_p+:ui_data_width_p]   = tx_sipo_data_lo[k][0+:ui_data_width_p];
    assign tx_mask[k*ui_mask_width_lp+:ui_mask_width_lp] = tx_sipo_data_lo[k][ui_data_width_p+:ui_mask_width_lp];
  end
  for(k=0;k<dfi_burst_length_lp;k++) begin: tx_make
    always @(posedge dfi_clk_i) begin
      tx_data_piso_data_li[k] <= tx_data[k*dfi_data_width_p+:dfi_data_width_p];
      tx_mask_piso_data_li[k] <= tx_mask[k*dfi_mask_width_lp+:dfi_mask_width_lp];
    end
  end

  assign tx_data_piso_valid_li = wburst_valid;
  assign tx_data_piso_yumi_li  = tx_data_piso_valid_lo;

  assign tx_mask_piso_valid_li = wburst_valid;
  assign tx_mask_piso_yumi_li  = tx_mask_piso_valid_lo;

  bsg_parallel_in_serial_out #
    (.width_p ( dfi_data_width_p      )
    ,.els_p   ( dfi_burst_length_lp   ))
  tx_data_piso
    (.clk_i   ( dfi_clk_i             )
    ,.reset_i ( dfi_clk_sync_rst_i    )
    ,.valid_i ( tx_data_piso_valid_li )
    ,.data_i  ( tx_data_piso_data_li  )
    ,.ready_o ( tx_data_piso_ready_lo ) 
    ,.valid_o ( tx_data_piso_valid_lo )
    ,.data_o  ( tx_data_piso_data_lo  )
    ,.yumi_i  ( tx_data_piso_yumi_li  ));

  bsg_parallel_in_serial_out #
    (.width_p ( dfi_mask_width_lp     )
    ,.els_p   ( dfi_burst_length_lp   ))
  tx_mask_piso
    (.clk_i   ( dfi_clk_i             )
    ,.reset_i ( dfi_clk_sync_rst_i    )
    ,.valid_i ( tx_mask_piso_valid_li )
    ,.data_i  ( tx_mask_piso_data_li  )
    ,.ready_o ( tx_mask_piso_ready_lo ) 
    ,.valid_o ( tx_mask_piso_valid_lo )
    ,.data_o  ( tx_mask_piso_data_lo  )
    ,.yumi_i  ( tx_mask_piso_yumi_li  ));

  assign dfi_wrdata_o      = tx_data_piso_data_lo;
  assign dfi_wrdata_en_o   = tx_data_piso_valid_lo;
  assign dfi_wrdata_mask_o = tx_mask_piso_data_lo;

  assign rddata_afifo_wclk  = dfi_clk_i;
  assign rddata_afifo_wrst  = dfi_clk_sync_rst_i;
  assign rddata_afifo_winc  = dfi_rddata_valid_i;
  assign rddata_afifo_wdata = dfi_rddata_i;

  assign rddata_afifo_rclk  = ui_clk_i;
  assign rddata_afifo_rrst  = ui_clk_sync_rst_i;
  assign rddata_afifo_rinc  = rx_sipo_ready_lo && rddata_afifo_rvalid;

  bsg_async_fifo #
    (.width_p   ( dfi_data_width_p    )
    ,.lg_size_p ( 6                   ))
  rddata_afifo
    (.r_data_o  ( rddata_afifo_rdata  )
    ,.w_full_o  ( rddata_afifo_wfull  )
    ,.r_valid_o ( rddata_afifo_rvalid )
    ,.w_data_i  ( rddata_afifo_wdata  )
    ,.w_enq_i   ( rddata_afifo_winc   )
    ,.w_clk_i   ( rddata_afifo_wclk   )
    ,.w_reset_i ( rddata_afifo_wrst   )
    ,.r_deq_i   ( rddata_afifo_rinc   )
    ,.r_clk_i   ( rddata_afifo_rclk   )
    ,.r_reset_i ( rddata_afifo_rrst   ));

  assign rx_sipo_valid_li = rddata_afifo_rvalid;
  assign rx_sipo_data_li = rddata_afifo_rdata;
  assign rx_sipo_yumi_cnt_li = ($clog2(dfi_burst_length_lp)+1)'(&rx_sipo_valid_lo? dfi_burst_length_lp: 0);

  bsg_serial_in_parallel_out #
    (.width_p    ( dfi_data_width_p    )
    ,.els_p      ( dfi_burst_length_lp ))
  rx_sipo
    (.clk_i      ( ui_clk_i            )
    ,.reset_i    ( ui_clk_sync_rst_i   )
    ,.valid_i    ( rx_sipo_valid_li    )
    ,.data_i     ( rx_sipo_data_li     )
    ,.ready_o    ( rx_sipo_ready_lo    ) 
    ,.valid_o    ( rx_sipo_valid_lo    )
    ,.data_o     ( rx_sipo_data_lo     )
    ,.yumi_cnt_i ( rx_sipo_yumi_cnt_li ));

  for(k=0;k<dfi_burst_length_lp;k++) begin: rx_flatten
    assign rx_data[k*dfi_data_width_p+:dfi_data_width_p] = rx_sipo_data_lo[k];
  end
  for(k=0;k<ui_burst_length_lp;k++) begin: rx_make
    assign rx_piso_data_li[k] = rx_data[k*ui_data_width_p+:ui_data_width_p];
  end
  assign rx_piso_valid_li = &rx_sipo_valid_lo;
  assign rx_piso_yumi_li = app_rd_data_valid_o;

  bsg_parallel_in_serial_out #
    (.width_p ( ui_data_width_p    )
    ,.els_p   ( ui_burst_length_lp ))
  rx_piso
    (.clk_i   ( ui_clk_i           )
    ,.reset_i ( ui_clk_sync_rst_i  )
    ,.valid_i ( rx_piso_valid_li   )
    ,.data_i  ( rx_piso_data_li    )
    ,.ready_o ( rx_piso_ready_lo   ) 
    ,.valid_o ( rx_piso_valid_lo   )
    ,.data_o  ( rx_piso_data_lo    )
    ,.yumi_i  ( rx_piso_yumi_li    ));

  //logic [$clog2(ui_burst_length_lp)-1:0] rd_cnt;
  logic [7:0] rd_cnt;

  always @(posedge ui_clk_i)
    if(ui_clk_sync_rst_i)
      rd_cnt <= 0;
    else if(rx_piso_yumi_li) begin
      if(rd_cnt == ui_burst_length_lp - 1)
        rd_cnt <= '0;
      else
        rd_cnt <= rd_cnt + 1;
    end

  assign app_rd_data_valid_o = rx_piso_valid_lo;
  assign app_rd_data_o       = rx_piso_data_lo;
  assign app_rd_data_end_o   = rx_piso_valid_lo && (rd_cnt == ui_burst_length_lp - 1);

endmodule
