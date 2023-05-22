simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/out/test_random1/waveform.fsdb
wvCreateWindow
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 952170.420561 1531634.133645
wvZoom -win $_nWave2 1104166.821314 1156878.162192
wvZoom -win $_nWave2 1118288.862795 1120029.486512
wvRestoreMarker -win $_nWave2 -file \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/marker.rpt"
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
wvSelectSignal -win $_nWave2 {( "G2" 1 )} 
wvSetCursor -win $_nWave2 1118614.213022 -snap {("G2" 1)}
wvSetCursor -win $_nWave2 1118619.635525
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma_pkt.addr\[29:0\]" \
           -driver
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcAction -pos 161 7 2 -win $_nTrace1 -name "dma_pkt" -ctrlKey off
srcHBSelect "testbench.DUT.miss" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT.miss" -delim "."
srcHBSelect "testbench.DUT.miss" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_index_v" -line 168 -pos 1 -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 1 )} 
wvSelectGroup -win $_nWave2 \
           {G2//testbench/dma_pkt/addr@1118510(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 1)}
wvScrollDown -win $_nWave2 3
wvScrollUp -win $_nWave2 11
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 12
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvGoToTime -win $_nWave2 186120
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
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
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSelectSignal -win $_nWave2 {( "G1" 4 5 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 3
wvScrollUp -win $_nWave2 10
wvScrollDown -win $_nWave2 0
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench" -win $_nTrace1
srcSignalViewExpand "testbench.cache_pkt"
srcSignalViewSelect "testbench.cache_pkt.addr\[29:0\]"
srcSignalViewSelect "testbench.cache_pkt.addr\[29:0\]" \
           "testbench.cache_pkt.data\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvAddSignal -win $_nWave2 "/testbench/cache_pkt.addr\[29:0\]" \
           "/testbench/cache_pkt.data\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 )} 
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/DUT/tag_hit_v\[7:0\]" \
           -driver
wvScrollUp -win $_nWave2 9
wvSetPosition -win $_nWave2 \
           {("G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver" 1)}
wvSetPosition -win $_nWave2 \
           {("G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver" 0)}
wvSetPosition -win $_nWave2 \
           {("G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 \
           {("G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver" 1)}
wvSetPosition -win $_nWave2 \
           {("G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver" 18)}
wvSelectGroup -win $_nWave2 \
           {G1//testbench/DUT/tag_hit_v@186110(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 10)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_tag_v" -line 340 -pos 1 -win $_nTrace1
srcAction -pos 339 8 6 -win $_nTrace1 -name "addr_tag_v" -ctrlKey off
debExit
