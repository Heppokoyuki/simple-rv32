#include <iostream>
#include <verilated.h>
#include <verilated_fst_c.h>
#include "VTop.h"

int time_counter = 0;

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    VTop *dut = new VTop();

    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;

    dut->trace(tfp, 100);
    tfp->open("simx.fst");

    dut->reset = 0;
    dut->clk = 0;

    while(time_counter < 100) {
        dut->eval();
        tfp->dump(time_counter);

        time_counter++;
    }

    dut->reset = 1;

    while(time_counter < 500) {
        if((time_counter % 5) == 0) {
            dut->clk = !dut->clk;
        }
        dut->eval();
        tfp->dump(time_counter);
        time_counter++;
    }

    dut->final();
    tfp->close();
}
