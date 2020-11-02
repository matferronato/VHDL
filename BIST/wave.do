onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dut_tb/WORD_SIZE
add wave -noupdate /dut_tb/LENGHT_SIZE
add wave -noupdate /dut_tb/signature_test
add wave -noupdate /dut_tb/signature_out
add wave -noupdate /dut_tb/data_out
add wave -noupdate /dut_tb/rst
add wave -noupdate /dut_tb/flag
add wave -noupdate /dut_tb/run
add wave -noupdate /dut_tb/clk
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/patterns_gen
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/run
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/flag
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/clk
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/rst
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/i
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/j
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/pattern
add wave -noupdate -group CHECKER -color Magenta /dut_tb/INST_MEM_CHECKER/current_s
add wave -noupdate -group CHECKER -color Yellow -radix unsigned -radixshowbase 1 /dut_tb/INST_MEM_CHECKER/w_addr
add wave -noupdate -group CHECKER -color Yellow -radix unsigned -radixshowbase 1 /dut_tb/INST_MEM_CHECKER/r_addr
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/w_data
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/r_data
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/en
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/timer
add wave -noupdate -group CHECKER /dut_tb/INST_MEM_CHECKER/t_retention_test
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/clk
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/rst
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_wadrr
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_raddr
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_wdata
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_rdata
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_wen
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/currentValue
add wave -noupdate -group REG_BANK /dut_tb/INST_MEM_CHECKER/INST_REGISTER_BANK/reg_bank
add wave -noupdate -group TB /dut_tb/WORD_SIZE
add wave -noupdate -group TB /dut_tb/LENGHT_SIZE
add wave -noupdate -group TB /dut_tb/signature_test
add wave -noupdate -group TB /dut_tb/signature_out
add wave -noupdate -group TB /dut_tb/data_out
add wave -noupdate -group TB /dut_tb/rst
add wave -noupdate -group TB /dut_tb/clk
add wave -noupdate -group PATTERN /dut_tb/INST_MEM_CHECKER/INST_PATTERN/clk
add wave -noupdate -group PATTERN /dut_tb/INST_MEM_CHECKER/INST_PATTERN/rst
add wave -noupdate -group PATTERN /dut_tb/INST_MEM_CHECKER/INST_PATTERN/patterns
add wave -noupdate -group PATTERN /dut_tb/INST_MEM_CHECKER/INST_PATTERN/pattern_w
add wave -noupdate -group PATTERN /dut_tb/INST_MEM_CHECKER/INST_PATTERN/pattern_source
add wave -noupdate /dut_tb/INST_SIGNATURE/clk
add wave -noupdate /dut_tb/INST_SIGNATURE/rst
add wave -noupdate /dut_tb/INST_SIGNATURE/data_in
add wave -noupdate /dut_tb/INST_SIGNATURE/data_out
add wave -noupdate /dut_tb/INST_SIGNATURE/data_aux
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {52247 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {20984941 ps} {21000793 ps}
