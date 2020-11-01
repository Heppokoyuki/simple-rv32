module Dmem(
input
    logic clk,
    logic we,
    logic [31:0] a,
    logic [31:0] wd,
output
    logic [31:0] rd
);

// 1KiB memory
logic [31:0] mem[1024:0];

assign rd = mem[a[12:2]];

always_ff @(posedge clk)
    if(we) mem[a[12:2]] <= wd;

endmodule

