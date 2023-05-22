simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/out/test_random1/waveform.fsdb
wvCreateWindow
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSignalViewSetFilter "tag_hit_v"
srcSignalViewSelect "testbench.DUT.tag_hit_v\[7:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 "/testbench/DUT/tag_hit_v\[7:0\]"
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetCursor -win $_nWave2 2397231.030951
wvSetCursor -win $_nWave2 2397211.445483
srcSignalViewSetFilter "v_r_"
srcSignalViewSetFilter "v_r_r"
srcSignalViewSetFilter "v_v_r"
srcSignalViewSelect "testbench.DUT.v_v_r"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 "/testbench/DUT/v_v_r"
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetSearchMode -win $_nWave2 -anyChange
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvSetOptions -win $_nWave2 -fixedDelta on
srcSignalViewSetFilter "reset_i"
srcSignalViewSelect "testbench.DUT.reset_i"
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvAddSignal -win $_nWave2 "/testbench/DUT/reset_i"
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetCursor -win $_nWave2 2402899.598422
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetRadix -win $_nWave2 -format Bin
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetRadix -win $_nWave2 -format Hex
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench" -win $_nTrace1
