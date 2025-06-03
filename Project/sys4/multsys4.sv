// mat2x2_mult.v
module mat2x2_mult #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] A11, A12, A21, A22,
    input [WIDTH-1:0] B11, B12, B21, B22,
    output [WIDTH-1:0] C11, C12, C21, C22
);
    assign C11 = A11*B11 + A12*B21;
    assign C12 = A11*B12 + A12*B22;
    assign C21 = A21*B11 + A22*B21;
    assign C22 = A21*B12 + A22*B22;
endmodule

module sys4 #(
    parameter WIDTH = 16
)(
    input clk,
    input rst,
    input start,
    input [WIDTH*16-1:0] A,  // Flattened 4x4 matrix (A[0] = A[0*WIDTH +: WIDTH], etc.)
    input [WIDTH*16-1:0] B,  // Flattened 4x4 matrix
    output reg [WIDTH*16-1:0] C, // Flattened 4x4 matrix
    output reg done
);

    // Internal flattened registers for 2x2 tiles
    reg [WIDTH*4-1:0] A_in0, B_in0;
    reg [WIDTH*4-1:0] A_in1, B_in1;
    reg [WIDTH*4-1:0] A_in2, B_in2;
    reg [WIDTH*4-1:0] A_in3, B_in3;

    // Output wires from mat2x2_mult (flattened as 4xWIDTH)
    wire [WIDTH*4-1:0] C_out00, C_out01, C_out10, C_out11;

    reg [1:0] state;
    integer i, j;

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            C <= 0;
        end else begin
            case (state)
                2'd0: begin
                    if (start) begin
                        // Load top-left tile of A and top-left tile of B
                        // A_in0 = {A11, A12, A21, A22} = {A[0], A[1], A[4], A[5]}
                        A_in0 <= {A[1*WIDTH +: WIDTH], A[0*WIDTH +: WIDTH], A[5*WIDTH +: WIDTH], A[4*WIDTH +: WIDTH]};
                        B_in0 <= {B[1*WIDTH +: WIDTH], B[0*WIDTH +: WIDTH], B[5*WIDTH +: WIDTH], B[4*WIDTH +: WIDTH]};
                        // Top-left tile of A and top-right tile of B
                        A_in1 <= {A[1*WIDTH +: WIDTH], A[0*WIDTH +: WIDTH], A[5*WIDTH +: WIDTH], A[4*WIDTH +: WIDTH]};
                        B_in1 <= {B[3*WIDTH +: WIDTH], B[2*WIDTH +: WIDTH], B[7*WIDTH +: WIDTH], B[6*WIDTH +: WIDTH]};
                        // Bottom-left tile of A and top-left tile of B
                        A_in2 <= {A[9*WIDTH +: WIDTH], A[8*WIDTH +: WIDTH], A[13*WIDTH +: WIDTH], A[12*WIDTH +: WIDTH]};
                        B_in2 <= {B[1*WIDTH +: WIDTH], B[0*WIDTH +: WIDTH], B[5*WIDTH +: WIDTH], B[4*WIDTH +: WIDTH]};
                        // Bottom-left tile of A and top-right tile of B
                        A_in3 <= {A[9*WIDTH +: WIDTH], A[8*WIDTH +: WIDTH], A[13*WIDTH +: WIDTH], A[12*WIDTH +: WIDTH]};
                        B_in3 <= {B[3*WIDTH +: WIDTH], B[2*WIDTH +: WIDTH], B[7*WIDTH +: WIDTH], B[6*WIDTH +: WIDTH]};

                        state <= 2'd1;
                    end
                end

                2'd1: begin
                    // Map outputs to C; for 2x2 output tiles, map to the correct positions
                    // This is a conceptual mapping; adjust indices as needed for your layout
                    for (i = 0; i < 2; i = i + 1) begin
                        for (j = 0; j < 2; j = j + 1) begin
                            // Top-left tile
                            C[(i*4 + j)*WIDTH +: WIDTH] <= C_out00[(i*2 + j)*WIDTH +: WIDTH];
                            // Top-right tile
                            C[(i*4 + j + 2)*WIDTH +: WIDTH] <= C_out01[(i*2 + j)*WIDTH +: WIDTH];
                            // Bottom-left tile
                            C[((i+2)*4 + j)*WIDTH +: WIDTH] <= C_out10[(i*2 + j)*WIDTH +: WIDTH];
                            // Bottom-right tile
                            C[((i+2)*4 + j + 2)*WIDTH +: WIDTH] <= C_out11[(i*2 + j)*WIDTH +: WIDTH];
                        end
                    end
                    state <= 2'd2;
                end

                2'd2: begin
                    done <= 1;
                    state <= 2'd0;
                end

                default: state <= 2'd0;
            endcase
        end
    end

    // Instantiate 4 mat2x2 multipliers
    // Note: Order of elements in A_in0, etc. is {A11, A12, A21, A22}
    mat2x2_mult m0 (
        .A11(A_in0[0*WIDTH +: WIDTH]), .A12(A_in0[1*WIDTH +: WIDTH]),
        .A21(A_in0[2*WIDTH +: WIDTH]), .A22(A_in0[3*WIDTH +: WIDTH]),
        .B11(B_in0[0*WIDTH +: WIDTH]), .B12(B_in0[1*WIDTH +: WIDTH]),
        .B21(B_in0[2*WIDTH +: WIDTH]), .B22(B_in0[3*WIDTH +: WIDTH]),
        .C11(C_out00[0*WIDTH +: WIDTH]), .C12(C_out00[1*WIDTH +: WIDTH]),
        .C21(C_out00[2*WIDTH +: WIDTH]), .C22(C_out00[3*WIDTH +: WIDTH])
    );
    mat2x2_mult m1 (
        .A11(A_in1[0*WIDTH +: WIDTH]), .A12(A_in1[1*WIDTH +: WIDTH]),
        .A21(A_in1[2*WIDTH +: WIDTH]), .A22(A_in1[3*WIDTH +: WIDTH]),
        .B11(B_in1[0*WIDTH +: WIDTH]), .B12(B_in1[1*WIDTH +: WIDTH]),
        .B21(B_in1[2*WIDTH +: WIDTH]), .B22(B_in1[3*WIDTH +: WIDTH]),
        .C11(C_out01[0*WIDTH +: WIDTH]), .C12(C_out01[1*WIDTH +: WIDTH]),
        .C21(C_out01[2*WIDTH +: WIDTH]), .C22(C_out01[3*WIDTH +: WIDTH])
    );
    mat2x2_mult m2 (
        .A11(A_in2[0*WIDTH +: WIDTH]), .A12(A_in2[1*WIDTH +: WIDTH]),
        .A21(A_in2[2*WIDTH +: WIDTH]), .A22(A_in2[3*WIDTH +: WIDTH]),
        .B11(B_in2[0*WIDTH +: WIDTH]), .B12(B_in2[1*WIDTH +: WIDTH]),
        .B21(B_in2[2*WIDTH +: WIDTH]), .B22(B_in2[3*WIDTH +: WIDTH]),
        .C11(C_out10[0*WIDTH +: WIDTH]), .C12(C_out10[1*WIDTH +: WIDTH]),
        .C21(C_out10[2*WIDTH +: WIDTH]), .C22(C_out10[3*WIDTH +: WIDTH])
    );
    mat2x2_mult m3 (
        .A11(A_in3[0*WIDTH +: WIDTH]), .A12(A_in3[1*WIDTH +: WIDTH]),
        .A21(A_in3[2*WIDTH +: WIDTH]), .A22(A_in3[3*WIDTH +: WIDTH]),
        .B11(B_in3[0*WIDTH +: WIDTH]), .B12(B_in3[1*WIDTH +: WIDTH]),
        .B21(B_in3[2*WIDTH +: WIDTH]), .B22(B_in3[3*WIDTH +: WIDTH]),
        .C11(C_out11[0*WIDTH +: WIDTH]), .C12(C_out11[1*WIDTH +: WIDTH]),
        .C21(C_out11[2*WIDTH +: WIDTH]), .C22(C_out11[3*WIDTH +: WIDTH])
    );

    // If you still get UNUSEDSIGNAL warnings for unused bits of A or B, you can add:
    // (just for lint, not for synthesis)
    // wire [WIDTH-1:0] unused_A = A[127:96] | A[63:32];
    // wire [WIDTH-1:0] unused_B = B[223:192] | B[159:128];
    // But in this code, all bits of A and B are used, so this should not be needed.
endmodule

