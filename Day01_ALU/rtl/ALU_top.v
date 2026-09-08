module ALU_top (
    input  wire       clk,
    input  wire       rst_n,        // active-low reset
    input  wire [7:0] d0_in,
    input  wire [7:0] d1_in,
    input  wire [3:0] sel_in,
    output reg  [8:0] result_out,
    output reg        zero_out,
    output reg        carry_out,
    output reg        negative_out,
    output reg        overflow_out
);

    // input-side registers
    reg [7:0] d0_q, d1_q;
    reg [3:0] sel_q;

    // combinational ALU outputs
    wire [8:0] result_c;
    wire zero_c, carry_c, negative_c, overflow_c;

    ALU core (
        .d0(d0_q), .d1(d1_q), .sel(sel_q),
        .result(result_c),
        .zero(zero_c), .carry(carry_c),
        .negative(negative_c), .overflow(overflow_c)
    );

    // capture inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0_q  <= 8'b0;
            d1_q  <= 8'b0;
            sel_q <= 4'b0;
        end else begin
            d0_q  <= d0_in;
            d1_q  <= d1_in;
            sel_q <= sel_in;
        end
    end

    // capture outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out   <= 9'b0;
            zero_out     <= 1'b0;
            carry_out    <= 1'b0;
            negative_out <= 1'b0;
            overflow_out <= 1'b0;
        end else begin
            result_out   <= result_c;
            zero_out     <= zero_c;
            carry_out    <= carry_c;
            negative_out <= negative_c;
            overflow_out <= overflow_c;
        end
    end

endmodule