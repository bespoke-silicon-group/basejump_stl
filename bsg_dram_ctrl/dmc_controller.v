//`include "fifo.v"

module dmc_controller #
  (parameter UI_ADDR_WIDTH  = 28
  ,parameter UI_DATA_WIDTH  = 128
  ,parameter DFI_DATA_WIDTH = 32)
  // User interface clock and reset
  (input                                ui_clk
  ,input                                ui_clk_sync_rst
  // User interface signals
  ,input            [UI_ADDR_WIDTH-1:0] app_addr
  ,input                          [2:0] app_cmd
  ,input                                app_en
  ,output                               app_rdy
  ,input                                app_wdf_wren
  ,input            [UI_DATA_WIDTH-1:0] app_wdf_data
  ,input       [(UI_DATA_WIDTH>>3)-1:0] app_wdf_mask
  ,input                                app_wdf_end
  ,output                               app_wdf_rdy
  ,output                               app_rd_data_valid
  ,output           [UI_DATA_WIDTH-1:0] app_rd_data
  ,output                               app_rd_data_end
  ,input                                app_ref_req
  ,output                               app_ref_ack
  ,input                                app_zq_req
  ,output                               app_zq_ack
  ,input                                app_sr_req
  ,output                               app_sr_active
  // Status signal
  ,output reg                           init_calib_complete
  // DDR PHY interface clock and reset
  ,input                                dfi_clk
  ,input                                dfi_clk_2x
  ,input                                dfi_clk_sync_rst
  // DDR PHY interface signals
  ,output reg                     [2:0] dfi_bank
  ,output reg                    [15:0] dfi_address
  ,output reg                           dfi_cke
  ,output reg                           dfi_cs_n
  ,output reg                           dfi_ras_n
  ,output reg                           dfi_cas_n
  ,output reg                           dfi_we_n
  ,output reg                           dfi_reset_n
  ,output reg                           dfi_odt
  ,output reg                           dfi_wrdata_en
  ,output reg      [DFI_DATA_WIDTH-1:0] dfi_wrdata
  ,output reg [(DFI_DATA_WIDTH>>3)-1:0] dfi_wrdata_mask
  ,output reg                           dfi_rddata_en
  //,output                               dfi_rddata_en
  ,input           [DFI_DATA_WIDTH-1:0] dfi_rddata
  ,input                                dfi_rddata_valid
  // Control and Status Registers
  ,input                         [31:0] slv_reg0
  ,input                         [31:0] slv_reg1
  ,input                         [31:0] slv_reg2
  ,input                         [31:0] slv_reg3
  ,input                         [31:0] slv_reg4
  ,input                         [31:0] slv_reg5
  ,input                         [31:0] slv_reg6
  ,input                         [31:0] slv_reg7
  ,input                         [31:0] slv_reg8
  ,input                         [31:0] slv_reg9
  ,input                         [31:0] slv_reg10
  ,input                         [31:0] slv_reg11
  ,input                         [31:0] slv_reg12
  ,input                         [31:0] slv_reg13
  ,input                         [31:0] slv_reg14
  ,input                         [31:0] slv_reg15);

  localparam  IDLE   = 4'b0000,
              INIT   = 4'b0001,
              REFR   = 4'b0010,
              LDST   = 4'b0011,
              //
              LMR    = 4'b0000,
              REF    = 4'b0001,
              PRE    = 4'b0010,
              ACT    = 4'b0011,
              WRITE  = 4'b0100,
              READ   = 4'b0101,
              BST    = 4'b0110,
              NOP    = 4'b0111,
	      //
	      ERROR  = 4'b1111;

  reg                                  [15:0] row_addr, col_addr;
  reg                                   [2:0] bank_addr;

  wire                                        cmd_afifo_wclk,   cmd_afifo_rclk;
  wire                                        cmd_afifo_wrst_n, cmd_afifo_rrst_n;
  wire                                        cmd_afifo_winc,   cmd_afifo_rinc;
  wire                                        cmd_afifo_wfull,  cmd_afifo_rempty;
  wire                      [UI_ADDR_WIDTH:0] cmd_afifo_wdata,  cmd_afifo_rdata;

  wire                                        cmd_sfifo_winc,  cmd_sfifo_rinc;
  wire                                        cmd_sfifo_full,  cmd_sfifo_empty;
  wire                                 [27:0] cmd_sfifo_wdata, cmd_sfifo_rdata;

  wire                                        wrdata_afifo_wclk,   wrdata_afifo_rclk;
  wire                                        wrdata_afifo_wrst_n, wrdata_afifo_rrst_n;
  wire                                        wrdata_afifo_winc,   wrdata_afifo_rinc;
  wire                                        wrdata_afifo_wfull,  wrdata_afifo_rempty;
  wire [UI_DATA_WIDTH+(UI_DATA_WIDTH>>3)-1:0] wrdata_afifo_wdata,  wrdata_afifo_rdata;

  wire                                        rddata_afifo_wclk,   rddata_afifo_rclk;
  wire                                        rddata_afifo_wrst_n, rddata_afifo_rrst_n;
  wire                                        rddata_afifo_winc,   rddata_afifo_rinc;
  wire                                        rddata_afifo_wfull,  rddata_afifo_rempty;
  wire                    [UI_DATA_WIDTH-1:0] rddata_afifo_wdata,  rddata_afifo_rdata;

  reg                     [UI_DATA_WIDTH-1:0] circular_buffer_wrdata;
  reg                [(UI_DATA_WIDTH>>3)-1:0] circular_buffer_wrmask;
  reg                     [UI_DATA_WIDTH-1:0] circular_buffer_rddata;
  reg                                   [1:0] burst_cnt;

  reg   [7:0] cmd_tick;
  reg   [7:0] cmd_lmr_tick;
  reg   [7:0] cmd_pre_tick, cmd_ref_tick;
  reg   [7:0] cmd_act_tick, cmd_wr_tick, cmd_rd_tick;

  reg         cwd_valid;
  reg   [7:0] cwd_tick;
  reg         wburst_valid;
  reg   [7:0] wburst_tick;

  reg         cas_valid;
  reg   [7:0] cas_tick;
  reg         rburst_valid;
  reg   [7:0] rburst_tick;
  reg         rburst_valid_90, rburst_valid_180, rburst_valid_270;

  reg   [3:0] cstate, nstate;

  reg   [3:0] p_cmd;
  wire  [3:0] c_cmd, n_cmd;
  reg         shoot;
  reg   [7:0] open_bank;
  reg  [15:0] open_row [0:7];

  reg   [3:0] init_tick;
  reg         push_init_cmd;
  reg  [27:0] init_cmd;
  reg         init_done;

  reg  [15:0] ref_tick;
  reg   [1:0] refr_tick;
  reg         push_refr_cmd;
  reg  [27:0] refr_cmd;
  reg         refr_req;
  wire        refr_ack;

  reg   [1:0] ldst_tick;
  reg         push_ldst_cmd;
  reg  [27:0] ldst_cmd;

  wire  [7:0] TMRD;
  wire  [7:0] TRFC;
  wire  [7:0] TRP;
  wire  [7:0] TRAS;
  wire  [7:0] TRRD;
  wire  [7:0] TRCD;
  wire  [7:0] TWR;
  wire  [3:0] TBL;
  wire  [7:0] TWTR;
  wire  [7:0] TRTP;
  wire  [7:0] TCAS;
  wire [15:0] TREFI;

  wire  [2:0] DDR_TYPE;
  wire  [3:0] INIT_CMD_CNT;
  wire  [1:0] RDDATA_VALID_CALIB;

  assign TMRD  = slv_reg1;
  assign TRFC  = slv_reg2;
  assign TRP   = slv_reg3;
  assign TRAS  = slv_reg4;
  assign TRRD  = slv_reg5;
  assign TRCD  = slv_reg6;
  assign TWR   = slv_reg7;
  assign TBL   = slv_reg8;
  assign TWTR  = slv_reg9;
  assign TRTP  = slv_reg10;
  assign TCAS  = slv_reg11;
  assign TREFI = slv_reg12;

  assign DDR_TYPE = slv_reg13[2:0];
  assign INIT_CMD_CNT = slv_reg14[3:0];
  assign RDDATA_VALID_CALIB = slv_reg14[3:0];

  wire [3:0] col_width, row_width;
  wire [1:0] bank_width;
  wire       row_bank_col;

  assign app_rdy = ~cmd_afifo_wfull & ~wrdata_afifo_wfull;

  assign cmd_afifo_wclk   = ui_clk;
  assign cmd_afifo_wrst_n = ~ui_clk_sync_rst;
  assign cmd_afifo_winc   = app_en & app_rdy;
  assign cmd_afifo_wdata  = {app_cmd[0], app_addr};

  assign cmd_afifo_rclk   = dfi_clk;
  assign cmd_afifo_rrst_n = ~dfi_clk_sync_rst;
  assign cmd_afifo_rinc   = ~cmd_afifo_rempty & ~cmd_sfifo_full & (cstate == LDST && ldst_tick == 0);

  dmc_afifo #(.DSIZE(UI_ADDR_WIDTH+1), .ASIZE(2)) cmd_afifo
    (.rdata  ( cmd_afifo_rdata  )
    ,.wfull  ( cmd_afifo_wfull  )
    ,.rempty ( cmd_afifo_rempty )
    ,.wdata  ( cmd_afifo_wdata  )
    ,.winc   ( cmd_afifo_winc   )
    ,.wclk   ( cmd_afifo_wclk   )
    ,.wrst_n ( cmd_afifo_wrst_n )
    ,.rinc   ( cmd_afifo_rinc   )
    ,.rclk   ( cmd_afifo_rclk   )
    ,.rrst_n ( cmd_afifo_rrst_n ));

  assign wrdata_afifo_wclk   = ui_clk;
  assign wrdata_afifo_wrst_n = ~ui_clk_sync_rst;
  assign wrdata_afifo_winc   = app_wdf_wren;
  assign wrdata_afifo_wdata  = {app_wdf_mask, app_wdf_data};

  assign wrdata_afifo_rclk   = dfi_clk;
  assign wrdata_afifo_rrst_n = ~dfi_clk_sync_rst;
  assign wrdata_afifo_rinc   = shoot & cmd_sfifo_rdata[23:20] == WRITE;

  dmc_afifo #(.DSIZE(UI_DATA_WIDTH+(UI_DATA_WIDTH>>3)), .ASIZE(2)) wrdata_afifo
    (.rdata  ( wrdata_afifo_rdata  )
    ,.wfull  ( wrdata_afifo_wfull  )
    ,.rempty ( wrdata_afifo_rempty )
    ,.wdata  ( wrdata_afifo_wdata  )
    ,.winc   ( wrdata_afifo_winc   )
    ,.wclk   ( wrdata_afifo_wclk   )
    ,.wrst_n ( wrdata_afifo_wrst_n )
    ,.rinc   ( wrdata_afifo_rinc   )
    ,.rclk   ( wrdata_afifo_rclk   )
    ,.rrst_n ( wrdata_afifo_rrst_n ));

  assign col_width    = slv_reg15[3:0];
  assign row_width    = slv_reg15[7:4];
  assign bank_width   = slv_reg15[9:8];
  assign row_bank_col = slv_reg15[10];

  always @(*) begin
    col_addr  = ((1 << col_width) - 1) & cmd_afifo_rdata[UI_ADDR_WIDTH-1:0];
    if(row_bank_col) begin
      bank_addr = ((1 << bank_width) - 1) & (cmd_afifo_rdata[UI_ADDR_WIDTH-1:0] >> col_width);
      row_addr  = ((1 << row_width) - 1) & (cmd_afifo_rdata[UI_ADDR_WIDTH-1:0] >> ({1'b0,col_width} + {1'b0,bank_width}));
    end
    else begin
      bank_addr = ((1 << bank_width) - 1) & (cmd_afifo_rdata[UI_ADDR_WIDTH-1:0] >> ( {1'b0,col_width} + {1'b0,row_width}));
      row_addr  = ((1 << row_width) - 1) & (cmd_afifo_rdata[UI_ADDR_WIDTH-1:0] >> col_width);
    end
  end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      init_calib_complete <= 0;
    else if(init_done)
      init_calib_complete <= 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      init_tick <= 0;
    else if(cstate == IDLE && nstate == INIT)
      init_tick <= INIT_CMD_CNT;
    else if(cstate == INIT && init_tick != 0 && push_init_cmd)
      init_tick <= init_tick - 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      init_done <= 0;
    else if(cstate == INIT && nstate == IDLE)
      init_done <= 1;

  always @(*) begin
    if(cstate == INIT)
      case(init_tick)
        'd5:      begin
                    push_init_cmd = ~cmd_sfifo_full;
                    init_cmd = {4'h2, NOP, 20'h0};
                  end
        'd4:      begin
                    push_init_cmd = ~cmd_sfifo_full;
                    init_cmd = {4'h2, PRE, 20'h400};
                  end
        'd3:      begin
                    push_init_cmd = ~cmd_sfifo_full;
                    init_cmd = {4'h2, REF, 20'h0};
                  end
        'd2:      begin
                    push_init_cmd = ~cmd_sfifo_full;
                    init_cmd = {4'h2, REF, 20'h0};
                  end
        'd1:      begin
                    push_init_cmd = ~cmd_sfifo_full;
                    init_cmd = {4'h2, LMR, 4'h0, 4'h0, TCAS, TBL};
                  end
        'd0:      begin
                    push_init_cmd = ~cmd_sfifo_full;
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

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      ref_tick <= 0;
    else if(init_done)
      if(ref_tick == TREFI)
        ref_tick <= 0;
      else if(!refr_req)
        ref_tick <= ref_tick + 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      refr_req <= 0;
    else if(init_done)
      if(refr_ack)
        refr_req <= 0;
      else if(ref_tick == TREFI)
        refr_req <= 1;
/*
  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      refr_ack <= 0;
    else if(cstate == REFR && nstate == IDLE)
      refr_ack <= 1;
    else
      refr_ack <= 0;
*/
  assign refr_ack = (cstate == REFR) & push_refr_cmd & (refr_tick == 0);

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
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
                    push_refr_cmd = ~cmd_sfifo_full;
                    refr_cmd = {4'h2, PRE, 20'h400};
                  end
        'd0:      begin
                    push_refr_cmd = ~cmd_sfifo_full;
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

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
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
                   push_ldst_cmd = ~cmd_sfifo_full;
                   ldst_cmd = {4'h2, PRE, {1'b0, bank_addr}, open_row[bank_addr]};
                 end
        'd1:     begin
                   push_ldst_cmd = ~cmd_sfifo_full;
                   ldst_cmd = {4'h2, ACT, {1'b0, bank_addr}, row_addr};
                 end
        'd0:     begin
                   push_ldst_cmd = ~cmd_sfifo_full;
                   if(cmd_afifo_rdata[UI_ADDR_WIDTH])
                     ldst_cmd = {4'h2, READ,  {1'b0, bank_addr}, {col_addr[14:10], 1'b0, col_addr[9:0]}};
                   else
                     ldst_cmd = {4'h2, WRITE, {1'b0, bank_addr}, {col_addr[14:10], 1'b0, col_addr[9:0]}};
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
      IDLE: if(!init_done)                         nstate = INIT;
            else if(refr_req)                      nstate = REFR;
            else if(!cmd_afifo_rempty)             nstate = LDST;
            else                                   nstate = cstate;
      INIT: if(init_tick == 0 && push_init_cmd)    nstate = IDLE;
            else                                   nstate = cstate;
      REFR: if(refr_tick == 0 && push_refr_cmd)    nstate = IDLE;
            else                                   nstate = cstate;
      LDST: if(ldst_tick == 0 && push_ldst_cmd)    nstate = IDLE;
            else                                   nstate = cstate;
      default:                                     nstate = IDLE;
    endcase
  end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      cstate <= IDLE;
    else
      cstate <= nstate;

  assign cmd_sfifo_winc  = push_init_cmd | push_refr_cmd | push_ldst_cmd;
  assign cmd_sfifo_wdata = push_init_cmd? init_cmd: (push_refr_cmd? refr_cmd: (push_ldst_cmd? ldst_cmd: 32'hx));
/*
  assign cmd_sfifo_winc  = push_init_cmd | push_ldst_cmd;
  assign cmd_sfifo_wdata = push_init_cmd? init_cmd: push_ldst_cmd? ldst_cmd: 32'hx;
*/
  assign cmd_sfifo_rinc  = shoot;

  dmc_sfifo #(.DSIZE(28), .ASIZE(4)) cmd_sfifo
    (.rdata ( cmd_sfifo_rdata  )
    ,.full  ( cmd_sfifo_full   )
    ,.empty ( cmd_sfifo_empty  )
    ,.wdata ( cmd_sfifo_wdata  )
    ,.winc  ( cmd_sfifo_winc   )
    ,.rinc  ( cmd_sfifo_rinc   )
    ,.clk   ( dfi_clk          )
    ,.reset ( dfi_clk_sync_rst ));

  assign app_wdf_rdy = ~wrdata_afifo_wfull;

  always @(*) begin
    if(!cmd_sfifo_empty)
      case(p_cmd)
	LMR:   shoot = cmd_tick >= TMRD;
	REF:   shoot = cmd_tick >= TRFC;
	PRE:   shoot = cmd_tick >= TRP;
	ACT:   case(n_cmd)
                 PRE:     shoot = cmd_tick >= TRAS;
                 ACT:     shoot = cmd_tick >= TRRD;
                 WRITE:   shoot = (cmd_tick >= TRCD) & (cmd_rd_tick >= TCAS+TBL);
                 //WRITE,
                 READ:    shoot = (cmd_tick >= TRCD) & (cmd_wr_tick >= TWTR);
	         default: shoot = 1'b1;
               endcase
        WRITE: case(n_cmd)
                 PRE:     shoot = cmd_tick >= TWR;
                 WRITE:   shoot = cmd_tick >= TBL;
                 READ:    shoot = cmd_tick >= TWTR;
	         default: shoot = 1'b1;
               endcase
        READ:  case(n_cmd)
                 PRE:     shoot = cmd_tick >= TRTP;
                 WRITE:   shoot = cmd_tick >= TBL+TCAS-1;
                 READ:    shoot = cmd_tick >= TBL;
	         default: shoot = 1'b1;
               endcase
	default: shoot = 1'b1;
      endcase
    else
      shoot = 1'b0;
  end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      cmd_tick <= 0;
    else if(shoot)
      cmd_tick <= 0;
    else if(cmd_tick != 8'hff)
      cmd_tick <= cmd_tick + 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      cmd_act_tick <= 0;
    else if(shoot && n_cmd == READ)
      cmd_act_tick <= 0;
    else if(cmd_tick != 8'hff)
      cmd_act_tick <= cmd_act_tick + 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      cmd_wr_tick <= 0;
    else if(shoot && n_cmd == WRITE)
      cmd_wr_tick <= 0;
    else if(cmd_tick != 8'hff)
      cmd_wr_tick <= cmd_wr_tick + 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      cmd_rd_tick <= 0;
    else if(shoot && n_cmd == READ)
      cmd_rd_tick <= 0;
    else if(cmd_tick != 8'hff)
      cmd_rd_tick <= cmd_rd_tick + 1;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      p_cmd <= NOP;
    else if(shoot)
      p_cmd <= n_cmd;

  assign c_cmd = {dfi_cs_n, dfi_ras_n, dfi_cas_n, dfi_we_n};
  assign n_cmd = cmd_sfifo_rdata[23:20];

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      cwd_tick <= 0;
      cwd_valid <= 0;
    end
    else if(DDR_TYPE != 3'b001 && shoot && cmd_sfifo_rdata[23:20] == WRITE) begin
      cwd_tick <= TCAS - 2;
      cwd_valid <= 1;
    end
    else if(cwd_valid) begin
      cwd_tick <= cwd_tick - 1;
      if(cwd_tick == 0) cwd_valid <= 0;
    end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      wburst_tick <= 0;
      wburst_valid <= 0;
    end
    else if((DDR_TYPE == 3'b001 && shoot && cmd_sfifo_rdata[23:20] == WRITE) || (DDR_TYPE != 3'b001 && cwd_valid && cwd_tick == 0)) begin
      case(TBL)
        8'h01:   wburst_tick <= 0;
        8'h02:   wburst_tick <= 1;
        8'h03:   wburst_tick <= 3;
        default: wburst_tick <= 0;
      endcase
      wburst_valid <= 1;
    end
    else if(wburst_valid) begin
      wburst_tick <= wburst_tick - 1;
      if(wburst_tick == 0) wburst_valid <= 0;
    end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      cas_tick <= 0;
      cas_valid <= 0;
    end
    else if(shoot && cmd_sfifo_rdata[23:20] == READ) begin
      cas_tick <= TCAS - 1;
      cas_valid <= 1;
    end
    else if(cas_valid) begin
      cas_tick <= cas_tick - 1;
      if(cas_tick == 0) cas_valid <= 0;
    end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      rburst_tick <= 0;
      rburst_valid <= 0;
    end
    else if(cas_valid && cas_tick == 0) begin
      case(TBL)
        8'h01:   rburst_tick <= 0;
        8'h02:   rburst_tick <= 1;
        8'h03:   rburst_tick <= 3;
        default: rburst_tick <= 0;
      endcase
      rburst_valid <= 1;
    end
    else if(rburst_valid) begin
      rburst_tick <= rburst_tick - 1;
      if(rburst_tick == 0) rburst_valid <= 0;
    end

  always @(posedge dfi_clk) begin
    if(dfi_clk_sync_rst) begin
      dfi_bank <= 3'b000;
      dfi_address <= 16'h0000;
      dfi_cke <= 1'b0;
      dfi_cs_n <= 1'b1;
      dfi_ras_n <= 1'b1;
      dfi_cas_n <= 1'b1;
      dfi_we_n <= 1'b1;
      dfi_reset_n <= 1'b1;
      dfi_odt <= 1'b1;
    end
    else if(shoot)begin
      dfi_bank <= cmd_sfifo_rdata[18:16];
      dfi_address <= cmd_sfifo_rdata[15:0];
      dfi_cke <= cmd_sfifo_rdata[25];
      dfi_cs_n <= cmd_sfifo_rdata[23];
      dfi_ras_n <= cmd_sfifo_rdata[22];
      dfi_cas_n <= cmd_sfifo_rdata[21];
      dfi_we_n <= cmd_sfifo_rdata[20];
    end
    else begin
      dfi_cs_n <= 1'b1;
      dfi_ras_n <= 1'b1;
      dfi_cas_n <= 1'b1;
      dfi_we_n <= 1'b1;
      dfi_reset_n <= 1'b1;
      dfi_odt <= 1'b1;
    end
  end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      open_bank <= 0;
    else if(cmd_sfifo_winc && cmd_sfifo_wdata[25])
      if(cmd_sfifo_wdata[23:20] == ACT) begin
        open_bank[cmd_sfifo_wdata[18:16]] <= 1'b1;
        open_row[cmd_sfifo_wdata[18:16]] <= cmd_sfifo_wdata[15:0];
      end
      else if(cmd_sfifo_wdata[23:20] == PRE)
        if(cmd_sfifo_wdata[10])
          open_bank <= 0;
        else
          open_bank[cmd_sfifo_wdata[18:16]] <= 1'b0;

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      dfi_wrdata_en <= 1'b0;
      dfi_wrdata <= 32'h0;
      dfi_wrdata_mask <= 4'h0;
      circular_buffer_wrdata <= 0;
      circular_buffer_wrmask <= 0;
    end
    else begin
      dfi_wrdata_en <= wburst_valid;
      if(shoot && cmd_sfifo_rdata[23:20] == WRITE) begin
        circular_buffer_wrdata <= wrdata_afifo_rdata[UI_DATA_WIDTH-1:0];
        circular_buffer_wrmask <= wrdata_afifo_rdata[UI_DATA_WIDTH+(UI_DATA_WIDTH>>3)-1:UI_DATA_WIDTH];
        if(wburst_valid) begin
          dfi_wrdata <= circular_buffer_wrdata[DFI_DATA_WIDTH-1:0];
          dfi_wrdata_mask <= circular_buffer_wrmask[(DFI_DATA_WIDTH>>3)-1:0];
        end
      end
      else if(wburst_valid) begin
        {circular_buffer_wrdata[UI_DATA_WIDTH-DFI_DATA_WIDTH-1:0], dfi_wrdata} <= circular_buffer_wrdata;
        {circular_buffer_wrmask[(UI_DATA_WIDTH>>3)-(DFI_DATA_WIDTH>>3)-1:0], dfi_wrdata_mask} <= circular_buffer_wrmask;
      end
    end

  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst) begin
      circular_buffer_rddata <= 0;
      burst_cnt <= 0;
    end
    else if(dfi_rddata_valid) begin
      circular_buffer_rddata <= {dfi_rddata, circular_buffer_rddata[UI_DATA_WIDTH-1:DFI_DATA_WIDTH]};
      burst_cnt <= burst_cnt + 1;
    end
/*
  always @(posedge dfi_clk)
    if(dfi_clk_sync_rst)
      dfi_rddata_en <= 1'b0;
    else
      dfi_rddata_en <= rburst_valid;
*/
  //assign dfi_rddata_en = rburst_valid;
  always @(posedge dfi_clk_2x)
    rburst_valid_180 <= rburst_valid;

  always @(negedge dfi_clk_2x) begin
    rburst_valid_90 <= rburst_valid;
    rburst_valid_270 <= rburst_valid_90;
  end

  always @(*)
    case(RDDATA_VALID_CALIB)
      2'b00:   dfi_rddata_en = rburst_valid;
      2'b01:   dfi_rddata_en = rburst_valid_90;
      2'b10:   dfi_rddata_en = rburst_valid_180;
      2'b11:   dfi_rddata_en = rburst_valid_270;
      default: dfi_rddata_en = rburst_valid;
    endcase

  assign rddata_afifo_wclk   = dfi_clk;
  assign rddata_afifo_wrst_n = ~dfi_clk_sync_rst;
  assign rddata_afifo_winc   = burst_cnt == 3;
  assign rddata_afifo_wdata  = {dfi_rddata, circular_buffer_rddata[UI_DATA_WIDTH-1:DFI_DATA_WIDTH]};

  assign rddata_afifo_rclk   = ui_clk;
  assign rddata_afifo_rrst_n = ~ui_clk_sync_rst;
  assign rddata_afifo_rinc   = ~rddata_afifo_rempty;

  dmc_afifo #(.DSIZE(UI_DATA_WIDTH), .ASIZE(2)) rddata_afifo
    (.rdata  ( rddata_afifo_rdata  )
    ,.wfull  ( rddata_afifo_wfull  )
    ,.rempty ( rddata_afifo_rempty )
    ,.wdata  ( rddata_afifo_wdata  )
    ,.winc   ( rddata_afifo_winc   )
    ,.wclk   ( rddata_afifo_wclk   )
    ,.wrst_n ( rddata_afifo_wrst_n )
    ,.rinc   ( rddata_afifo_rinc   )
    ,.rclk   ( rddata_afifo_rclk   )
    ,.rrst_n ( rddata_afifo_rrst_n ));

  assign app_rd_data_valid = rddata_afifo_rinc;
  assign app_rd_data_end = rddata_afifo_rinc;
  assign app_rd_data = rddata_afifo_rdata;

endmodule
