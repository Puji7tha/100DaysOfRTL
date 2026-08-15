module ALU(
    input wire [7:0] d0, //1st operand
    input wire [7:0] d1, //2nd operand
    input wire [3:0] sel, //operand select
    output reg [8:0] result, //result-9 bit to hold carry
    output wire       zero,
    output wire       carry,
    output wire       negative,
    output wire       overflow
);
always @(*) begin

    case (sel)
        // ---- Arithmetic ----
        4'b0000 : result = d0 + d1;              // ADD
        4'b0001 : result = d0 - d1;              // SUB
        4'b0010 : result = d0 * d1;              // MUL  (see note)
        4'b0011 : result = (d1 == 0) ? 9'b0 : d0 / d1;  // DIV

        // ---- Bitwise ----
        4'b0100 : result = {1'b0, d0 & d1};      // AND
        4'b0101 : result = {1'b0, d0 | d1};      // OR
        4'b0110 : result = {1'b0, ~(d0 & d1)};   // NAND
        4'b0111 : result = {1'b0, ~(d0 | d1)};   // NOR

        // ---- Shifts ----
        4'b1000 : result = d0 << 1;              // SHL d0
        4'b1001 : result = d1 << 1;              // SHL d1
        4'b1010 : result = {1'b0, d0 >> 1};      // SHR d0
        4'b1011 : result = {1'b0, d1 >> 1};      // SHR d1

        // ---- Unary ----
        4'b1100 : result = {1'b0, ~d0};                  // NOT d0
        4'b1101 : result = {1'b0, $signed(d0) >>> 1};    // ASR d0
        4'b1110 : result = {1'b0, (~d0 + 8'd1)};         // 2's complement
        4'b1111 : result = {1'b0, d0 ^ d1};              // XOR

        default : result = 9'b0;
    endcase
    
end

assign zero     = (result[7:0] == 8'b0);
assign carry    = result[8];
assign negative = result[7];
assign overflow = (sel == 4'b0000) ? (~(d0[7] ^ d1[7]) & (result[7] ^ d0[7])) : (sel == 4'b0001) ? ( (d0[7] ^ d1[7]) & (result[7] ^ d0[7])) :1'b0;

endmodule