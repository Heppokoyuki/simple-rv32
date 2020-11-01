module Top(
input
    logic clk,
    logic reset
);

logic [31:0] pc, inst, data_addr, write_data, read_data;
logic mem_write;

rv32 cpu(.clk,
        .reset,
        .pc,
        .inst,
        .mem_write,
        .alu_result(data_addr),
        .write_data,
        .read_data);

Imem imem(.a(pc),
          .rd(inst));

Dmem dmem(.clk, 
          .we(mem_write),
          .a(data_addr),
          .wd(write_data),
          .rd(read_data));

endmodule

