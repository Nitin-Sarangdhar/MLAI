module sys4 #(
    parameter WIDTH = 16
)(
    input clk,
    input rst,
    input start,
    input [WIDTH*16-1:0] A,  // 4x4 matrix, 256 bits
    input [WIDTH*16-1:0] B,  // 4x4 matrix, 256 bits
    output reg [WIDTH*16-1:0] C, // 4x4 matrix, 256 bits
    output reg done
);

    integer i, j, k;
    reg [WIDTH-1:0] sum;
    reg [WIDTH-1:0] a_row[0:3];
    reg [WIDTH-1:0] b_col[0:3];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C <= 0;
            done <= 0;
        end else if (start) begin
            done <= 0;
            // Compute each output element
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    // Get row i of A and column j of B
                    for (k = 0; k < 4; k = k + 1) begin
                        a_row[k] = A[(i*4 + k)*WIDTH +: WIDTH];
                        b_col[k] = B[(k*4 + j)*WIDTH +: WIDTH];
                    end
                    // Compute dot product
                    sum = a_row[0] * b_col[0] + a_row[1] * b_col[1] + a_row[2] * b_col[2] + a_row[3] * b_col[3];
                    C[(i*4 + j)*WIDTH +: WIDTH] <= sum;
                end
            end
            done <= 1;
        end
    end
endmodule

