simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/out/test_stride1/waveform.fsdb
wvCreateWindow
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT.dma" -delim "."
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT.dma" -delim "."
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcHBSelect "testbench.DUT.miss" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT.miss" -delim "."
srcHBSelect "testbench.DUT.miss" -win $_nTrace1
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G4}
wvSelectGroup -win $_nWave2 {G4}
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943329.344143
wvSetCursor -win $_nWave2 3943340.740478
wvSelectSignal -win $_nWave2 {( "G8" 1 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/dma_addr_i\[29:6\]" -driver
wvSelectGroup -win $_nWave2 \
           {G8//testbench/DUT/dma/dma_addr_i[29:6]@3943330(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 1)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G6" 1 )} 
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943373.504941 -snap {("G6" 2)}
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/dma0/rd_upper_addr\[10:0\]" -driver
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/rd_upper_addr@3943350(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 2)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 3 -win $_nTrace1 -name \
          "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -ctrlKey \
          off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
srcAction -pos 150 5 2 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
wvSetCursor -win $_nWave2 3943335.042310
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
srcAction -pos 100 3 1 -win $_nTrace1 -name "dma_pkt.addr" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
srcAction -pos 52 7 3 -win $_nTrace1 -name "dma_pkt_i" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcAction -pos 161 7 3 -win $_nTrace1 -name "dma_pkt" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcAction -pos 262 1 4 -win $_nTrace1 -name \
          "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_tag_v" -line 337 -pos 1 -win $_nTrace1
srcAction -pos 336 1 3 -win $_nTrace1 -name "addr_tag_v" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_v_i\[block_offset_width_lp+:tag_width_lp\]" -line 170 \
          -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_v_i\[29:6\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSetCursor -win $_nWave2 3943372.080399 -snap {("Cache Packet" 0)}
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
srcSignalViewSelect "testbench.DUT.miss.miss_v_i"
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSignalViewSetFilter "miss_v"
srcSignalViewSelect "testbench.DUT.miss_v"
srcSignalViewSelect "testbench.DUT.miss_v"
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss_v"
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943328.394448
wvSetCursor -win $_nWave2 3943334.567463
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 1 )} 
wvScrollDown -win $_nWave2 8
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G8" 2 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
wvSetCursor -win $_nWave2 3943337.416546
wvSetCursor -win $_nWave2 3943340.265629
wvSetCursor -win $_nWave2 3943343.589561
wvSetCursor -win $_nWave2 3943349.287728
wvSetCursor -win $_nWave2 3943357.360132
wvSetCursor -win $_nWave2 3943342.639866
wvSetCursor -win $_nWave2 3943335.992004
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943369.706162
wvSetCursor -win $_nWave2 3943383.951580
wvSetCursor -win $_nWave2 3943381.577344
wvSetCursor -win $_nWave2 3943403.895167
wvSetCursor -win $_nWave2 3943424.788448
wvSetCursor -win $_nWave2 3943444.732034
wvSetCursor -win $_nWave2 3943460.401995
wvSetCursor -win $_nWave2 3943477.021650
wvSetCursor -win $_nWave2 3943502.663404
wvSetCursor -win $_nWave2 3943529.254852
wvSetCursor -win $_nWave2 3943564.868399
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943359.259521
wvSetCursor -win $_nWave2 3943349.762575
wvSetCursor -win $_nWave2 3943365.432536
wvSetCursor -win $_nWave2 3943346.438644
wvSetCursor -win $_nWave2 3943376.828871
wvSetCursor -win $_nWave2 3943343.589561
wvSetCursor -win $_nWave2 3943369.231314
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "Cache Packet" 4 )} 
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3942759.289967
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 7
wvScrollUp -win $_nWave2 11
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/dma_data_o\[63:0\]" \
           -driver
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/dma_data_o@3942370(1ps)#ActiveDriver}
wvScrollDown -win $_nWave2 12
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/dma_data_o@3942370(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvScrollUp -win $_nWave2 11
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/dma_data_o\[63:0\]" \
           -driver
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/dma_data_o@3942370(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_o" -line 81 -pos 1 -win $_nTrace1
srcAction -pos 80 3 2 -win $_nTrace1 -name "dma_data_o" -ctrlKey off
wvSetCursor -win $_nWave2 3943368.471559
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_data_o\[63:0\]"
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvScrollDown -win $_nWave2 7
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/dma_data_i\[63:0\]" \
           -driver
wvSelectGroup -win $_nWave2 \
           {G7//testbench/dma0/dma_data_i@3942990(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
srcHBSelect "testbench.dma0" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.dma0" -delim "."
srcHBSelect "testbench.dma0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 43 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_data_i\[63:0\]"
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvScrollUp -win $_nWave2 4
wvSaveSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc"
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G7" 3 )} 
wvSelectSignal -win $_nWave2 {( "G7" 1 )} 
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943322.411372
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3943339.980722
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/start_read" -load
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvSelectGroup -win $_nWave2 {G6//testbench/dma0/start_read#Load}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/dma_data_o\[63:0\]" \
           -driver
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/dma_data_o@3942950(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 10 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 12 -win $_nTrace1
srcAction -pos 80 7 12 -win $_nTrace1 -name \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 3 -win $_nTrace1 -name \
          "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -ctrlKey \
          off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
srcAction -pos 150 5 3 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 100 -pos 1 -win $_nTrace1
srcAction -pos 99 1 6 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_o" -line 39 -pos 1 -win $_nTrace1
srcAction -pos 38 14 7 -win $_nTrace1 -name "dma_data_o" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 53 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_counter_r\[2:0\]"
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSetCursor -win $_nWave2 3943372.270338
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 10 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 10 -win $_nTrace1
srcAction -pos 80 7 10 -win $_nTrace1 -name \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_r\[16:6\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 3 -win $_nTrace1 -name \
          "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -ctrlKey \
          off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_n\[29:0\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
srcAction -pos 150 5 4 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {101 101 4 4 7 10}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_pkt.addr\[29:0\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 3943333.807707
wvSetCursor -win $_nWave2 3943341.880111
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
srcAction -pos 100 3 4 -win $_nTrace1 -name "dma_pkt.addr" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
srcAction -pos 52 7 4 -win $_nTrace1 -name "dma_pkt_i" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcAction -pos 161 7 3 -win $_nTrace1 -name "dma_pkt" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/dma_addr_i\[29:6\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcAction -pos 262 1 5 -win $_nTrace1 -name \
          "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_tag_v" -line 337 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_tag_v\[23:0\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_index_v" -line 338 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_index_v\[0:0\]"
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
wvSaveSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc"
wvSelectSignal -win $_nWave2 {( "Cache Packet" 1 )} 
wvReportMarker -win $_nWave2 -toFile \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/marker.rpt"
debExit
