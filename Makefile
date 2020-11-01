VERILATOR_OPTIONS = --cc --exe --trace-fst --trace-params --trace-structs --trace-underscore
TARGET = Top.sv rv32.sv
TEST_BENCH  = tb_top.cpp

all:
	verilator $(VERILATOR_OPTIONS) $(TARGET) -exe $(TEST_BENCH)
	make -C obj_dir -f VTop.mk
	./obj_dir/VTop

wave: all
	gtkwave simx.fst &

clean:
	rm -rf obj_dir simx.fst
