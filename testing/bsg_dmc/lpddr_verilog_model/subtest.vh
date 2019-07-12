initial begin:test
    //ck     <= 1'b0;
    cke    <= 1'b0;
    cs_n   <= 1'bz;
    ras_n  <= 1'bz;
    cas_n  <= 1'bz;
    we_n   <= 1'bz;
    a      <= {ADDR_BITS{1'bz}}; 
    ba     <= {BA_BITS{1'bz}};
    dq_en  <= 1'b0;
    dqs_en <= 1'b0;
    power_up;
    nop (10); // wait 10 clocks intead of 200 us for simulation purposes
    precharge('h00000000, 1);
    nop(trp);
    refresh;
    nop(trfc);
    refresh;
    nop(trfc);
    load_mode('h0, 'b011_0_001); // CL3 BT0 BL2
    nop(tmrd);
    load_mode('h2, 'b0);
    nop(tmrd);
    activate('h0, 'h1);
    nop(1);
    activate('h3, 'h1);
    write('h0, 'hb8, 1, 0, {$random,$random});
    nop(1);
    write('h3, 'h60, 0, 0, {$random,$random});
    write('h3, 'h62, 0, 0, {$random,$random});
    write('h3, 'h64, 0, 0, {$random,$random});
    write('h3, 'h66, 0, 0, {$random,$random});
    write('h3, 'h68, 0, 0, {$random,$random});
    write('h3, 'h6a, 1, 0, {$random,$random});
    activate('h0, 'h1);
    nop(10);



    read('h0, 'hb8, 1);
    nop(bl/2-1);
    nop('h00000014);
    test_done;
end
