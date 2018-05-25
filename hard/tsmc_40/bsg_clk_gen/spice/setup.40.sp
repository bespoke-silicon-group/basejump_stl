
.lib '/gro/cad/pdk/tsmc40/T-N40-CM-SP-003/Model_card/crn45gs_2d5_lk_v2d0_2_shrink0d9_embedded_usage.l' TTMacro_MOS_MOSCAP
.include '/gro/cad/pdk/tsmc40/tcbn45gsbwp/TSMCHOME/digital/Back_End/lpe_spice/tcbn45gsbwp_120a/tcbn45gsbwp_120a_lpe.spi'
.temp 25C
.param supply=0.9

.global vdd
.global vss

v1 vdd    0 supply
v0 vss    0 0
