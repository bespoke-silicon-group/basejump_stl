simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64_working/out/test_random1/waveform.fsdb
wvCreateWindow
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
wvSetCursor -win $_nWave2 116134.823570
wvRestoreSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
wvZoomAll -win $_nWave2
wvSetCursor -win $_nWave2 2455281.682243
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 1999241.490889 -snap {("G1" 1)}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSelectSignal -win $_nWave2 {( "G2" 1 )} 
wvExpandBus -win $_nWave2
wvSetCursor -win $_nWave2 2396788.725811
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetSearchMode -win $_nWave2 -value f080
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvPanRight -win $_nWave2
wvPanRight -win $_nWave2
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
wvSetCursor -win $_nWave2 2397237.411065 -snap {("G1" 3)}
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
wvPanRight -win $_nWave2
wvPanLeft -win $_nWave2
wvSetCursor -win $_nWave2 2397240.972059
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/DUT/data_o\[63:0\]" \
           -driver
srcDeselectAll -win $_nTrace1
srcSelect -signal "ld_data_final_lo" -line 962 -pos 1 -win $_nTrace1
srcAction -pos 961 5 5 -win $_nTrace1 -name "ld_data_final_lo" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "data_i\[sel_i\]" -line 20 -pos 1 -win $_nTrace1
srcAction -pos 19 7 2 -win $_nTrace1 -name "data_i\[sel_i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "byte_sel" -line 935 -pos 1 -win $_nTrace1
srcAction -pos 934 26 4 -win $_nTrace1 -name "byte_sel" -ctrlKey off
srcHBSelect "testbench.DUT.ld_data_sel\[0\].byte_mux" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.ld_data_sel\[0\].byte_mux"
srcSelect -win $_nTrace1 -range {928 928 4 5 1 1}
srcHBSelect "testbench.DUT.ld_data_sel\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_or_ld_data" -line 929 -pos 1 -win $_nTrace1
srcAction -pos 928 4 4 -win $_nTrace1 -name "snoop_or_ld_data" -ctrlKey off
wvSelectGroup -win $_nWave2 {G1//testbench/DUT/data_o@2397230(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetCursor -win $_nWave2 2397318.275306
wvSetCursor -win $_nWave2 2397775.269547
wvSetCursor -win $_nWave2 2397755.684079
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_lo" -line 902 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.snoop_word_lo\[63:0\]" -win $_nTrace1
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_n" -line 414 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.dma.snoop_word_n\[63:0\]" -win $_nTrace1
srcHBSelect "testbench.DUT.dma.snoop_mux0" -win $_nTrace1
srcHBSelect "testbench.DUT.dma.snoop_mux0" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.dma.snoop_mux0"
srcSelect -win $_nTrace1 -range {399 399 4 5 1 1}
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "in_fifo_data_lo" -line 400 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
srcActiveTrace "testbench.DUT.dma.in_fifo_data_lo\[63:0\]" -win $_nTrace1
srcHBSelect "testbench.DUT.dma.in_fifo.unhardened.un.fifo" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.dma.in_fifo.unhardened.un.fifo"
srcSelect -win $_nTrace1 -range {51 51 4 5 1 1}
srcHBSelect "testbench.DUT.dma.in_fifo.unhardened.un" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -word -line 51 -pos 2 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 10)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSelectSignal -win $_nWave2 {( "G2" 3 4 5 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 6)}
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 6)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSelectSignal -win $_nWave2 {( "G2" 5 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSelectSignal -win $_nWave2 {( "G2" 3 4 )} 
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/in_fifo/data_i\[63:0\]" -driver
wvSelectGroup -win $_nWave2 \
           {G2//testbench/DUT/dma/in_fifo/data_i@2397550(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 4)}
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
wvScrollDown -win $_nWave2 0
srcHBSelect "testbench.dma0" -win $_nTrace1
srcDeselectAll -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/in_fifo/data_i\[63:0\]" -load
srcDeselectAll -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/in_fifo_data_lo\[63:0\]" -driver
srcHBSelect "testbench.DUT.dma.in_fifo" -win $_nTrace1
srcHBSelect "testbench.DUT.dma.in_fifo" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.dma.in_fifo"
srcSelect -win $_nTrace1 -range {130 130 4 5 1 1}
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSelectGroup -win $_nWave2 \
           {G2//testbench/DUT/dma/in_fifo_data_lo@2397750(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSelectSignal -win $_nWave2 {( "G2" 3 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 133 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 133 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetCursor -win $_nWave2 2397638.171275
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSelectGroup -win $_nWave2 {G2//testbench/DUT/dma/in_fifo/data_i#Load}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSelectSignal -win $_nWave2 {( "G2" 2 3 )} 
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSetPosition -win $_nWave2 {("G2" 3)}
wvCollapseBus -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetCursor -win $_nWave2 2397384.747195
wvExpandBus -win $_nWave2
wvSetCursor -win $_nWave2 2397318.868805
wvSetCursor -win $_nWave2 2397759.838572
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
srcSignalViewSort -name
wvShowOneTraceSignals -win $_nWave2 -signal "/testbench/DUT/data_o\[63:0\]" \
           -driver
srcDeselectAll -win $_nTrace1
srcSelect -signal "ld_data_final_lo" -line 962 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "ld_data_final_lo" -line 962 -pos 1 -win $_nTrace1
srcAction -pos 961 5 5 -win $_nTrace1 -name "ld_data_final_lo" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "data_i\[sel_i\]" -line 20 -pos 1 -win $_nTrace1
srcAction -pos 19 7 1 -win $_nTrace1 -name "data_i\[sel_i\]" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "byte_sel" -line 935 -pos 1 -win $_nTrace1
srcAction -pos 934 26 2 -win $_nTrace1 -name "byte_sel" -ctrlKey off
srcHBSelect "testbench.DUT.ld_data_sel\[0\].byte_mux" -win $_nTrace1
srcHBSelect "testbench.DUT.ld_data_sel\[0\].byte_mux" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.ld_data_sel\[0\].byte_mux"
srcSelect -win $_nTrace1 -range {928 928 4 5 1 1}
srcHBSelect "testbench.DUT.ld_data_sel\[0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_or_ld_data" -line 929 -pos 1 -win $_nTrace1
srcAction -pos 928 4 9 -win $_nTrace1 -name "snoop_or_ld_data" -ctrlKey off
wvSelectGroup -win $_nWave2 {G1//testbench/DUT/data_o@2397750(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 3)}
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 0
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_lo" -line 902 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.snoop_word_lo\[63:0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_n" -line 414 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 8)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 10)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G2" 10)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 8)}
wvSetPosition -win $_nWave2 {("G2" 7)}
wvSetPosition -win $_nWave2 {("G2" 6)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 6)}
wvSetPosition -win $_nWave2 {("G2" 7)}
wvSetPosition -win $_nWave2 {("G2" 8)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 10)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 8)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/snoop_word_n\[63:0\]"
wvSetPosition -win $_nWave2 {("G2" 8)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSelectSignal -win $_nWave2 {( "G2" 9 )} 
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSelectSignal -win $_nWave2 {( "G2" 9 )} 
wvSetPosition -win $_nWave2 {("G2" 8)}
wvSetPosition -win $_nWave2 {("G2" 7)}
wvSetPosition -win $_nWave2 {("G2" 6)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 2397739.659606
wvSetCursor -win $_nWave2 2397717.700142
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_o" -line 414 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.dma.snoop_word_o\[63:0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_o" -line 414 -pos 1 -win $_nTrace1
srcAction -pos 413 1 5 -win $_nTrace1 -name "snoop_word_o" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_we" -line 413 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {413 413 5 5 8 9}
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_we" -line 413 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {413 413 5 5 5 8} -backward
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_we" -line 413 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvSetCursor -win $_nWave2 2397688.025192
wvSetCursor -win $_nWave2 2397759.838572
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_o" -line 414 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {414 414 2 2 7 8}
srcDeselectAll -win $_nTrace1
srcSelect -signal "snoop_word_o" -line 414 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 5)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 9)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/snoop_word_o\[63:0\]"
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSelectSignal -win $_nWave2 {( "G2" 1 )} 
wvSaveSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc"
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
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
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 2397759.838572
wvSetCursor -win $_nWave2 3898524.453208
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 3898641.372514
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 3898631.283031 -snap {("G2" 2)}
wvSetCursor -win $_nWave2 3898641.372514
wvSelectSignal -win $_nWave2 {( "G2" 3 )} 
wvSelectSignal -win $_nWave2 {( "G2" 8 )} 
wvSetSearchMode -win $_nWave2 -value 10B8
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
srcHBSelect "testbench" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench" -delim "."
srcHBSelect "testbench" -win $_nTrace1
srcSignalViewSelect "testbench.dma_pkt"
srcSignalViewSelect "testbench.dma_pkt"
srcSignalViewExpand "testbench.dma_pkt"
srcSignalViewSelect "testbench.dma_pkt.addr\[29:0\]"
srcSignalViewSelect "testbench.dma_pkt.addr\[29:0\]"
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 66 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.dma_pkt" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt" -line 162 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.dma.dma_pkt" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 250 \
          -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/dma_addr_i\[29:6\]"
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_pkt.addr" -line 249 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma/dma_pkt.addr\[29:0\]"
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSelectSignal -win $_nWave2 {( "G1" 10 11 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 9)}
srcDeselectAll -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 9)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_i\[addr_width_p-1:block_offset_width_lp\]" -line 250 \
          -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.dma.dma_addr_i\[29:6\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "invalid_way_id" -line 323 -pos 1 -win $_nTrace1
srcSelect -win $_nTrace1 -range {323 341 19 1 3 1}
srcDeselectAll -win $_nTrace1
wvSetCursor -win $_nWave2 3898579.055118
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSelectSignal -win $_nWave2 {( "G1" 5 6 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetCursor -win $_nWave2 3898652.648995
wvSetCursor -win $_nWave2 3898519.111717
wvSetCursor -win $_nWave2 3898522.079212
wvSetCursor -win $_nWave2 3898511.989729
srcHBSelect "testbench.DUT.miss" -win $_nTrace1
srcHBSelect "testbench.dma0" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.dma0" -delim "."
srcHBSelect "testbench.dma0" -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/testbench/DUT/dma/in_fifo_data_lo\[63:0\]" -driver
srcDeselectAll -win $_nTrace1
srcSelect -signal "w_v_i" -line 50 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "mem\[r_addr_i\]" -line 47 -pos 1 -partailSelPos 7 -win \
          $_nTrace1
srcHBSelect "testbench.DUT.dma.in_fifo" -win $_nTrace1
srcHBSelect "testbench.DUT.dma.in_fifo" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.dma.in_fifo"
srcSelect -win $_nTrace1 -range {130 130 4 5 1 1}
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 133 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_data_i" -line 133 -pos 1 -win $_nTrace1
srcActiveTrace "testbench.DUT.dma.dma_data_i\[63:0\]" -win $_nTrace1
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcHBSelect "testbench.DUT.dma" -win $_nTrace1
srcShowCalling -win $_nTrace1 "testbench.DUT.dma"
srcSelect -win $_nTrace1 -range {526 526 4 5 1 1}
srcHBSelect "testbench.DUT" -win $_nTrace1
wvSelectGroup -win $_nWave2 \
           {G2//testbench/DUT/dma/in_fifo_data_lo@3898510(1ps)#ActiveDriver}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 4)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "dma_addr_lo" -line 532 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetPosition -win $_nWave2 {("G2" 3)}
wvAddSignal -win $_nWave2 "/testbench/DUT/dma_addr_lo\[29:0\]"
wvSetPosition -win $_nWave2 {("G2" 3)}
wvSetPosition -win $_nWave2 {("G2" 4)}
wvSetCursor -win $_nWave2 3892632.194994 -snap {("G1" 1)}
wvSetSearchMode -win $_nWave2 -anyChange
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSearchPrev -win $_nWave2
wvSetCursor -win $_nWave2 2396764.095601
wvScrollDown -win $_nWave2 0
wvSetCursor -win $_nWave2 2396946.299799 -snap {("G1" 7)}
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvSelectSignal -win $_nWave2 {( "G2" 4 )} 
wvSetSearchMode -win $_nWave2 -value 10B8
wvSetSearchMode -win $_nWave2 -value f080
wvSearchNext -win $_nWave2
