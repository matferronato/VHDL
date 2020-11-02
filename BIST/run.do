
if [file exists work] {
    vdel -all
}
vlib work
vmap work work
vcom -novopt ./pattern_gen.vhd
vcom -novopt ./lfsr_signature.vhd
vcom -novopt ./reg_bank.vhd
vcom -novopt ./mem_test.vhd

vcom -novopt ./mem_test_tb.vhd

vsim -novopt work.dut_tb -t 1ps
add wave sim:/*

do wave.do
run 1000 ns

