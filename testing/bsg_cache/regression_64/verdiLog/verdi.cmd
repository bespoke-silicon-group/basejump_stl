simSetSimulator "-vcssv" -exec \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv" \
           -args "-reportstats +wave=1 +checker=basic"
debImport "-dbdir" \
          "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/simv.daidir"
debLoadSimResult \
           /home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/out/test_random1/waveform.fsdb
wvCreateWindow
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSignalViewSort -name
srcSignalViewSort -name
srcSignalViewSelect "testbench.DUT.cache_pkt"
srcSignalViewAddSelectedToWave -win $_nTrace1
srcSignalViewSelect "testbench.DUT.cache_pkt"
srcSignalViewExpand "testbench.DUT.cache_pkt"
srcSignalViewSelect "testbench.DUT.cache_pkt.opcode\[5:0\]"
srcSignalViewSelect "testbench.DUT.cache_pkt.opcode\[5:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvAddSignal -win $_nWave2 "/testbench/DUT/cache_pkt.opcode\[5:0\]"
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetCursor -win $_nWave2 183297.883680 -snap {("G1" 2)}
wvScrollDown -win $_nWave2 1
srcSignalViewSelect "testbench.DUT.cache_pkt.opcode\[5:0\]"
srcSignalViewAddSelectedToWave -win $_nTrace1
srcSignalViewSelect "testbench.DUT.cache_pkt"
srcSignalViewAddSelectedToWave -win $_nTrace1
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvExpandBus -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 5 6 7 8 )} 
wvSelectSignal -win $_nWave2 {( "G1" 5 6 7 8 )} 
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetCursor -win $_nWave2 3244230.134344 -snap {("G2" 0)}
wvSetCursor -win $_nWave2 3260505.196158 -snap {("G1" 1)}
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSelectGroup -win $_nWave2 {G2}
wvSetCursor -win $_nWave2 3203447.159966 -snap {("G1" 0)}
wvSetSearchMode -win $_nWave2 -value 
srcHBSelect "testbench.DUT.tbuf_gen" -win $_nTrace1
srcHBSelect "testbench.DUT.tbuf_gen" -win $_nTrace1
srcShowDefine -win $_nTrace1 "testbench.DUT.tbuf_gen"
srcDeselectAll -win $_nTrace1
srcSelect -signal "tbuf_addr_lo" -line 819 -pos 1 -win $_nTrace1
schCreateWindow -win $_nSchema1 -level 1 -fanout
verdiDockWidgetSetCurTab -dock widgetDock_MTB_SOURCE_TAB_1
srcSetScope "testbench.DUT.word_tracking_p" -win $_nTrace1
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
wvSetCursor -win $_nWave2 3461999.529156 -snap {("G2" 0)}
wvZoomAll -win $_nWave2
wvZoom -win $_nWave2 3435946.940187 3517128.317445
srcDeselectAll -win $_nTrace1
srcSelect -signal "clk_i" -line 41 -pos 1 -win $_nTrace1
schCreateWindow -win $_nSchema1 -level 1 -fanin
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
wvZoom -win $_nWave2 3485161.569515 3489410.314493
wvZoom -win $_nWave2 3486495.754853 3486921.952947
wvSetCursor -win $_nWave2 3486648.177099 -snap {("G1" 2)}
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
verdiWindowResize -win $_Verdi_1 "392" "54" "1440" "723"
verdiWindowResize -win $_Verdi_1 "336" "281" "1440" "723"
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 3486076.060843 -snap {("G2" 0)}
wvSetCursor -win $_nWave2 3485790.969941 -snap {("G1" 2)}
wvSetCursor -win $_nWave2 3486630.603666
wvSetCursor -win $_nWave2 3486629.578159
wvSetCursor -win $_nWave2 3486637.782214
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "testbench.DUT" -delim "."
srcHBSelect "testbench.DUT" -win $_nTrace1
srcSignalViewSort -declaration
srcSignalViewSort -name
srcSignalViewSort -name
srcSignalViewSort -declaration
srcSignalViewSelect "testbench.DUT.data_o\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 0)}
srcSignalViewSelect "testbench.DUT.data_o\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvAddSignal -win $_nWave2 "/testbench/DUT/data_o\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
srcSignalViewExpand "testbench.DUT.dma_pkt_o\[38:0\]"
srcSignalViewCollapse "testbench.DUT.dma_pkt_o\[38:0\]"
srcSignalViewExpand "testbench.DUT.cache_pkt_i\[107:0\]"
srcSignalViewCollapse "testbench.DUT.cache_pkt_i\[107:0\]"
srcSignalViewSort -name
srcSignalViewSort -name
srcSignalViewExpand "testbench.DUT.cache_pkt"
srcSignalViewSelect "testbench.DUT.cache_pkt.data\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvAddSignal -win $_nWave2 "/testbench/DUT/cache_pkt.data\[63:0\]"
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
srcSignalViewSelect "testbench.DUT.cache_pkt.addr\[29:0\]"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvAddSignal -win $_nWave2 "/testbench/DUT/cache_pkt.addr\[29:0\]"
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSaveSignal -win $_nWave2 \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/signal.rc"
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
srcSignalViewCollapse "testbench.DUT.cache_pkt"
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSetSearchMode -win $_nWave2 -value 25ee
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvSetSearchMode -win $_nWave2 -value 2530
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSetCursor -win $_nWave2 3458619.652779 -snap {("G1" 0)}
wvSetCursor -win $_nWave2 3458620.678285
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSetCursor -win $_nWave2 3486649.493032 -snap {("G1" 0)}
wvSetCursor -win $_nWave2 3486574.631033 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 3486519.441455 -snap {("G1" 5)}
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvPanLeft -win $_nWave2
wvPanRight -win $_nWave2
srcSignalViewExpand "testbench.DUT.cache_pkt_i\[107:0\]"
srcSignalViewCollapse "testbench.DUT.cache_pkt_i\[107:0\]"
srcSignalViewExpand "testbench.DUT.cache_pkt"
srcSignalViewSelect "testbench.DUT.cache_pkt.data\[63:0\]"
srcSignalViewSort -declaration
srcSignalViewSelect "testbench.DUT.v_o"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvAddSignal -win $_nWave2 "/testbench/DUT/v_o"
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSetSearchMode -win $_nWave2 -value d008
wvSearchPrev -win $_nWave2
wvZoomIn -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
wvSearchPrev -win $_nWave2
wvSearchNext -win $_nWave2
