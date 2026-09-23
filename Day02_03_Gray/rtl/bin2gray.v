module bin2gray #(parameter W = 8) (
    input  wire [W-1:0] bin,
    output wire [W-1:0] gray
);
    assign gray = bin ^ (bin >> 1);
endmodule
