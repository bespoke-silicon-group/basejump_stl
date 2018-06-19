
.lib '/gro/cad/pdk/arm180/TSMC_180_7_26_16/MOSIS_Logic_7_26_16/T-018-LO-SP-001/T018LOSP001_2_1/T018LOSP001_2_1/log018.l' SS
.lib '/gro/cad/pdk/arm180/TSMC_180_7_26_16/MOSIS_Logic_7_26_16/T-018-LO-SP-001/T018LOSP001_2_1/T018LOSP001_2_1/log018.l' SS_3V
.lib '/gro/cad/pdk/arm180/TSMC_180_7_26_16/MOSIS_Logic_7_26_16/T-018-LO-SP-001/T018LOSP001_2_1/T018LOSP001_2_1/log018.l' DIO
.lib '/gro/cad/pdk/arm180/TSMC_180_7_26_16/MOSIS_Logic_7_26_16/T-018-LO-SP-001/T018LOSP001_2_1/T018LOSP001_2_1/log018.l' DIO3
.include '/gro/cad/pdk/arm180/TSMC_180_7_26_16/ARM_7_26_16/TS02LB500-FB-00000_tsmc/cl018g/sc9_base_rvt/2008q3v01/cdl/sage-x_tsmc_cl018g_rvt.cdl'
.include '/gro/cad/pdk/arm180/TSMC_180_7_26_16/ARM_7_26_16/TS02IG500-FB-00000-r0p0-01rel0/TSMCHOME_fb/digital/Back_End/spice/tpz973gv_270a/tpz973gv_1_2.spi'
.temp 125C

.malias pch P
.malias nch N
.malias pch3 pd
.malias nch3 nd
.malias pdio dp
.malias ndio dn
.malias pdio_3 d1
.malias nwdio_3 db


.param supply=1.8
.param supply33=3.3

v3 vsspst 0 0
v2 vd33   0 supply33
v1 vdd    0 supply
v0 vss    0 0
