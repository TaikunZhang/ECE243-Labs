# stop any simulation that is currently running
quit -sim


# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog part2.v proc.v
# compile the Verilog code of the testbench
vlog testbench.v
# start the Simulator
vsim testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 300 ns
