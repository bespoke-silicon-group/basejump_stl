class fifo_scoreboard;
    logic [7:0] model_q[$];
    int pass_count = 0;
    int error_count = 0;

    function void write_expected(logic [7:0] d);
        model_q.push_back(d);
    endfunction

    function void check_actual(logic [7:0] d_out);
        if (model_q.size() > 0) begin
            logic [7:0] expected = model_q.pop_front();
            if (d_out === expected) begin
                $display("[%0t] PASS: %h", $time, d_out);
                pass_count++;
            end else begin
                $display("[%0t] FAIL: expected %h got %h", $time, expected, d_out);
                error_count++;
            end
        end else begin
            $display("[%0t] ERROR: Unexpected data out %h", $time, d_out);
            error_count++;
        end
    endfunction

    function void report();
        $display("--------------------------");
        $display("Final Result: PASS=%0d FAIL=%0d", pass_count, error_count);
        $display("--------------------------");
    endfunction
endclass

class fifo_driver;
    virtual fifo_if vif;
    fifo_scoreboard sb;

    function new(virtual fifo_if v, fifo_scoreboard s);
        vif = v;
        sb  = s;
    endfunction

    task run();
        logic [7:0] data_to_send;
        vif.drv_cb.v_i <= 0;
        
        forever begin
            @(vif.drv_cb);
            // Decide to send a transaction
            if ($urandom_range(0,9) < 6) begin
                data_to_send = 8'($urandom_range(0,255));
                vif.drv_cb.v_i <= 1;
                vif.drv_cb.data_in <= data_to_send;
                
                // Wait for Handshake (ready_o must be 1)
                do begin
                    if (vif.drv_cb.ready_o) begin
                        sb.write_expected(data_to_send);
                        $display("[%0t] WRITE: %h", $time, data_to_send);
                    end
                    @(vif.drv_cb);
                end while (!vif.drv_cb.ready_o);
                
                vif.drv_cb.v_i <= 0;
            end
        end
    endtask
endclass

class fifo_monitor;
    virtual fifo_if vif;
    fifo_scoreboard sb;

    function new(virtual fifo_if v, fifo_scoreboard s);
        vif = v;
        sb  = s;
    endfunction

    task run();
        vif.drv_cb.yumi_i <= 0;
        forever begin
            @(vif.mon_cb);
            
            // Check data only if handshake (v_o and yumi_i) was active
            // We use mon_cb to sample the signals correctly
            if (vif.mon_cb.v_o && vif.mon_cb.yumi_i) begin
                sb.check_actual(vif.mon_cb.data_out);
            end
            
            // Generate yumi for the NEXT cycle if data is available
            if (vif.mon_cb.v_o && ($urandom_range(0,9) < 4)) begin
                vif.drv_cb.yumi_i <= 1;
            end else begin
                vif.drv_cb.yumi_i <= 0;
            end
        end
    endtask
endclass

class fifo_env;
    fifo_driver drv;
    fifo_monitor mon;
    fifo_scoreboard sb;

    function new(virtual fifo_if v);
        sb  = new();
        drv = new(v, sb);
        mon = new(v, sb);
    endfunction
endclass