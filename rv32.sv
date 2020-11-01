/* verilator lint_off UNDRIVEN */

module rv32(
input
    logic clk,
    logic reset,
    logic [31:0] inst,
    logic [31:0] read_data,
output
    logic [31:0] pc,
    logic mem_write,
    logic [31:0] alu_result,
    logic [31:0] write_data
);

localparam
    SIZE_BYTE = 2'b00,
    SIZE_HALF = 2'b01,
    SIZE_WORD = 2'b10;

localparam
    ALU_ADD = 4'd0,
    ALU_SUB = 4'd1,
    ALU_SLT = 4'd2,
    ALU_SLTU = 4'd3,
    ALU_XOR = 4'd4,
    ALU_SRL = 4'd5,
    ALU_SRA = 4'd6,
    ALU_OR = 4'd7,
    ALU_AND = 4'd8,
    ALU_SLL = 4'd9,
    ALU_SEQ = 4'd10,
    ALU_SNEQ = 4'd11,
    ALU_SGE = 4'd12,
    ALU_SGEU = 4'd13,
    ALU_NOP = 4'd14;

logic [31:0] register[31:0];
logic pc_chg;
logic [31:0] next_pc;
wire [31:0] pc_src = pc_chg ? next_pc : 32'd4;

always_ff @(posedge clk) begin
    if(!reset) begin
        int i;
        pc <= 32'b0;
        for(i = 0; i < 32; i = i + 1) register[i] <= 32'b0;
    end
    else begin
        pc <= pc + pc_src;
    end
end

// decode
wire [6:0] opcode = inst[6:0];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];

wire op_load = (7'b0000011 == opcode);
wire op_store = (7'b0100011 == opcode);
wire op_alu_imm = (7'b0010011 == opcode);
wire op_alu_reg = (7'b0110011 == opcode);
wire op_branch = (7'b1100011 == opcode);

wire i_auipc = (7'b0010111 == opcode);
wire i_lui = (7'b0110111 == opcode);

wire i_jal = (7'b1101111 == opcode);
wire i_jalr = (7'b1100111 == opcode);

// load
wire i_lb = op_load && (3'b000 == funct3);
wire i_lh = op_load && (3'b001 == funct3);
wire i_lw = op_load && (3'b010 == funct3);
wire i_lbu = op_load && (3'b100 == funct3);
wire i_lhu = op_load && (3'b101 == funct3);

// store
wire i_sb = op_store && (3'b000 == funct3);
wire i_sh = op_store && (3'b001 == funct3);
wire i_sw = op_store && (3'b010 == funct3);

// alu_imm
wire i_addi = op_alu_imm && (3'b000 == funct3);
wire i_slti = op_alu_imm && (3'b010 == funct3);
wire i_sltiu = op_alu_imm && (3'b011 == funct3);
wire i_xori = op_alu_imm && (3'b100 == funct3);
wire i_ori = op_alu_imm && (3'b110 == funct3);
wire i_andi = op_alu_imm && (3'b111 == funct3);
wire i_slli = op_alu_imm && (3'b001 == funct3) && (7'b0000000 == funct7);
wire i_srli = op_alu_imm && (3'b101 == funct3) && (7'b0000000 == funct7);
wire i_srai = op_alu_imm && (3'b101 == funct3) && (7'b0100000 == funct7);

// alu_reg
wire i_add = op_alu_reg && (3'b000 == funct3) && (7'b0000000 == funct7);
wire i_sub = op_alu_reg && (3'b000 == funct3) && (7'b0100000 == funct7);
wire i_sll = op_alu_reg && (3'b001 == funct3);
wire i_slt = op_alu_reg && (3'b010 == funct3);
wire i_sltu = op_alu_reg && (3'b011 == funct3);
wire i_xor = op_alu_reg && (3'b100 == funct3);
wire i_srl = op_alu_reg && (3'b101 == funct3) && (7'b0000000 == funct7);
wire i_sra = op_alu_reg && (3'b101 == funct3) && (7'b0100000 == funct7);
wire i_or = op_alu_reg && (3'b110 == funct3);
wire i_and = op_alu_reg && (3'b111 == funct3);

// branch
wire i_beq = op_branch && (3'b000 == funct3);
wire i_bne = op_branch && (3'b001 == funct3);
wire i_blt = op_branch && (3'b100 == funct3);
wire i_bge = op_branch && (3'b101 == funct3);
wire i_bltu = op_branch && (3'b110 == funct3);
wire i_bgeu = op_branch && (3'b111 == funct3);

wire [1:0] r_size = (i_lb || i_lbu || i_sb) ? SIZE_BYTE :
                         (i_lh || i_lhu || i_sh) ? SIZE_HALF : SIZE_WORD;

assign mem_write = (op_store);
wire reg_write = (op_load || op_alu_imm || op_alu_reg || i_auipc || i_lui || i_jal || i_jalr);
wire sign_ext = (i_lb || i_lh || i_lw);
wire [3:0] alu_op = (op_load || op_store || i_addi || i_add || i_auipc || i_lui || i_jal || i_jalr) ? ALU_ADD :
                    (i_sub) ? ALU_SUB :
                    (i_slti || i_slt || i_blt) ? ALU_SLT :
                    (i_sltiu || i_sltu || i_bltu) ? ALU_SLTU :
                    (i_xori || i_xor) ? ALU_XOR :
                    (i_ori || i_or) ? ALU_OR :
                    (i_andi || i_and) ? ALU_AND :
                    (i_slli || i_sll) ? ALU_SLL :
                    (i_srli || i_srl) ? ALU_SRL :
                    (i_srai || i_sra) ? ALU_SRA :
                    (i_beq) ? ALU_SEQ :
                    (i_bne) ? ALU_SNEQ :
                    (i_bge) ? ALU_SGE :
                    (i_bgeu) ? ALU_SGEU : ALU_NOP;
wire imm_op = (op_load || op_store || op_alu_imm || i_auipc || i_lui);
wire imm_shamt_op = (i_slli || i_srli || i_srai);
wire alu_a_pc = (i_auipc || i_jal || i_jalr);
wire alu_a_zero = (i_lui);
wire alu_b_four = (i_jal || i_jalr);
wire wb_mem_op = (op_load);
assign pc_chg = (i_jal || i_jalr || (op_branch && alu_result == 32'd1));

wire [4:0] rd = inst[11:7];
wire [4:0] rs1 = inst[19:15];
wire [4:0] rs2 = inst[24:20];
wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]}; 
wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
wire [31:0] imm_u = {inst[31:12], 12'b0};
wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
wire [31:0] imm_shamt = {26'b0, inst[25:20]};

wire [31:0] imm_jalr = (register[rs1] + imm_i) & ~32'b1;
wire [31:0] imm = (imm_shamt_op) ? imm_shamt :
                  (op_load || op_alu_imm) ? imm_i : 
                  (op_branch) ? imm_b :
                  (i_auipc || i_lui) ? imm_u :
                  (i_jal) ? imm_j :
                  (i_jalr) ? imm_jalr :
                  (op_store) ? imm_s : 32'b0;
assign next_pc = imm;

// execute
wire [31:0] alu_in_a = alu_a_pc ? pc :
                       alu_a_zero ? 32'b0 : register[rs1];
wire [31:0] alu_in_b = imm_op ? imm :
                       alu_b_four ? 32'd4 : register[rs2];
always_comb begin
    case(alu_op)
        ALU_ADD: alu_result = alu_in_a + alu_in_b;
        ALU_SUB: alu_result = alu_in_a - alu_in_b;
        ALU_SLT: alu_result = {31'b0, $signed(alu_in_a) < $signed(alu_in_b)};
        ALU_SLTU: alu_result = {31'b0, alu_in_a < alu_in_b};
        ALU_XOR: alu_result = alu_in_a ^ alu_in_b;
        ALU_SRL: alu_result = alu_in_a >> alu_in_b;
        ALU_SRA: alu_result = $signed(alu_in_a) >>> alu_in_b;
        ALU_OR: alu_result = alu_in_a | alu_in_b;
        ALU_AND: alu_result = alu_in_a & alu_in_b;
        ALU_SLL: alu_result = alu_in_a << alu_in_b;
        ALU_SEQ: alu_result = {31'b0, alu_in_a == alu_in_b};
        ALU_SNEQ: alu_result = {31'b0, alu_in_a != alu_in_b};
        ALU_SGE: alu_result = {31'b0, $signed(alu_in_a) >= $signed(alu_in_b)};
        ALU_SGEU: alu_result = {31'b0, alu_in_a >= alu_in_b};
        default: alu_result = 32'b0;
    endcase
end

// memory
wire [31:0] reg_data = register[rs2];
assign write_data = (SIZE_BYTE == r_size) ? {{24{reg_data[7]}}, reg_data[7:0]} :
                    (SIZE_HALF == r_size) ? {{16{reg_data[15]}}, reg_data[15:0]} :
                    reg_data;

// write back
wire [31:0] mem_data = (SIZE_BYTE == r_size) ? 
                            sign_ext ? {{24{read_data[7]}}, read_data[7:0]} :
                            {24'b0, read_data[7:0]} :
                        (SIZE_HALF == r_size) ?
                            sign_ext ? {{16{read_data[15]}}, read_data[15:0]} :
                        {16'b0, read_data[15:0]} : read_data;
wire [31:0] reg_write_data = wb_mem_op ? mem_data : alu_result;
always_ff @(posedge clk) begin
    if(reg_write) begin
        if(rd != 5'd0) register[rd] <= reg_write_data;
    end
end

endmodule
