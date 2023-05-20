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
wvSelectGroup -win $_nWave2 {G1}
wvRestoreMarker -win $_nWave2 -file \
           "/home/rcrist/bsg_cache_research/basejump_stl/testing/bsg_cache/regression_64/marker.rpt"
wvUnselectUserMarker -win $_nWave2
wvSetCursor -win $_nWave2 2397547.959424 -snap {("G1" 0)}
wvSetCursor -win $_nWave2 2397553.894415
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvSelectUserMarker -win $_nWave2 -next
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
wvSetCursor -win $_nWave2 3336989.119561 -snap {("G2" 9)}
wvSelectSignal -win $_nWave2 {( "G2" 5 )} 
wvSelectSignal -win $_nWave2 {( "G2" 6 )} 
wvSelectSignal -win $_nWave2 {( "G2" 8 )} 
wvSetCursor -win $_nWave2 3337070.428926 -snap {("G2" 8)}
wvSetCursor -win $_nWave2 3336993.274054 -snap {("G2" 8)}
wvZoomAll -win $_nWave2
wvZoomAll -win $_nWave2
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
wvZoomOut -win $_nWave2
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -next
wvSelectUserMarker -win $_nWave2 -previous
wvZoomIn -win $_nWave2
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
