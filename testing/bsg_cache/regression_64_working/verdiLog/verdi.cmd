simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/out/test_stride1/waveform.fsdb
wvCreateWindow
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvUnselectUserMarker -win $_nWave2
wvRestoreMarker -win $_nWave2 -file \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/marker.rpt"
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
wvZoom -win $_nWave2 587951.872200 8113735.836364
wvSelectSignal -win $_nWave2 {( "Cache Packet" 2 )} 
wvSelectSignal -win $_nWave2 {( "Cache Packet" 3 )} 
wvSetSearchMode -win $_nWave2 -value 10014
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvZoom -win $_nWave2 3129454.133826 3298015.829993
wvZoom -win $_nWave2 3230835.443839 3234277.744617
wvZoom -win $_nWave2 3233046.407777 3233094.028538
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
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
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
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
wvSearchPrev -win $_nWave2
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
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvSelectSignal -win $_nWave2 {( "G7" 3 )} 
wvSelectSignal -win $_nWave2 {( "G7" 4 )} 
wvSelectSignal -win $_nWave2 {( "G7" 3 )} 
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvSelectSignal -win $_nWave2 {( "G6" 1 )} 
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 3233113.743339
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSignalViewSetFilter "miss_v"
srcSignalViewSelect "testbench.DUT.miss_v"
wvScrollUp -win $_nWave2 21
wvScrollDown -win $_nWave2 0
srcSignalViewSelect "testbench.DUT.miss_v"
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss_v"
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvScrollDown -win $_nWave2 5
wvSelectGroup -win $_nWave2 {G3}
wvSelectGroup -win $_nWave2 {G4}
wvScrollDown -win $_nWave2 7
wvScrollDown -win $_nWave2 10
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectGroup -win $_nWave2 {G5}
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
wvSetCursor -win $_nWave2 3233116.503963 -snap {("G7" 2)}
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
wvSetCursor -win $_nWave2 3233116.503963
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 11
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
wvSetCursor -win $_nWave2 3233118.260724 -snap {("G7" 3)}
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 5
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 2
wvScrollDown -win $_nWave2 8
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvSetSearchMode -win $_nWave2 -value fcfdfeff000102f9
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
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
wvSetCursor -win $_nWave2 3307614.667963
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
wvSelectSignal -win $_nWave2 {( "Cache Packet" 3 )} 
wvSelectGroup -win $_nWave2 {Cache Packet}
wvSetMarker -win $_nWave2 -keepViewRange -name "?" 3307614.668000 ID_ORANGE5 \
           long_dashed
wvSetSearchMode -win $_nWave2 -value 10004
wvSearchPrev -win $_nWave2
wvSelectSignal -win $_nWave2 {( "Cache Packet" 3 )} 
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
tfgGenerate -incr -ref "testbench.cache_pkt.addr\[29:0\]#2637930#T" -startWithStmt -schFG
tfgNodeTraceActTrans -win $_tFlowView3 -folder "group_0#T" "testbench.cache_pkt.addr\[29:0\]" -stopLevel 10
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSetSearchMode -win $_nWave2 -value 10014
wvSearchPrev -win $_nWave2
wvSetCursor -win $_nWave2 3233096.125540
wvSelectGroup -win $_nWave2 {Cache Packet}
wvSetMarker -win $_nWave2 -keepViewRange -name "SAME t" 3233096.126000 ID_ORANGE5 \
           long_dashed
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
wvSetCursor -win $_nWave2 3233113.191215 -snap {("G6" 1)}
wvSetCursor -win $_nWave2 3233122.727916 -snap {("G6" 1)}
wvSetCursor -win $_nWave2 3233096.627472 -snap {("G6" 1)}
wvSetCursor -win $_nWave2 3233128.751095 -snap {("G6" 1)}
wvSetCursor -win $_nWave2 3233118.461497
wvSelectSignal -win $_nWave2 {( "G6" 1 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/dma0/rd_upper_addr\[10:0\]" -driver
wvSelectSignal -win $_nWave2 \
           {( "G6//testbench/dma0/rd_upper_addr@3233110(1ps)#ActiveDriver" \
           1 )} 
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/rd_upper_addr@3233110(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 1)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_r\[16:6\]"
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 2 -win $_nTrace1 -name \
          "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -ctrlKey \
          off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_n\[29:0\]"
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 10
wvSetPosition -win $_nWave2 {("Cache Output" 4)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
srcAction -pos 150 5 4 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3233096.878438
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
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
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
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
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_pkt.addr\[29:0\]"
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
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
srcAction -pos 100 3 7 -win $_nTrace1 -name "dma_pkt.addr" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_pkt_i\[38:0\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
srcAction -pos 52 7 5 -win $_nTrace1 -name "dma_pkt_i" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcAction -pos 161 7 3 -win $_nTrace1 -name "dma_pkt" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcAction -pos 262 1 5 -win $_nTrace1 -name \
          "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_tag_v" -line 336 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
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
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_tag_v\[17:0\]"
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
srcSelect -signal "addr_tag_v" -line 336 -pos 1 -win $_nTrace1
srcAction -pos 335 1 2 -win $_nTrace1 -name "addr_tag_v" -ctrlKey off
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 6
wvScrollUp -win $_nWave2 6
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G7" 2 )} 
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 9
wvScrollDown -win $_nWave2 7
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
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
wvSetCursor -win $_nWave2 3232528.014244 -snap {("Cache Packet" 3)}
wvSetSearchMode -win $_nWave2 -value 14
wvSearchPrev -win $_nWave2
wvSelectSignal -win $_nWave2 {( "Cache Packet" 3 )} 
wvSearchPrev -win $_nWave2
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvSearchNext -win $_nWave2
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
wvScrollDown -win $_nWave2 6
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 3
wvScrollUp -win $_nWave2 5
wvScrollUp -win $_nWave2 1
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
wvSelectSignal -win $_nWave2 {( "G6" 1 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSetSearchMode -win $_nWave2 -value 0
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvSetCursor -win $_nWave2 4034662.023236 -snap {("G3" 0)}
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 7
wvScrollDown -win $_nWave2 4
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSearchNext -win $_nWave2
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvSearchNext -win $_nWave2
wvSetCursor -win $_nWave2 4034679.114008
wvSetCursor -win $_nWave2 4034697.183546
wvSearchNext -win $_nWave2
wvSetCursor -win $_nWave2 4818016.278094
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/dma0/dma_data_o\[63:0\]" \
           -driver
wvSelectGroup -win $_nWave2 \
           {G6//testbench/dma0/dma_data_o@4818010(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetCursor -win $_nWave2 4817997.706625
wvSetCursor -win $_nWave2 4818009.752984
wvSetCursor -win $_nWave2 4818019.791616
wvSetCursor -win $_nWave2 4818037.861154
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 4817993.942138
wvSelectUserMarker -win $_nWave2 -previous
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 51 -win $_nTrace1
srcAction -pos 80 7 51 -win $_nTrace1 -name \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_counter_n" -line 152 -pos 1 -win $_nTrace1
srcAction -pos 151 5 4 -win $_nTrace1 -name "rd_counter_n" -ctrlKey off
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
wvScrollUp -win $_nWave2 1
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 23
wvScrollDown -win $_nWave2 21
wvScrollDown -win $_nWave2 2
srcHBSelect "testbench.dma0" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.dma0" -delim "."
srcHBSelect "testbench.dma0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 43 -pos 1 -win $_nTrace1
srcTraceLoad "testbench.dma0.dma_data_i\[63:0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{wr_upper_addr, \{\(block_size_in_words_p>1\)\{wr_counter_r\}\}\}\]\[i*word_width_lp+:word_width_lp\]" \
          -line 277 -pos 1 -partailSelPos 12 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{wr_upper_addr, \{\(block_size_in_words_p>1\)\{wr_counter_r\}\}\}\]\[i*word_width_lp+:word_width_lp\]" \
          -line 277 -pos 1 -partailSelPos 11 -win $_nTrace1
srcSelect -win $_nTrace1 -range {277 277 2 2 8 12} -backward
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{wr_upper_addr, \{\(block_size_in_words_p>1\)\{wr_counter_r\}\}\}\]\[i*word_width_lp+:word_width_lp\]" \
          -line 277 -pos 1 -partailSelPos 9 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvAddSignal -win $_nWave2 "/testbench/dma0/wr_upper_addr\[10:0\]"
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvScrollDown -win $_nWave2 7
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_mask_li\[i\]" -line 276 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_mask_li\[0:0\]"
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 1)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_mask_li\[i\]" -line 276 -pos 1 -win $_nTrace1
srcAction -pos 275 4 2 -win $_nTrace1 -name "dma_mask_li\[i\]" -ctrlKey off
srcHBSelect "testbench.dma0.mux" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.dma0.mux"
srcSelect -win $_nTrace1 -range {181 181 4 5 1 1}
srcHBSelect "testbench.dma0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_mask_li" -line 184 -pos 1 -win $_nTrace1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
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
wvSetCursor -win $_nWave2 3307638.007819
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_yumi_o" -line 274 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_data_yumi_o"
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 5)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSelectGroup -win $_nWave2 {G7}
wvSetCursor -win $_nWave2 3307649.552246
wvSetCursor -win $_nWave2 3307637.254922
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_v_i" -line 274 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 4)}
wvSetPosition -win $_nWave2 {("Cache Packet" 3)}
wvSetPosition -win $_nWave2 {("Cache Packet" 2)}
wvSetPosition -win $_nWave2 {("Cache Packet" 1)}
wvSetPosition -win $_nWave2 {("Cache Packet" 0)}
srcDeselectAll -win $_nTrace1
wvScrollDown -win $_nWave2 0
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_v_i" -line 274 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_data_v_i"
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G8" 6)}
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 6 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/DUT/dma/dma_data_v_i" \
           -driver
wvSelectGroup -win $_nWave2 \
           {G8//testbench/DUT/dma/dma_data_v_i@3307630(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 4)}
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G8" 6 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSelectSignal -win $_nWave2 {( "G8" 4 5 )} 
wvSelectSignal -win $_nWave2 {( "G8" 5 )} 
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetCursor -win $_nWave2 3307679.718336
wvSetCursor -win $_nWave2 3307701.050430
wvUnselectUserMarker -win $_nWave2
wvSetCursor -win $_nWave2 3307681.726063
wvSetCursor -win $_nWave2 3307698.540772
wvSetCursor -win $_nWave2 3307679.216405
wvSetCursor -win $_nWave2 3307699.795601
wvSetCursor -win $_nWave2 3307681.977029
wvSetCursor -win $_nWave2 3307700.046567
wvSetCursor -win $_nWave2 3307680.722200
wvSetCursor -win $_nWave2 3307703.811054
wvSetCursor -win $_nWave2 3307677.961576
wvSetCursor -win $_nWave2 3307702.054293
wvSetCursor -win $_nWave2 3307675.953849
wvSetCursor -win $_nWave2 3307695.278216
wvSetCursor -win $_nWave2 3307676.204815
wvSetCursor -win $_nWave2 3307697.536909
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvSelectSignal -win $_nWave2 {( "G8" 1 )} 
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvSearchNext -win $_nWave2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3598495.851453
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i\[i*word_width_lp+:word_width_lp\]" -line 277 -pos 1 \
          -win $_nTrace1
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G8" 5)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_data_i\[63:0\]"
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSelectSignal -win $_nWave2 {( "G8" 5 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 5 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvScrollDown -win $_nWave2 1
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/dma_data_i\[63:0\]" -driver
wvScrollDown -win $_nWave2 2
wvSelectGroup -win $_nWave2 \
           {G8//testbench/DUT/dma/dma_data_i@3598490(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 5 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 4 )} 
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvSelectSignal -win $_nWave2 {( "G8" 3 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 6
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
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3598519.442239
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
srcHBSelect "testbench.dma0" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.dma0" -delim "."
srcHBSelect "testbench.dma0" -win $_nTrace1
wvScrollUp -win $_nWave2 15
wvScrollUp -win $_nWave2 10
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/signal copy.rc" \
           -overWriteAutoAlias on -appendSignals on
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
wvScrollDown -win $_nWave2 11
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 7
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 7
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 11
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
wvScrollUp -win $_nWave2 1
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 64
wvScrollUp -win $_nWave2 64
wvSelectGroup -win $_nWave2 {Cache Packet}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G4" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 4)}
wvSelectGroup -win $_nWave2 {Cache Output}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G3" 4)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSelectGroup -win $_nWave2 {G3}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSelectGroup -win $_nWave2 {G4}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSelectGroup -win $_nWave2 {G5}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSelectGroup -win $_nWave2 {G6}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSelectGroup -win $_nWave2 {G7}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSelectGroup -win $_nWave2 {G8}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSelectGroup -win $_nWave2 {G9}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/signal copy.rc" \
           -overWriteAutoAlias on -appendSignals on
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
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
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -previous
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
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvUnselectUserMarker -win $_nWave2
wvSetCursor -win $_nWave2 3233075.470143 -snap {("Cache Packet" 6)}
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSetCursor -win $_nWave2 3233076.419837
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
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 2 )} 
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvScrollDown -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_o" -line 39 -pos 1 -win $_nTrace1
srcAction -pos 38 14 3 -win $_nTrace1 -name "dma_data_o" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 51 -win $_nTrace1
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
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_counter_r\[2:0\]"
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 3233165.216281 -snap {("G6" 4)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
srcDeselectAll -win $_nTrace1
srcSelect -signal \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -line 81 -pos 1 -partailSelPos 10 -win $_nTrace1
srcAction -pos 80 7 10 -win $_nTrace1 -name \
          "mem\[\{rd_upper_addr, \{\(block_size_in_words_p>1\)\{rd_counter_r\}\}\}\]" \
          -ctrlKey off
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
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_r\[16:6\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
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
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 5 -win $_nTrace1 -name \
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
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_n\[29:0\]"
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvSetPosition -win $_nWave2 {("G6" 4)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetCursor -win $_nWave2 3233119.156094 -snap {("G6" 5)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r" -line 151 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_addr_r\[29:0\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 7 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_upper_addr" -line 80 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcAction -pos 78 6 0 -win $_nTrace1 -name "1" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 5 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvSelectSignal -win $_nWave2 {( "G6" 6 )} 
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -line \
          80 -pos 1 -win $_nTrace1
srcAction -pos 79 7 3 -win $_nTrace1 -name \
          "rd_addr_r\[block_offset_width_lp+:upper_addr_width_lp\]" -ctrlKey \
          off
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_addr_n" -line 151 -pos 1 -win $_nTrace1
srcAction -pos 150 5 3 -win $_nTrace1 -name "rd_addr_n" -ctrlKey off
wvSelectSignal -win $_nWave2 {( "G6" 3 )} 
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_req_delay_zero" -line 100 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {100 100 10 10 4 8} -backward
srcDeselectAll -win $_nTrace1
srcSelect -signal "rd_req_delay_zero" -line 100 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/rd_req_delay_zero"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSelectSignal -win $_nWave2 {( "G6" 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
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
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G8" 4)}
wvSetPosition -win $_nWave2 {("G8" 3)}
wvSetPosition -win $_nWave2 {("G8" 2)}
wvSetPosition -win $_nWave2 {("G8" 1)}
wvSetPosition -win $_nWave2 {("G8" 0)}
wvSetPosition -win $_nWave2 {("G7" 4)}
wvSetPosition -win $_nWave2 {("G7" 3)}
wvSetPosition -win $_nWave2 {("G7" 2)}
wvSetPosition -win $_nWave2 {("G7" 1)}
wvSetPosition -win $_nWave2 {("G7" 0)}
wvSetPosition -win $_nWave2 {("G6" 8)}
wvSetPosition -win $_nWave2 {("G6" 7)}
wvSetPosition -win $_nWave2 {("G6" 6)}
wvSetPosition -win $_nWave2 {("G6" 5)}
wvSetPosition -win $_nWave2 {("G6" 4)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("Cache Output" 2)}
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvAddSignal -win $_nWave2 "/testbench/dma0/dma_pkt.addr\[29:0\]"
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 4)}
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
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 101 -pos 1 -win $_nTrace1
srcAction -pos 100 3 7 -win $_nTrace1 -name "dma_pkt.addr" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt_i" -line 53 -pos 1 -win $_nTrace1
srcAction -pos 52 7 2 -win $_nTrace1 -name "dma_pkt_i" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcAction -pos 161 7 2 -win $_nTrace1 -name "dma_pkt" -ctrlKey off
wvSetCursor -win $_nWave2 3233103.676072
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 5)}
wvSetPosition -win $_nWave2 {("Cache Packet" 6)}
wvSetPosition -win $_nWave2 {("Cache Packet" 7)}
wvSetPosition -win $_nWave2 {("Cache Packet" 8)}
wvSetPosition -win $_nWave2 {("Cache Output" 0)}
wvSetPosition -win $_nWave2 {("Cache Output" 1)}
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 2)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/dma_addr_i\[29:6\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 263 \
          -pos 1 -win $_nTrace1
srcAction -pos 262 1 3 -win $_nTrace1 -name \
          "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_tag_v" -line 336 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("Cache Output" 3)}
wvSetPosition -win $_nWave2 {("G6" 0)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_tag_v\[17:0\]"
wvSetPosition -win $_nWave2 {("G6" 0)}
wvSetPosition -win $_nWave2 {("G6" 1)}
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
srcDeselectAll -win $_nTrace1
srcSelect -signal "addr_index_v" -line 337 -pos 1 -win $_nTrace1
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
wvSetPosition -win $_nWave2 {("G6" 3)}
wvSetPosition -win $_nWave2 {("G6" 1)}
wvAddSignal -win $_nWave2 "/testbench/DUT/miss/addr_index_v\[5:0\]"
wvSetPosition -win $_nWave2 {("G6" 1)}
wvSetPosition -win $_nWave2 {("G6" 2)}
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 10608430.646562 11952749.681663
wvZoom -win $_nWave2 10923601.710454 10952653.791763
wvZoom -win $_nWave2 10930393.847337 10930793.384801
wvZoomAll -win $_nWave2
