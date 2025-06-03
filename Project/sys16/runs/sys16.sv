// mat2x2_mult.v
module mat2x2_mult(
    input  logic [63:0]  A_in, // 4x16 bits packed: {A22, A21, A12, A11}
    input  logic [63:0]  B_in, // 4x16 bits packed: {B22, B21, B12, B11}
    output logic [127:0] C_out // 4x32 bits packed: {C22, C21, C12, C11}
);

    // Unpack 16-bit elements from packed inputs
    logic [15:0] A11, A12, A21, A22;
    logic [15:0] B11, B12, B21, B22;

    assign {A22, A21, A12, A11} = A_in;
    assign {B22, B21, B12, B11} = B_in;

    // Compute 32-bit results
    logic [31:0] C11, C12, C21, C22;

    assign C11 = A11 * B11 + A12 * B21;
    assign C12 = A11 * B12 + A12 * B22;
    assign C21 = A21 * B11 + A22 * B21;
    assign C22 = A21 * B12 + A22 * B22;

    // Pack results into output
    assign C_out = {C22, C21, C12, C11};


endmodule


module sys16 #(
    parameter WIDTH = 16,
    parameter MATRIX_SIZE = 16 // 4x4 matrix flattened to 16 elements
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             start,
    input  logic [WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] A_flat, // 16x16 elements
    input  logic [WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] B_flat, // 16x16 elements
    output logic [2*WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] C_flat, // 16x16 elements, 32 bits each
    output logic            done
);  


    // Internal input registers to mat2x2_mult units (64 multipliers)
    logic [4*WIDTH-1:0] A_in_packed [0:63];  // Array of 64 input A tiles
    logic [4*WIDTH-1:0] B_in_packed [0:63];  // Array of 64 input B tiles

    // Output wires from multipliers

    wire [4*2*WIDTH-1:0] C_out_packed [0:63];



    reg [1:0] state;
    logic [2:0] pass_j;
    // Helper macro for bit slicing
    `define SLICE(vec, idx) vec[(idx)*WIDTH +: WIDTH]
    `define SLICE32(vec, idx) vec[(idx)*2*WIDTH +: 2*WIDTH]

    // Display block (optional, can be removed for synthesis)
    // Main state machine
    always_ff @(posedge clk or posedge rst) begin
        
        if (rst) begin
            state <= 2'd0;
            done <= 0;
            C_flat <= '0;
            pass_j <= 3'd0;
        end else begin
            case (state)
            // State 0: Load multiplier inputs for pass_j
                2'd0: begin                    
                    if (start) begin
                        case (pass_j)
                            3'd0: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(1)), `SLICE(A_flat, 16*(1)+(0)), `SLICE(A_flat, 16*(0)+(1)), `SLICE(A_flat, 16*(0)+(0)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(1)), `SLICE(A_flat, 16*(3)+(0)), `SLICE(A_flat, 16*(2)+(1)), `SLICE(A_flat, 16*(2)+(0)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(1)), `SLICE(A_flat, 16*(5)+(0)), `SLICE(A_flat, 16*(4)+(1)), `SLICE(A_flat, 16*(4)+(0)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(1)), `SLICE(A_flat, 16*(7)+(0)), `SLICE(A_flat, 16*(6)+(1)), `SLICE(A_flat, 16*(6)+(0)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(1)), `SLICE(A_flat, 16*(9)+(0)), `SLICE(A_flat, 16*(8)+(1)), `SLICE(A_flat, 16*(8)+(0)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(1)), `SLICE(A_flat, 16*(11)+(0)), `SLICE(A_flat, 16*(10)+(1)), `SLICE(A_flat, 16*(10)+(0)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(1)), `SLICE(A_flat, 16*(13)+(0)), `SLICE(A_flat, 16*(12)+(1)), `SLICE(A_flat, 16*(12)+(0)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(1)+(1)), `SLICE(B_flat, 16*(1)+(0)), `SLICE(B_flat, 16*(0)+(1)), `SLICE(B_flat, 16*(0)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(1)+(3)), `SLICE(B_flat, 16*(1)+(2)), `SLICE(B_flat, 16*(0)+(3)), `SLICE(B_flat, 16*(0)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(1)+(5)), `SLICE(B_flat, 16*(1)+(4)), `SLICE(B_flat, 16*(0)+(5)), `SLICE(B_flat, 16*(0)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(1)+(7)), `SLICE(B_flat, 16*(1)+(6)), `SLICE(B_flat, 16*(0)+(7)), `SLICE(B_flat, 16*(0)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(1)+(9)), `SLICE(B_flat, 16*(1)+(8)), `SLICE(B_flat, 16*(0)+(9)), `SLICE(B_flat, 16*(0)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(1)+(11)), `SLICE(B_flat, 16*(1)+(10)), `SLICE(B_flat, 16*(0)+(11)), `SLICE(B_flat, 16*(0)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(1)+(13)), `SLICE(B_flat, 16*(1)+(12)), `SLICE(B_flat, 16*(0)+(13)), `SLICE(B_flat, 16*(0)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(1)), `SLICE(A_flat, 16*(15)+(0)), `SLICE(A_flat, 16*(14)+(1)), `SLICE(A_flat, 16*(14)+(0)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(1)+(15)), `SLICE(B_flat, 16*(1)+(14)), `SLICE(B_flat, 16*(0)+(15)), `SLICE(B_flat, 16*(0)+(14)) };
                            end
                            3'd1: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(3)), `SLICE(A_flat, 16*(1)+(2)), `SLICE(A_flat, 16*(0)+(3)), `SLICE(A_flat, 16*(0)+(2)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(3)), `SLICE(A_flat, 16*(3)+(2)), `SLICE(A_flat, 16*(2)+(3)), `SLICE(A_flat, 16*(2)+(2)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(3)), `SLICE(A_flat, 16*(5)+(2)), `SLICE(A_flat, 16*(4)+(3)), `SLICE(A_flat, 16*(4)+(2)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(3)), `SLICE(A_flat, 16*(7)+(2)), `SLICE(A_flat, 16*(6)+(3)), `SLICE(A_flat, 16*(6)+(2)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(3)), `SLICE(A_flat, 16*(9)+(2)), `SLICE(A_flat, 16*(8)+(3)), `SLICE(A_flat, 16*(8)+(2)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(3)), `SLICE(A_flat, 16*(11)+(2)), `SLICE(A_flat, 16*(10)+(3)), `SLICE(A_flat, 16*(10)+(2)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(3)), `SLICE(A_flat, 16*(13)+(2)), `SLICE(A_flat, 16*(12)+(3)), `SLICE(A_flat, 16*(12)+(2)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(3)+(1)), `SLICE(B_flat, 16*(3)+(0)), `SLICE(B_flat, 16*(2)+(1)), `SLICE(B_flat, 16*(2)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(3)+(3)), `SLICE(B_flat, 16*(3)+(2)), `SLICE(B_flat, 16*(2)+(3)), `SLICE(B_flat, 16*(2)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(3)+(5)), `SLICE(B_flat, 16*(3)+(4)), `SLICE(B_flat, 16*(2)+(5)), `SLICE(B_flat, 16*(2)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(3)+(7)), `SLICE(B_flat, 16*(3)+(6)), `SLICE(B_flat, 16*(2)+(7)), `SLICE(B_flat, 16*(2)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(3)+(9)), `SLICE(B_flat, 16*(3)+(8)), `SLICE(B_flat, 16*(2)+(9)), `SLICE(B_flat, 16*(2)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(3)+(11)), `SLICE(B_flat, 16*(3)+(10)), `SLICE(B_flat, 16*(2)+(11)), `SLICE(B_flat, 16*(2)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(3)+(13)), `SLICE(B_flat, 16*(3)+(12)), `SLICE(B_flat, 16*(2)+(13)), `SLICE(B_flat, 16*(2)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(3)), `SLICE(A_flat, 16*(15)+(2)), `SLICE(A_flat, 16*(14)+(3)), `SLICE(A_flat, 16*(14)+(2)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(3)+(15)), `SLICE(B_flat, 16*(3)+(14)), `SLICE(B_flat, 16*(2)+(15)), `SLICE(B_flat, 16*(2)+(14)) };
                            end
                            3'd2: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(5)), `SLICE(A_flat, 16*(1)+(4)), `SLICE(A_flat, 16*(0)+(5)), `SLICE(A_flat, 16*(0)+(4)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(5)), `SLICE(A_flat, 16*(3)+(4)), `SLICE(A_flat, 16*(2)+(5)), `SLICE(A_flat, 16*(2)+(4)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(5)), `SLICE(A_flat, 16*(5)+(4)), `SLICE(A_flat, 16*(4)+(5)), `SLICE(A_flat, 16*(4)+(4)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(5)), `SLICE(A_flat, 16*(7)+(4)), `SLICE(A_flat, 16*(6)+(5)), `SLICE(A_flat, 16*(6)+(4)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(5)), `SLICE(A_flat, 16*(9)+(4)), `SLICE(A_flat, 16*(8)+(5)), `SLICE(A_flat, 16*(8)+(4)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(5)), `SLICE(A_flat, 16*(11)+(4)), `SLICE(A_flat, 16*(10)+(5)), `SLICE(A_flat, 16*(10)+(4)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(5)), `SLICE(A_flat, 16*(13)+(4)), `SLICE(A_flat, 16*(12)+(5)), `SLICE(A_flat, 16*(12)+(4)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(5)+(1)), `SLICE(B_flat, 16*(5)+(0)), `SLICE(B_flat, 16*(4)+(1)), `SLICE(B_flat, 16*(4)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(5)+(3)), `SLICE(B_flat, 16*(5)+(2)), `SLICE(B_flat, 16*(4)+(3)), `SLICE(B_flat, 16*(4)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(5)+(5)), `SLICE(B_flat, 16*(5)+(4)), `SLICE(B_flat, 16*(4)+(5)), `SLICE(B_flat, 16*(4)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(5)+(7)), `SLICE(B_flat, 16*(5)+(6)), `SLICE(B_flat, 16*(4)+(7)), `SLICE(B_flat, 16*(4)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(5)+(9)), `SLICE(B_flat, 16*(5)+(8)), `SLICE(B_flat, 16*(4)+(9)), `SLICE(B_flat, 16*(4)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(5)+(11)), `SLICE(B_flat, 16*(5)+(10)), `SLICE(B_flat, 16*(4)+(11)), `SLICE(B_flat, 16*(4)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(5)+(13)), `SLICE(B_flat, 16*(5)+(12)), `SLICE(B_flat, 16*(4)+(13)), `SLICE(B_flat, 16*(4)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(5)), `SLICE(A_flat, 16*(15)+(4)), `SLICE(A_flat, 16*(14)+(5)), `SLICE(A_flat, 16*(14)+(4)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(5)+(15)), `SLICE(B_flat, 16*(5)+(14)), `SLICE(B_flat, 16*(4)+(15)), `SLICE(B_flat, 16*(4)+(14)) };
                            end
                            3'd3: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(7)), `SLICE(A_flat, 16*(1)+(6)), `SLICE(A_flat, 16*(0)+(7)), `SLICE(A_flat, 16*(0)+(6)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(7)), `SLICE(A_flat, 16*(3)+(6)), `SLICE(A_flat, 16*(2)+(7)), `SLICE(A_flat, 16*(2)+(6)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(7)), `SLICE(A_flat, 16*(5)+(6)), `SLICE(A_flat, 16*(4)+(7)), `SLICE(A_flat, 16*(4)+(6)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(7)), `SLICE(A_flat, 16*(7)+(6)), `SLICE(A_flat, 16*(6)+(7)), `SLICE(A_flat, 16*(6)+(6)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(7)), `SLICE(A_flat, 16*(9)+(6)), `SLICE(A_flat, 16*(8)+(7)), `SLICE(A_flat, 16*(8)+(6)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(7)), `SLICE(A_flat, 16*(11)+(6)), `SLICE(A_flat, 16*(10)+(7)), `SLICE(A_flat, 16*(10)+(6)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(7)), `SLICE(A_flat, 16*(13)+(6)), `SLICE(A_flat, 16*(12)+(7)), `SLICE(A_flat, 16*(12)+(6)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(7)+(1)), `SLICE(B_flat, 16*(7)+(0)), `SLICE(B_flat, 16*(6)+(1)), `SLICE(B_flat, 16*(6)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(7)+(3)), `SLICE(B_flat, 16*(7)+(2)), `SLICE(B_flat, 16*(6)+(3)), `SLICE(B_flat, 16*(6)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(7)+(5)), `SLICE(B_flat, 16*(7)+(4)), `SLICE(B_flat, 16*(6)+(5)), `SLICE(B_flat, 16*(6)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(7)+(7)), `SLICE(B_flat, 16*(7)+(6)), `SLICE(B_flat, 16*(6)+(7)), `SLICE(B_flat, 16*(6)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(7)+(9)), `SLICE(B_flat, 16*(7)+(8)), `SLICE(B_flat, 16*(6)+(9)), `SLICE(B_flat, 16*(6)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(7)+(11)), `SLICE(B_flat, 16*(7)+(10)), `SLICE(B_flat, 16*(6)+(11)), `SLICE(B_flat, 16*(6)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(7)+(13)), `SLICE(B_flat, 16*(7)+(12)), `SLICE(B_flat, 16*(6)+(13)), `SLICE(B_flat, 16*(6)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(7)), `SLICE(A_flat, 16*(15)+(6)), `SLICE(A_flat, 16*(14)+(7)), `SLICE(A_flat, 16*(14)+(6)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(7)+(15)), `SLICE(B_flat, 16*(7)+(14)), `SLICE(B_flat, 16*(6)+(15)), `SLICE(B_flat, 16*(6)+(14)) };
                            end
                            3'd4: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(9)), `SLICE(A_flat, 16*(1)+(8)), `SLICE(A_flat, 16*(0)+(9)), `SLICE(A_flat, 16*(0)+(8)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(9)), `SLICE(A_flat, 16*(3)+(8)), `SLICE(A_flat, 16*(2)+(9)), `SLICE(A_flat, 16*(2)+(8)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(9)), `SLICE(A_flat, 16*(5)+(8)), `SLICE(A_flat, 16*(4)+(9)), `SLICE(A_flat, 16*(4)+(8)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(9)), `SLICE(A_flat, 16*(7)+(8)), `SLICE(A_flat, 16*(6)+(9)), `SLICE(A_flat, 16*(6)+(8)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(9)), `SLICE(A_flat, 16*(9)+(8)), `SLICE(A_flat, 16*(8)+(9)), `SLICE(A_flat, 16*(8)+(8)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(9)), `SLICE(A_flat, 16*(11)+(8)), `SLICE(A_flat, 16*(10)+(9)), `SLICE(A_flat, 16*(10)+(8)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(9)), `SLICE(A_flat, 16*(13)+(8)), `SLICE(A_flat, 16*(12)+(9)), `SLICE(A_flat, 16*(12)+(8)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(9)+(1)), `SLICE(B_flat, 16*(9)+(0)), `SLICE(B_flat, 16*(8)+(1)), `SLICE(B_flat, 16*(8)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(9)+(3)), `SLICE(B_flat, 16*(9)+(2)), `SLICE(B_flat, 16*(8)+(3)), `SLICE(B_flat, 16*(8)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(9)+(5)), `SLICE(B_flat, 16*(9)+(4)), `SLICE(B_flat, 16*(8)+(5)), `SLICE(B_flat, 16*(8)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(9)+(7)), `SLICE(B_flat, 16*(9)+(6)), `SLICE(B_flat, 16*(8)+(7)), `SLICE(B_flat, 16*(8)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(9)+(9)), `SLICE(B_flat, 16*(9)+(8)), `SLICE(B_flat, 16*(8)+(9)), `SLICE(B_flat, 16*(8)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(9)+(11)), `SLICE(B_flat, 16*(9)+(10)), `SLICE(B_flat, 16*(8)+(11)), `SLICE(B_flat, 16*(8)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(9)+(13)), `SLICE(B_flat, 16*(9)+(12)), `SLICE(B_flat, 16*(8)+(13)), `SLICE(B_flat, 16*(8)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(9)), `SLICE(A_flat, 16*(15)+(8)), `SLICE(A_flat, 16*(14)+(9)), `SLICE(A_flat, 16*(14)+(8)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(9)+(15)), `SLICE(B_flat, 16*(9)+(14)), `SLICE(B_flat, 16*(8)+(15)), `SLICE(B_flat, 16*(8)+(14)) };
                            end
                            3'd5: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(11)), `SLICE(A_flat, 16*(1)+(10)), `SLICE(A_flat, 16*(0)+(11)), `SLICE(A_flat, 16*(0)+(10)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(11)), `SLICE(A_flat, 16*(3)+(10)), `SLICE(A_flat, 16*(2)+(11)), `SLICE(A_flat, 16*(2)+(10)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(11)), `SLICE(A_flat, 16*(5)+(10)), `SLICE(A_flat, 16*(4)+(11)), `SLICE(A_flat, 16*(4)+(10)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(11)), `SLICE(A_flat, 16*(7)+(10)), `SLICE(A_flat, 16*(6)+(11)), `SLICE(A_flat, 16*(6)+(10)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(11)), `SLICE(A_flat, 16*(9)+(10)), `SLICE(A_flat, 16*(8)+(11)), `SLICE(A_flat, 16*(8)+(10)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(11)), `SLICE(A_flat, 16*(11)+(10)), `SLICE(A_flat, 16*(10)+(11)), `SLICE(A_flat, 16*(10)+(10)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(11)), `SLICE(A_flat, 16*(13)+(10)), `SLICE(A_flat, 16*(12)+(11)), `SLICE(A_flat, 16*(12)+(10)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(11)+(1)), `SLICE(B_flat, 16*(11)+(0)), `SLICE(B_flat, 16*(10)+(1)), `SLICE(B_flat, 16*(10)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(11)+(3)), `SLICE(B_flat, 16*(11)+(2)), `SLICE(B_flat, 16*(10)+(3)), `SLICE(B_flat, 16*(10)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(11)+(5)), `SLICE(B_flat, 16*(11)+(4)), `SLICE(B_flat, 16*(10)+(5)), `SLICE(B_flat, 16*(10)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(11)+(7)), `SLICE(B_flat, 16*(11)+(6)), `SLICE(B_flat, 16*(10)+(7)), `SLICE(B_flat, 16*(10)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(11)+(9)), `SLICE(B_flat, 16*(11)+(8)), `SLICE(B_flat, 16*(10)+(9)), `SLICE(B_flat, 16*(10)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(11)+(11)), `SLICE(B_flat, 16*(11)+(10)), `SLICE(B_flat, 16*(10)+(11)), `SLICE(B_flat, 16*(10)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(11)+(13)), `SLICE(B_flat, 16*(11)+(12)), `SLICE(B_flat, 16*(10)+(13)), `SLICE(B_flat, 16*(10)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(11)), `SLICE(A_flat, 16*(15)+(10)), `SLICE(A_flat, 16*(14)+(11)), `SLICE(A_flat, 16*(14)+(10)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(11)+(15)), `SLICE(B_flat, 16*(11)+(14)), `SLICE(B_flat, 16*(10)+(15)), `SLICE(B_flat, 16*(10)+(14)) };
                            end
                            3'd6: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(13)), `SLICE(A_flat, 16*(1)+(12)), `SLICE(A_flat, 16*(0)+(13)), `SLICE(A_flat, 16*(0)+(12)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(13)), `SLICE(A_flat, 16*(3)+(12)), `SLICE(A_flat, 16*(2)+(13)), `SLICE(A_flat, 16*(2)+(12)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(13)), `SLICE(A_flat, 16*(5)+(12)), `SLICE(A_flat, 16*(4)+(13)), `SLICE(A_flat, 16*(4)+(12)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(13)), `SLICE(A_flat, 16*(7)+(12)), `SLICE(A_flat, 16*(6)+(13)), `SLICE(A_flat, 16*(6)+(12)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(13)), `SLICE(A_flat, 16*(9)+(12)), `SLICE(A_flat, 16*(8)+(13)), `SLICE(A_flat, 16*(8)+(12)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(13)), `SLICE(A_flat, 16*(11)+(12)), `SLICE(A_flat, 16*(10)+(13)), `SLICE(A_flat, 16*(10)+(12)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(13)), `SLICE(A_flat, 16*(13)+(12)), `SLICE(A_flat, 16*(12)+(13)), `SLICE(A_flat, 16*(12)+(12)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(13)+(1)), `SLICE(B_flat, 16*(13)+(0)), `SLICE(B_flat, 16*(12)+(1)), `SLICE(B_flat, 16*(12)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(13)+(3)), `SLICE(B_flat, 16*(13)+(2)), `SLICE(B_flat, 16*(12)+(3)), `SLICE(B_flat, 16*(12)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(13)+(5)), `SLICE(B_flat, 16*(13)+(4)), `SLICE(B_flat, 16*(12)+(5)), `SLICE(B_flat, 16*(12)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(13)+(7)), `SLICE(B_flat, 16*(13)+(6)), `SLICE(B_flat, 16*(12)+(7)), `SLICE(B_flat, 16*(12)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(13)+(9)), `SLICE(B_flat, 16*(13)+(8)), `SLICE(B_flat, 16*(12)+(9)), `SLICE(B_flat, 16*(12)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(13)+(11)), `SLICE(B_flat, 16*(13)+(10)), `SLICE(B_flat, 16*(12)+(11)), `SLICE(B_flat, 16*(12)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(13)+(13)), `SLICE(B_flat, 16*(13)+(12)), `SLICE(B_flat, 16*(12)+(13)), `SLICE(B_flat, 16*(12)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(13)), `SLICE(A_flat, 16*(15)+(12)), `SLICE(A_flat, 16*(14)+(13)), `SLICE(A_flat, 16*(14)+(12)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(13)+(15)), `SLICE(B_flat, 16*(13)+(14)), `SLICE(B_flat, 16*(12)+(15)), `SLICE(B_flat, 16*(12)+(14)) };
                            end
                            3'd7: begin
                                A_in_packed[0] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[0] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[1] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[1] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[2] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[2] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[3] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[3] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[4] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[4] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[5] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[5] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[6] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[6] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[7] <= { `SLICE(A_flat, 16*(1)+(15)), `SLICE(A_flat, 16*(1)+(14)), `SLICE(A_flat, 16*(0)+(15)), `SLICE(A_flat, 16*(0)+(14)) };
                                B_in_packed[7] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[8] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[8] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[9] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[9] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[10] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[10] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[11] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[11] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[12] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[12] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[13] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[13] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[14] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[14] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[15] <= { `SLICE(A_flat, 16*(3)+(15)), `SLICE(A_flat, 16*(3)+(14)), `SLICE(A_flat, 16*(2)+(15)), `SLICE(A_flat, 16*(2)+(14)) };
                                B_in_packed[15] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[16] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[16] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[17] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[17] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[18] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[18] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[19] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[19] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[20] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[20] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[21] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[21] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[22] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[22] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[23] <= { `SLICE(A_flat, 16*(5)+(15)), `SLICE(A_flat, 16*(5)+(14)), `SLICE(A_flat, 16*(4)+(15)), `SLICE(A_flat, 16*(4)+(14)) };
                                B_in_packed[23] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[24] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[24] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[25] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[25] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[26] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[26] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[27] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[27] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[28] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[28] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[29] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[29] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[30] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[30] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[31] <= { `SLICE(A_flat, 16*(7)+(15)), `SLICE(A_flat, 16*(7)+(14)), `SLICE(A_flat, 16*(6)+(15)), `SLICE(A_flat, 16*(6)+(14)) };
                                B_in_packed[31] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[32] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[32] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[33] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[33] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[34] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[34] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[35] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[35] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[36] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[36] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[37] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[37] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[38] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[38] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[39] <= { `SLICE(A_flat, 16*(9)+(15)), `SLICE(A_flat, 16*(9)+(14)), `SLICE(A_flat, 16*(8)+(15)), `SLICE(A_flat, 16*(8)+(14)) };
                                B_in_packed[39] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[40] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[40] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[41] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[41] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[42] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[42] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[43] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[43] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[44] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[44] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[45] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[45] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[46] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[46] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[47] <= { `SLICE(A_flat, 16*(11)+(15)), `SLICE(A_flat, 16*(11)+(14)), `SLICE(A_flat, 16*(10)+(15)), `SLICE(A_flat, 16*(10)+(14)) };
                                B_in_packed[47] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[48] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[48] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[49] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[49] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[50] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[50] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[51] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[51] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[52] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[52] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[53] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[53] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[54] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[54] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[55] <= { `SLICE(A_flat, 16*(13)+(15)), `SLICE(A_flat, 16*(13)+(14)), `SLICE(A_flat, 16*(12)+(15)), `SLICE(A_flat, 16*(12)+(14)) };
                                B_in_packed[55] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                                A_in_packed[56] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[56] <= { `SLICE(B_flat, 16*(15)+(1)), `SLICE(B_flat, 16*(15)+(0)), `SLICE(B_flat, 16*(14)+(1)), `SLICE(B_flat, 16*(14)+(0)) };
                                A_in_packed[57] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[57] <= { `SLICE(B_flat, 16*(15)+(3)), `SLICE(B_flat, 16*(15)+(2)), `SLICE(B_flat, 16*(14)+(3)), `SLICE(B_flat, 16*(14)+(2)) };
                                A_in_packed[58] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[58] <= { `SLICE(B_flat, 16*(15)+(5)), `SLICE(B_flat, 16*(15)+(4)), `SLICE(B_flat, 16*(14)+(5)), `SLICE(B_flat, 16*(14)+(4)) };
                                A_in_packed[59] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[59] <= { `SLICE(B_flat, 16*(15)+(7)), `SLICE(B_flat, 16*(15)+(6)), `SLICE(B_flat, 16*(14)+(7)), `SLICE(B_flat, 16*(14)+(6)) };
                                A_in_packed[60] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[60] <= { `SLICE(B_flat, 16*(15)+(9)), `SLICE(B_flat, 16*(15)+(8)), `SLICE(B_flat, 16*(14)+(9)), `SLICE(B_flat, 16*(14)+(8)) };
                                A_in_packed[61] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[61] <= { `SLICE(B_flat, 16*(15)+(11)), `SLICE(B_flat, 16*(15)+(10)), `SLICE(B_flat, 16*(14)+(11)), `SLICE(B_flat, 16*(14)+(10)) };
                                A_in_packed[62] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[62] <= { `SLICE(B_flat, 16*(15)+(13)), `SLICE(B_flat, 16*(15)+(12)), `SLICE(B_flat, 16*(14)+(13)), `SLICE(B_flat, 16*(14)+(12)) };
                                A_in_packed[63] <= { `SLICE(A_flat, 16*(15)+(15)), `SLICE(A_flat, 16*(15)+(14)), `SLICE(A_flat, 16*(14)+(15)), `SLICE(A_flat, 16*(14)+(14)) };
                                B_in_packed[63] <= { `SLICE(B_flat, 16*(15)+(15)), `SLICE(B_flat, 16*(15)+(14)), `SLICE(B_flat, 16*(14)+(15)), `SLICE(B_flat, 16*(14)+(14)) };
                            end
                        endcase
                        state <= 2'd1;
                        done <= 1'b0;
                    end
                end

                // State 1: Accumulate multiplier outputs for pass_j
                2'd1: begin
                        case (pass_j)
                            3'd0: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd1;
                            end
                            3'd1: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd2;
                            end
                            3'd2: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd3;
                            end
                            3'd3: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd4;
                            end
                            3'd4: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd5;
                            end
                            3'd5: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd6;
                            end
                            3'd6: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd7;
                            end
                            3'd7: begin
                                C_flat[0*32 +: 32] <= C_flat[0*32 +: 32] + C_out_packed[0][0*32 +: 32];
                                C_flat[1*32 +: 32] <= C_flat[1*32 +: 32] + C_out_packed[0][1*32 +: 32];
                                C_flat[16*32 +: 32] <= C_flat[16*32 +: 32] + C_out_packed[0][2*32 +: 32];
                                C_flat[17*32 +: 32] <= C_flat[17*32 +: 32] + C_out_packed[0][3*32 +: 32];
                                C_flat[2*32 +: 32] <= C_flat[2*32 +: 32] + C_out_packed[1][0*32 +: 32];
                                C_flat[3*32 +: 32] <= C_flat[3*32 +: 32] + C_out_packed[1][1*32 +: 32];
                                C_flat[18*32 +: 32] <= C_flat[18*32 +: 32] + C_out_packed[1][2*32 +: 32];
                                C_flat[19*32 +: 32] <= C_flat[19*32 +: 32] + C_out_packed[1][3*32 +: 32];
                                C_flat[4*32 +: 32] <= C_flat[4*32 +: 32] + C_out_packed[2][0*32 +: 32];
                                C_flat[5*32 +: 32] <= C_flat[5*32 +: 32] + C_out_packed[2][1*32 +: 32];
                                C_flat[20*32 +: 32] <= C_flat[20*32 +: 32] + C_out_packed[2][2*32 +: 32];
                                C_flat[21*32 +: 32] <= C_flat[21*32 +: 32] + C_out_packed[2][3*32 +: 32];
                                C_flat[6*32 +: 32] <= C_flat[6*32 +: 32] + C_out_packed[3][0*32 +: 32];
                                C_flat[7*32 +: 32] <= C_flat[7*32 +: 32] + C_out_packed[3][1*32 +: 32];
                                C_flat[22*32 +: 32] <= C_flat[22*32 +: 32] + C_out_packed[3][2*32 +: 32];
                                C_flat[23*32 +: 32] <= C_flat[23*32 +: 32] + C_out_packed[3][3*32 +: 32];
                                C_flat[8*32 +: 32] <= C_flat[8*32 +: 32] + C_out_packed[4][0*32 +: 32];
                                C_flat[9*32 +: 32] <= C_flat[9*32 +: 32] + C_out_packed[4][1*32 +: 32];
                                C_flat[24*32 +: 32] <= C_flat[24*32 +: 32] + C_out_packed[4][2*32 +: 32];
                                C_flat[25*32 +: 32] <= C_flat[25*32 +: 32] + C_out_packed[4][3*32 +: 32];
                                C_flat[10*32 +: 32] <= C_flat[10*32 +: 32] + C_out_packed[5][0*32 +: 32];
                                C_flat[11*32 +: 32] <= C_flat[11*32 +: 32] + C_out_packed[5][1*32 +: 32];
                                C_flat[26*32 +: 32] <= C_flat[26*32 +: 32] + C_out_packed[5][2*32 +: 32];
                                C_flat[27*32 +: 32] <= C_flat[27*32 +: 32] + C_out_packed[5][3*32 +: 32];
                                C_flat[12*32 +: 32] <= C_flat[12*32 +: 32] + C_out_packed[6][0*32 +: 32];
                                C_flat[13*32 +: 32] <= C_flat[13*32 +: 32] + C_out_packed[6][1*32 +: 32];
                                C_flat[28*32 +: 32] <= C_flat[28*32 +: 32] + C_out_packed[6][2*32 +: 32];
                                C_flat[29*32 +: 32] <= C_flat[29*32 +: 32] + C_out_packed[6][3*32 +: 32];
                                C_flat[14*32 +: 32] <= C_flat[14*32 +: 32] + C_out_packed[7][0*32 +: 32];
                                C_flat[15*32 +: 32] <= C_flat[15*32 +: 32] + C_out_packed[7][1*32 +: 32];
                                C_flat[30*32 +: 32] <= C_flat[30*32 +: 32] + C_out_packed[7][2*32 +: 32];
                                C_flat[31*32 +: 32] <= C_flat[31*32 +: 32] + C_out_packed[7][3*32 +: 32];
                                C_flat[32*32 +: 32] <= C_flat[32*32 +: 32] + C_out_packed[8][0*32 +: 32];
                                C_flat[33*32 +: 32] <= C_flat[33*32 +: 32] + C_out_packed[8][1*32 +: 32];
                                C_flat[48*32 +: 32] <= C_flat[48*32 +: 32] + C_out_packed[8][2*32 +: 32];
                                C_flat[49*32 +: 32] <= C_flat[49*32 +: 32] + C_out_packed[8][3*32 +: 32];
                                C_flat[34*32 +: 32] <= C_flat[34*32 +: 32] + C_out_packed[9][0*32 +: 32];
                                C_flat[35*32 +: 32] <= C_flat[35*32 +: 32] + C_out_packed[9][1*32 +: 32];
                                C_flat[50*32 +: 32] <= C_flat[50*32 +: 32] + C_out_packed[9][2*32 +: 32];
                                C_flat[51*32 +: 32] <= C_flat[51*32 +: 32] + C_out_packed[9][3*32 +: 32];
                                C_flat[36*32 +: 32] <= C_flat[36*32 +: 32] + C_out_packed[10][0*32 +: 32];
                                C_flat[37*32 +: 32] <= C_flat[37*32 +: 32] + C_out_packed[10][1*32 +: 32];
                                C_flat[52*32 +: 32] <= C_flat[52*32 +: 32] + C_out_packed[10][2*32 +: 32];
                                C_flat[53*32 +: 32] <= C_flat[53*32 +: 32] + C_out_packed[10][3*32 +: 32];
                                C_flat[38*32 +: 32] <= C_flat[38*32 +: 32] + C_out_packed[11][0*32 +: 32];
                                C_flat[39*32 +: 32] <= C_flat[39*32 +: 32] + C_out_packed[11][1*32 +: 32];
                                C_flat[54*32 +: 32] <= C_flat[54*32 +: 32] + C_out_packed[11][2*32 +: 32];
                                C_flat[55*32 +: 32] <= C_flat[55*32 +: 32] + C_out_packed[11][3*32 +: 32];
                                C_flat[40*32 +: 32] <= C_flat[40*32 +: 32] + C_out_packed[12][0*32 +: 32];
                                C_flat[41*32 +: 32] <= C_flat[41*32 +: 32] + C_out_packed[12][1*32 +: 32];
                                C_flat[56*32 +: 32] <= C_flat[56*32 +: 32] + C_out_packed[12][2*32 +: 32];
                                C_flat[57*32 +: 32] <= C_flat[57*32 +: 32] + C_out_packed[12][3*32 +: 32];
                                C_flat[42*32 +: 32] <= C_flat[42*32 +: 32] + C_out_packed[13][0*32 +: 32];
                                C_flat[43*32 +: 32] <= C_flat[43*32 +: 32] + C_out_packed[13][1*32 +: 32];
                                C_flat[58*32 +: 32] <= C_flat[58*32 +: 32] + C_out_packed[13][2*32 +: 32];
                                C_flat[59*32 +: 32] <= C_flat[59*32 +: 32] + C_out_packed[13][3*32 +: 32];
                                C_flat[44*32 +: 32] <= C_flat[44*32 +: 32] + C_out_packed[14][0*32 +: 32];
                                C_flat[45*32 +: 32] <= C_flat[45*32 +: 32] + C_out_packed[14][1*32 +: 32];
                                C_flat[60*32 +: 32] <= C_flat[60*32 +: 32] + C_out_packed[14][2*32 +: 32];
                                C_flat[61*32 +: 32] <= C_flat[61*32 +: 32] + C_out_packed[14][3*32 +: 32];
                                C_flat[46*32 +: 32] <= C_flat[46*32 +: 32] + C_out_packed[15][0*32 +: 32];
                                C_flat[47*32 +: 32] <= C_flat[47*32 +: 32] + C_out_packed[15][1*32 +: 32];
                                C_flat[62*32 +: 32] <= C_flat[62*32 +: 32] + C_out_packed[15][2*32 +: 32];
                                C_flat[63*32 +: 32] <= C_flat[63*32 +: 32] + C_out_packed[15][3*32 +: 32];
                                C_flat[64*32 +: 32] <= C_flat[64*32 +: 32] + C_out_packed[16][0*32 +: 32];
                                C_flat[65*32 +: 32] <= C_flat[65*32 +: 32] + C_out_packed[16][1*32 +: 32];
                                C_flat[80*32 +: 32] <= C_flat[80*32 +: 32] + C_out_packed[16][2*32 +: 32];
                                C_flat[81*32 +: 32] <= C_flat[81*32 +: 32] + C_out_packed[16][3*32 +: 32];
                                C_flat[66*32 +: 32] <= C_flat[66*32 +: 32] + C_out_packed[17][0*32 +: 32];
                                C_flat[67*32 +: 32] <= C_flat[67*32 +: 32] + C_out_packed[17][1*32 +: 32];
                                C_flat[82*32 +: 32] <= C_flat[82*32 +: 32] + C_out_packed[17][2*32 +: 32];
                                C_flat[83*32 +: 32] <= C_flat[83*32 +: 32] + C_out_packed[17][3*32 +: 32];
                                C_flat[68*32 +: 32] <= C_flat[68*32 +: 32] + C_out_packed[18][0*32 +: 32];
                                C_flat[69*32 +: 32] <= C_flat[69*32 +: 32] + C_out_packed[18][1*32 +: 32];
                                C_flat[84*32 +: 32] <= C_flat[84*32 +: 32] + C_out_packed[18][2*32 +: 32];
                                C_flat[85*32 +: 32] <= C_flat[85*32 +: 32] + C_out_packed[18][3*32 +: 32];
                                C_flat[70*32 +: 32] <= C_flat[70*32 +: 32] + C_out_packed[19][0*32 +: 32];
                                C_flat[71*32 +: 32] <= C_flat[71*32 +: 32] + C_out_packed[19][1*32 +: 32];
                                C_flat[86*32 +: 32] <= C_flat[86*32 +: 32] + C_out_packed[19][2*32 +: 32];
                                C_flat[87*32 +: 32] <= C_flat[87*32 +: 32] + C_out_packed[19][3*32 +: 32];
                                C_flat[72*32 +: 32] <= C_flat[72*32 +: 32] + C_out_packed[20][0*32 +: 32];
                                C_flat[73*32 +: 32] <= C_flat[73*32 +: 32] + C_out_packed[20][1*32 +: 32];
                                C_flat[88*32 +: 32] <= C_flat[88*32 +: 32] + C_out_packed[20][2*32 +: 32];
                                C_flat[89*32 +: 32] <= C_flat[89*32 +: 32] + C_out_packed[20][3*32 +: 32];
                                C_flat[74*32 +: 32] <= C_flat[74*32 +: 32] + C_out_packed[21][0*32 +: 32];
                                C_flat[75*32 +: 32] <= C_flat[75*32 +: 32] + C_out_packed[21][1*32 +: 32];
                                C_flat[90*32 +: 32] <= C_flat[90*32 +: 32] + C_out_packed[21][2*32 +: 32];
                                C_flat[91*32 +: 32] <= C_flat[91*32 +: 32] + C_out_packed[21][3*32 +: 32];
                                C_flat[76*32 +: 32] <= C_flat[76*32 +: 32] + C_out_packed[22][0*32 +: 32];
                                C_flat[77*32 +: 32] <= C_flat[77*32 +: 32] + C_out_packed[22][1*32 +: 32];
                                C_flat[92*32 +: 32] <= C_flat[92*32 +: 32] + C_out_packed[22][2*32 +: 32];
                                C_flat[93*32 +: 32] <= C_flat[93*32 +: 32] + C_out_packed[22][3*32 +: 32];
                                C_flat[78*32 +: 32] <= C_flat[78*32 +: 32] + C_out_packed[23][0*32 +: 32];
                                C_flat[79*32 +: 32] <= C_flat[79*32 +: 32] + C_out_packed[23][1*32 +: 32];
                                C_flat[94*32 +: 32] <= C_flat[94*32 +: 32] + C_out_packed[23][2*32 +: 32];
                                C_flat[95*32 +: 32] <= C_flat[95*32 +: 32] + C_out_packed[23][3*32 +: 32];
                                C_flat[96*32 +: 32] <= C_flat[96*32 +: 32] + C_out_packed[24][0*32 +: 32];
                                C_flat[97*32 +: 32] <= C_flat[97*32 +: 32] + C_out_packed[24][1*32 +: 32];
                                C_flat[112*32 +: 32] <= C_flat[112*32 +: 32] + C_out_packed[24][2*32 +: 32];
                                C_flat[113*32 +: 32] <= C_flat[113*32 +: 32] + C_out_packed[24][3*32 +: 32];
                                C_flat[98*32 +: 32] <= C_flat[98*32 +: 32] + C_out_packed[25][0*32 +: 32];
                                C_flat[99*32 +: 32] <= C_flat[99*32 +: 32] + C_out_packed[25][1*32 +: 32];
                                C_flat[114*32 +: 32] <= C_flat[114*32 +: 32] + C_out_packed[25][2*32 +: 32];
                                C_flat[115*32 +: 32] <= C_flat[115*32 +: 32] + C_out_packed[25][3*32 +: 32];
                                C_flat[100*32 +: 32] <= C_flat[100*32 +: 32] + C_out_packed[26][0*32 +: 32];
                                C_flat[101*32 +: 32] <= C_flat[101*32 +: 32] + C_out_packed[26][1*32 +: 32];
                                C_flat[116*32 +: 32] <= C_flat[116*32 +: 32] + C_out_packed[26][2*32 +: 32];
                                C_flat[117*32 +: 32] <= C_flat[117*32 +: 32] + C_out_packed[26][3*32 +: 32];
                                C_flat[102*32 +: 32] <= C_flat[102*32 +: 32] + C_out_packed[27][0*32 +: 32];
                                C_flat[103*32 +: 32] <= C_flat[103*32 +: 32] + C_out_packed[27][1*32 +: 32];
                                C_flat[118*32 +: 32] <= C_flat[118*32 +: 32] + C_out_packed[27][2*32 +: 32];
                                C_flat[119*32 +: 32] <= C_flat[119*32 +: 32] + C_out_packed[27][3*32 +: 32];
                                C_flat[104*32 +: 32] <= C_flat[104*32 +: 32] + C_out_packed[28][0*32 +: 32];
                                C_flat[105*32 +: 32] <= C_flat[105*32 +: 32] + C_out_packed[28][1*32 +: 32];
                                C_flat[120*32 +: 32] <= C_flat[120*32 +: 32] + C_out_packed[28][2*32 +: 32];
                                C_flat[121*32 +: 32] <= C_flat[121*32 +: 32] + C_out_packed[28][3*32 +: 32];
                                C_flat[106*32 +: 32] <= C_flat[106*32 +: 32] + C_out_packed[29][0*32 +: 32];
                                C_flat[107*32 +: 32] <= C_flat[107*32 +: 32] + C_out_packed[29][1*32 +: 32];
                                C_flat[122*32 +: 32] <= C_flat[122*32 +: 32] + C_out_packed[29][2*32 +: 32];
                                C_flat[123*32 +: 32] <= C_flat[123*32 +: 32] + C_out_packed[29][3*32 +: 32];
                                C_flat[108*32 +: 32] <= C_flat[108*32 +: 32] + C_out_packed[30][0*32 +: 32];
                                C_flat[109*32 +: 32] <= C_flat[109*32 +: 32] + C_out_packed[30][1*32 +: 32];
                                C_flat[124*32 +: 32] <= C_flat[124*32 +: 32] + C_out_packed[30][2*32 +: 32];
                                C_flat[125*32 +: 32] <= C_flat[125*32 +: 32] + C_out_packed[30][3*32 +: 32];
                                C_flat[110*32 +: 32] <= C_flat[110*32 +: 32] + C_out_packed[31][0*32 +: 32];
                                C_flat[111*32 +: 32] <= C_flat[111*32 +: 32] + C_out_packed[31][1*32 +: 32];
                                C_flat[126*32 +: 32] <= C_flat[126*32 +: 32] + C_out_packed[31][2*32 +: 32];
                                C_flat[127*32 +: 32] <= C_flat[127*32 +: 32] + C_out_packed[31][3*32 +: 32];
                                C_flat[128*32 +: 32] <= C_flat[128*32 +: 32] + C_out_packed[32][0*32 +: 32];
                                C_flat[129*32 +: 32] <= C_flat[129*32 +: 32] + C_out_packed[32][1*32 +: 32];
                                C_flat[144*32 +: 32] <= C_flat[144*32 +: 32] + C_out_packed[32][2*32 +: 32];
                                C_flat[145*32 +: 32] <= C_flat[145*32 +: 32] + C_out_packed[32][3*32 +: 32];
                                C_flat[130*32 +: 32] <= C_flat[130*32 +: 32] + C_out_packed[33][0*32 +: 32];
                                C_flat[131*32 +: 32] <= C_flat[131*32 +: 32] + C_out_packed[33][1*32 +: 32];
                                C_flat[146*32 +: 32] <= C_flat[146*32 +: 32] + C_out_packed[33][2*32 +: 32];
                                C_flat[147*32 +: 32] <= C_flat[147*32 +: 32] + C_out_packed[33][3*32 +: 32];
                                C_flat[132*32 +: 32] <= C_flat[132*32 +: 32] + C_out_packed[34][0*32 +: 32];
                                C_flat[133*32 +: 32] <= C_flat[133*32 +: 32] + C_out_packed[34][1*32 +: 32];
                                C_flat[148*32 +: 32] <= C_flat[148*32 +: 32] + C_out_packed[34][2*32 +: 32];
                                C_flat[149*32 +: 32] <= C_flat[149*32 +: 32] + C_out_packed[34][3*32 +: 32];
                                C_flat[134*32 +: 32] <= C_flat[134*32 +: 32] + C_out_packed[35][0*32 +: 32];
                                C_flat[135*32 +: 32] <= C_flat[135*32 +: 32] + C_out_packed[35][1*32 +: 32];
                                C_flat[150*32 +: 32] <= C_flat[150*32 +: 32] + C_out_packed[35][2*32 +: 32];
                                C_flat[151*32 +: 32] <= C_flat[151*32 +: 32] + C_out_packed[35][3*32 +: 32];
                                C_flat[136*32 +: 32] <= C_flat[136*32 +: 32] + C_out_packed[36][0*32 +: 32];
                                C_flat[137*32 +: 32] <= C_flat[137*32 +: 32] + C_out_packed[36][1*32 +: 32];
                                C_flat[152*32 +: 32] <= C_flat[152*32 +: 32] + C_out_packed[36][2*32 +: 32];
                                C_flat[153*32 +: 32] <= C_flat[153*32 +: 32] + C_out_packed[36][3*32 +: 32];
                                C_flat[138*32 +: 32] <= C_flat[138*32 +: 32] + C_out_packed[37][0*32 +: 32];
                                C_flat[139*32 +: 32] <= C_flat[139*32 +: 32] + C_out_packed[37][1*32 +: 32];
                                C_flat[154*32 +: 32] <= C_flat[154*32 +: 32] + C_out_packed[37][2*32 +: 32];
                                C_flat[155*32 +: 32] <= C_flat[155*32 +: 32] + C_out_packed[37][3*32 +: 32];
                                C_flat[140*32 +: 32] <= C_flat[140*32 +: 32] + C_out_packed[38][0*32 +: 32];
                                C_flat[141*32 +: 32] <= C_flat[141*32 +: 32] + C_out_packed[38][1*32 +: 32];
                                C_flat[156*32 +: 32] <= C_flat[156*32 +: 32] + C_out_packed[38][2*32 +: 32];
                                C_flat[157*32 +: 32] <= C_flat[157*32 +: 32] + C_out_packed[38][3*32 +: 32];
                                C_flat[142*32 +: 32] <= C_flat[142*32 +: 32] + C_out_packed[39][0*32 +: 32];
                                C_flat[143*32 +: 32] <= C_flat[143*32 +: 32] + C_out_packed[39][1*32 +: 32];
                                C_flat[158*32 +: 32] <= C_flat[158*32 +: 32] + C_out_packed[39][2*32 +: 32];
                                C_flat[159*32 +: 32] <= C_flat[159*32 +: 32] + C_out_packed[39][3*32 +: 32];
                                C_flat[160*32 +: 32] <= C_flat[160*32 +: 32] + C_out_packed[40][0*32 +: 32];
                                C_flat[161*32 +: 32] <= C_flat[161*32 +: 32] + C_out_packed[40][1*32 +: 32];
                                C_flat[176*32 +: 32] <= C_flat[176*32 +: 32] + C_out_packed[40][2*32 +: 32];
                                C_flat[177*32 +: 32] <= C_flat[177*32 +: 32] + C_out_packed[40][3*32 +: 32];
                                C_flat[162*32 +: 32] <= C_flat[162*32 +: 32] + C_out_packed[41][0*32 +: 32];
                                C_flat[163*32 +: 32] <= C_flat[163*32 +: 32] + C_out_packed[41][1*32 +: 32];
                                C_flat[178*32 +: 32] <= C_flat[178*32 +: 32] + C_out_packed[41][2*32 +: 32];
                                C_flat[179*32 +: 32] <= C_flat[179*32 +: 32] + C_out_packed[41][3*32 +: 32];
                                C_flat[164*32 +: 32] <= C_flat[164*32 +: 32] + C_out_packed[42][0*32 +: 32];
                                C_flat[165*32 +: 32] <= C_flat[165*32 +: 32] + C_out_packed[42][1*32 +: 32];
                                C_flat[180*32 +: 32] <= C_flat[180*32 +: 32] + C_out_packed[42][2*32 +: 32];
                                C_flat[181*32 +: 32] <= C_flat[181*32 +: 32] + C_out_packed[42][3*32 +: 32];
                                C_flat[166*32 +: 32] <= C_flat[166*32 +: 32] + C_out_packed[43][0*32 +: 32];
                                C_flat[167*32 +: 32] <= C_flat[167*32 +: 32] + C_out_packed[43][1*32 +: 32];
                                C_flat[182*32 +: 32] <= C_flat[182*32 +: 32] + C_out_packed[43][2*32 +: 32];
                                C_flat[183*32 +: 32] <= C_flat[183*32 +: 32] + C_out_packed[43][3*32 +: 32];
                                C_flat[168*32 +: 32] <= C_flat[168*32 +: 32] + C_out_packed[44][0*32 +: 32];
                                C_flat[169*32 +: 32] <= C_flat[169*32 +: 32] + C_out_packed[44][1*32 +: 32];
                                C_flat[184*32 +: 32] <= C_flat[184*32 +: 32] + C_out_packed[44][2*32 +: 32];
                                C_flat[185*32 +: 32] <= C_flat[185*32 +: 32] + C_out_packed[44][3*32 +: 32];
                                C_flat[170*32 +: 32] <= C_flat[170*32 +: 32] + C_out_packed[45][0*32 +: 32];
                                C_flat[171*32 +: 32] <= C_flat[171*32 +: 32] + C_out_packed[45][1*32 +: 32];
                                C_flat[186*32 +: 32] <= C_flat[186*32 +: 32] + C_out_packed[45][2*32 +: 32];
                                C_flat[187*32 +: 32] <= C_flat[187*32 +: 32] + C_out_packed[45][3*32 +: 32];
                                C_flat[172*32 +: 32] <= C_flat[172*32 +: 32] + C_out_packed[46][0*32 +: 32];
                                C_flat[173*32 +: 32] <= C_flat[173*32 +: 32] + C_out_packed[46][1*32 +: 32];
                                C_flat[188*32 +: 32] <= C_flat[188*32 +: 32] + C_out_packed[46][2*32 +: 32];
                                C_flat[189*32 +: 32] <= C_flat[189*32 +: 32] + C_out_packed[46][3*32 +: 32];
                                C_flat[174*32 +: 32] <= C_flat[174*32 +: 32] + C_out_packed[47][0*32 +: 32];
                                C_flat[175*32 +: 32] <= C_flat[175*32 +: 32] + C_out_packed[47][1*32 +: 32];
                                C_flat[190*32 +: 32] <= C_flat[190*32 +: 32] + C_out_packed[47][2*32 +: 32];
                                C_flat[191*32 +: 32] <= C_flat[191*32 +: 32] + C_out_packed[47][3*32 +: 32];
                                C_flat[192*32 +: 32] <= C_flat[192*32 +: 32] + C_out_packed[48][0*32 +: 32];
                                C_flat[193*32 +: 32] <= C_flat[193*32 +: 32] + C_out_packed[48][1*32 +: 32];
                                C_flat[208*32 +: 32] <= C_flat[208*32 +: 32] + C_out_packed[48][2*32 +: 32];
                                C_flat[209*32 +: 32] <= C_flat[209*32 +: 32] + C_out_packed[48][3*32 +: 32];
                                C_flat[194*32 +: 32] <= C_flat[194*32 +: 32] + C_out_packed[49][0*32 +: 32];
                                C_flat[195*32 +: 32] <= C_flat[195*32 +: 32] + C_out_packed[49][1*32 +: 32];
                                C_flat[210*32 +: 32] <= C_flat[210*32 +: 32] + C_out_packed[49][2*32 +: 32];
                                C_flat[211*32 +: 32] <= C_flat[211*32 +: 32] + C_out_packed[49][3*32 +: 32];
                                C_flat[196*32 +: 32] <= C_flat[196*32 +: 32] + C_out_packed[50][0*32 +: 32];
                                C_flat[197*32 +: 32] <= C_flat[197*32 +: 32] + C_out_packed[50][1*32 +: 32];
                                C_flat[212*32 +: 32] <= C_flat[212*32 +: 32] + C_out_packed[50][2*32 +: 32];
                                C_flat[213*32 +: 32] <= C_flat[213*32 +: 32] + C_out_packed[50][3*32 +: 32];
                                C_flat[198*32 +: 32] <= C_flat[198*32 +: 32] + C_out_packed[51][0*32 +: 32];
                                C_flat[199*32 +: 32] <= C_flat[199*32 +: 32] + C_out_packed[51][1*32 +: 32];
                                C_flat[214*32 +: 32] <= C_flat[214*32 +: 32] + C_out_packed[51][2*32 +: 32];
                                C_flat[215*32 +: 32] <= C_flat[215*32 +: 32] + C_out_packed[51][3*32 +: 32];
                                C_flat[200*32 +: 32] <= C_flat[200*32 +: 32] + C_out_packed[52][0*32 +: 32];
                                C_flat[201*32 +: 32] <= C_flat[201*32 +: 32] + C_out_packed[52][1*32 +: 32];
                                C_flat[216*32 +: 32] <= C_flat[216*32 +: 32] + C_out_packed[52][2*32 +: 32];
                                C_flat[217*32 +: 32] <= C_flat[217*32 +: 32] + C_out_packed[52][3*32 +: 32];
                                C_flat[202*32 +: 32] <= C_flat[202*32 +: 32] + C_out_packed[53][0*32 +: 32];
                                C_flat[203*32 +: 32] <= C_flat[203*32 +: 32] + C_out_packed[53][1*32 +: 32];
                                C_flat[218*32 +: 32] <= C_flat[218*32 +: 32] + C_out_packed[53][2*32 +: 32];
                                C_flat[219*32 +: 32] <= C_flat[219*32 +: 32] + C_out_packed[53][3*32 +: 32];
                                C_flat[204*32 +: 32] <= C_flat[204*32 +: 32] + C_out_packed[54][0*32 +: 32];
                                C_flat[205*32 +: 32] <= C_flat[205*32 +: 32] + C_out_packed[54][1*32 +: 32];
                                C_flat[220*32 +: 32] <= C_flat[220*32 +: 32] + C_out_packed[54][2*32 +: 32];
                                C_flat[221*32 +: 32] <= C_flat[221*32 +: 32] + C_out_packed[54][3*32 +: 32];
                                C_flat[206*32 +: 32] <= C_flat[206*32 +: 32] + C_out_packed[55][0*32 +: 32];
                                C_flat[207*32 +: 32] <= C_flat[207*32 +: 32] + C_out_packed[55][1*32 +: 32];
                                C_flat[222*32 +: 32] <= C_flat[222*32 +: 32] + C_out_packed[55][2*32 +: 32];
                                C_flat[223*32 +: 32] <= C_flat[223*32 +: 32] + C_out_packed[55][3*32 +: 32];
                                C_flat[224*32 +: 32] <= C_flat[224*32 +: 32] + C_out_packed[56][0*32 +: 32];
                                C_flat[225*32 +: 32] <= C_flat[225*32 +: 32] + C_out_packed[56][1*32 +: 32];
                                C_flat[240*32 +: 32] <= C_flat[240*32 +: 32] + C_out_packed[56][2*32 +: 32];
                                C_flat[241*32 +: 32] <= C_flat[241*32 +: 32] + C_out_packed[56][3*32 +: 32];
                                C_flat[226*32 +: 32] <= C_flat[226*32 +: 32] + C_out_packed[57][0*32 +: 32];
                                C_flat[227*32 +: 32] <= C_flat[227*32 +: 32] + C_out_packed[57][1*32 +: 32];
                                C_flat[242*32 +: 32] <= C_flat[242*32 +: 32] + C_out_packed[57][2*32 +: 32];
                                C_flat[243*32 +: 32] <= C_flat[243*32 +: 32] + C_out_packed[57][3*32 +: 32];
                                C_flat[228*32 +: 32] <= C_flat[228*32 +: 32] + C_out_packed[58][0*32 +: 32];
                                C_flat[229*32 +: 32] <= C_flat[229*32 +: 32] + C_out_packed[58][1*32 +: 32];
                                C_flat[244*32 +: 32] <= C_flat[244*32 +: 32] + C_out_packed[58][2*32 +: 32];
                                C_flat[245*32 +: 32] <= C_flat[245*32 +: 32] + C_out_packed[58][3*32 +: 32];
                                C_flat[230*32 +: 32] <= C_flat[230*32 +: 32] + C_out_packed[59][0*32 +: 32];
                                C_flat[231*32 +: 32] <= C_flat[231*32 +: 32] + C_out_packed[59][1*32 +: 32];
                                C_flat[246*32 +: 32] <= C_flat[246*32 +: 32] + C_out_packed[59][2*32 +: 32];
                                C_flat[247*32 +: 32] <= C_flat[247*32 +: 32] + C_out_packed[59][3*32 +: 32];
                                C_flat[232*32 +: 32] <= C_flat[232*32 +: 32] + C_out_packed[60][0*32 +: 32];
                                C_flat[233*32 +: 32] <= C_flat[233*32 +: 32] + C_out_packed[60][1*32 +: 32];
                                C_flat[248*32 +: 32] <= C_flat[248*32 +: 32] + C_out_packed[60][2*32 +: 32];
                                C_flat[249*32 +: 32] <= C_flat[249*32 +: 32] + C_out_packed[60][3*32 +: 32];
                                C_flat[234*32 +: 32] <= C_flat[234*32 +: 32] + C_out_packed[61][0*32 +: 32];
                                C_flat[235*32 +: 32] <= C_flat[235*32 +: 32] + C_out_packed[61][1*32 +: 32];
                                C_flat[250*32 +: 32] <= C_flat[250*32 +: 32] + C_out_packed[61][2*32 +: 32];
                                C_flat[251*32 +: 32] <= C_flat[251*32 +: 32] + C_out_packed[61][3*32 +: 32];
                                C_flat[236*32 +: 32] <= C_flat[236*32 +: 32] + C_out_packed[62][0*32 +: 32];
                                C_flat[237*32 +: 32] <= C_flat[237*32 +: 32] + C_out_packed[62][1*32 +: 32];
                                C_flat[252*32 +: 32] <= C_flat[252*32 +: 32] + C_out_packed[62][2*32 +: 32];
                                C_flat[253*32 +: 32] <= C_flat[253*32 +: 32] + C_out_packed[62][3*32 +: 32];
                                C_flat[238*32 +: 32] <= C_flat[238*32 +: 32] + C_out_packed[63][0*32 +: 32];
                                C_flat[239*32 +: 32] <= C_flat[239*32 +: 32] + C_out_packed[63][1*32 +: 32];
                                C_flat[254*32 +: 32] <= C_flat[254*32 +: 32] + C_out_packed[63][2*32 +: 32];
                                C_flat[255*32 +: 32] <= C_flat[255*32 +: 32] + C_out_packed[63][3*32 +: 32];
                                pass_j <= 3'd0;
                            end
                        endcase
			done <= 1'b1;
			state <= 2'd2;

                end

                // State 2: Done
                2'd2: begin
                    done <= 1'b1;
                    state <= 2'd2;
                end
		2'd3: begin
		   state <= 2'd0;
		end
            endcase
        end
    end
    
    // Undefine macro if used
    `undef SLICE
    `undef SLICE32
    mat2x2_mult m0 (
        .A_in(A_in_packed[0]),
        .B_in(B_in_packed[0]),
        .C_out(C_out_packed[0])
    );
    mat2x2_mult m1 (
        .A_in(A_in_packed[1]),
        .B_in(B_in_packed[1]),
        .C_out(C_out_packed[1])
    );
    mat2x2_mult m2 (
        .A_in(A_in_packed[2]),
        .B_in(B_in_packed[2]),
        .C_out(C_out_packed[2])
    );
    mat2x2_mult m3 (
        .A_in(A_in_packed[3]),
        .B_in(B_in_packed[3]),
        .C_out(C_out_packed[3])
    );
    mat2x2_mult m4 (
        .A_in(A_in_packed[4]),
        .B_in(B_in_packed[4]),
        .C_out(C_out_packed[4])
    );
    mat2x2_mult m5 (
        .A_in(A_in_packed[5]),
        .B_in(B_in_packed[5]),
        .C_out(C_out_packed[5])
    );
    mat2x2_mult m6 (
        .A_in(A_in_packed[6]),
        .B_in(B_in_packed[6]),
        .C_out(C_out_packed[6])
    );
    mat2x2_mult m7 (
        .A_in(A_in_packed[7]),
        .B_in(B_in_packed[7]),
        .C_out(C_out_packed[7])
    );
    mat2x2_mult m8 (
        .A_in(A_in_packed[8]),
        .B_in(B_in_packed[8]),
        .C_out(C_out_packed[8])
    );
    mat2x2_mult m9 (
        .A_in(A_in_packed[9]),
        .B_in(B_in_packed[9]),
        .C_out(C_out_packed[9])
    );
    mat2x2_mult m10 (
        .A_in(A_in_packed[10]),
        .B_in(B_in_packed[10]),
        .C_out(C_out_packed[10])
    );
    mat2x2_mult m11 (
        .A_in(A_in_packed[11]),
        .B_in(B_in_packed[11]),
        .C_out(C_out_packed[11])
    );
    mat2x2_mult m12 (
        .A_in(A_in_packed[12]),
        .B_in(B_in_packed[12]),
        .C_out(C_out_packed[12])
    );
    mat2x2_mult m13 (
        .A_in(A_in_packed[13]),
        .B_in(B_in_packed[13]),
        .C_out(C_out_packed[13])
    );
    mat2x2_mult m14 (
        .A_in(A_in_packed[14]),
        .B_in(B_in_packed[14]),
        .C_out(C_out_packed[14])
    );
    mat2x2_mult m15 (
        .A_in(A_in_packed[15]),
        .B_in(B_in_packed[15]),
        .C_out(C_out_packed[15])
    );
    mat2x2_mult m16 (
        .A_in(A_in_packed[16]),
        .B_in(B_in_packed[16]),
        .C_out(C_out_packed[16])
    );
    mat2x2_mult m17 (
        .A_in(A_in_packed[17]),
        .B_in(B_in_packed[17]),
        .C_out(C_out_packed[17])
    );
    mat2x2_mult m18 (
        .A_in(A_in_packed[18]),
        .B_in(B_in_packed[18]),
        .C_out(C_out_packed[18])
    );
    mat2x2_mult m19 (
        .A_in(A_in_packed[19]),
        .B_in(B_in_packed[19]),
        .C_out(C_out_packed[19])
    );
    mat2x2_mult m20 (
        .A_in(A_in_packed[20]),
        .B_in(B_in_packed[20]),
        .C_out(C_out_packed[20])
    );
    mat2x2_mult m21 (
        .A_in(A_in_packed[21]),
        .B_in(B_in_packed[21]),
        .C_out(C_out_packed[21])
    );
    mat2x2_mult m22 (
        .A_in(A_in_packed[22]),
        .B_in(B_in_packed[22]),
        .C_out(C_out_packed[22])
    );
    mat2x2_mult m23 (
        .A_in(A_in_packed[23]),
        .B_in(B_in_packed[23]),
        .C_out(C_out_packed[23])
    );
    mat2x2_mult m24 (
        .A_in(A_in_packed[24]),
        .B_in(B_in_packed[24]),
        .C_out(C_out_packed[24])
    );
    mat2x2_mult m25 (
        .A_in(A_in_packed[25]),
        .B_in(B_in_packed[25]),
        .C_out(C_out_packed[25])
    );
    mat2x2_mult m26 (
        .A_in(A_in_packed[26]),
        .B_in(B_in_packed[26]),
        .C_out(C_out_packed[26])
    );
    mat2x2_mult m27 (
        .A_in(A_in_packed[27]),
        .B_in(B_in_packed[27]),
        .C_out(C_out_packed[27])
    );
    mat2x2_mult m28 (
        .A_in(A_in_packed[28]),
        .B_in(B_in_packed[28]),
        .C_out(C_out_packed[28])
    );
    mat2x2_mult m29 (
        .A_in(A_in_packed[29]),
        .B_in(B_in_packed[29]),
        .C_out(C_out_packed[29])
    );
    mat2x2_mult m30 (
        .A_in(A_in_packed[30]),
        .B_in(B_in_packed[30]),
        .C_out(C_out_packed[30])
    );
    mat2x2_mult m31 (
        .A_in(A_in_packed[31]),
        .B_in(B_in_packed[31]),
        .C_out(C_out_packed[31])
    );
    mat2x2_mult m32 (
        .A_in(A_in_packed[32]),
        .B_in(B_in_packed[32]),
        .C_out(C_out_packed[32])
    );
    mat2x2_mult m33 (
        .A_in(A_in_packed[33]),
        .B_in(B_in_packed[33]),
        .C_out(C_out_packed[33])
    );
    mat2x2_mult m34 (
        .A_in(A_in_packed[34]),
        .B_in(B_in_packed[34]),
        .C_out(C_out_packed[34])
    );
    mat2x2_mult m35 (
        .A_in(A_in_packed[35]),
        .B_in(B_in_packed[35]),
        .C_out(C_out_packed[35])
    );
    mat2x2_mult m36 (
        .A_in(A_in_packed[36]),
        .B_in(B_in_packed[36]),
        .C_out(C_out_packed[36])
    );
    mat2x2_mult m37 (
        .A_in(A_in_packed[37]),
        .B_in(B_in_packed[37]),
        .C_out(C_out_packed[37])
    );
    mat2x2_mult m38 (
        .A_in(A_in_packed[38]),
        .B_in(B_in_packed[38]),
        .C_out(C_out_packed[38])
    );
    mat2x2_mult m39 (
        .A_in(A_in_packed[39]),
        .B_in(B_in_packed[39]),
        .C_out(C_out_packed[39])
    );
    mat2x2_mult m40 (
        .A_in(A_in_packed[40]),
        .B_in(B_in_packed[40]),
        .C_out(C_out_packed[40])
    );
    mat2x2_mult m41 (
        .A_in(A_in_packed[41]),
        .B_in(B_in_packed[41]),
        .C_out(C_out_packed[41])
    );
    mat2x2_mult m42 (
        .A_in(A_in_packed[42]),
        .B_in(B_in_packed[42]),
        .C_out(C_out_packed[42])
    );
    mat2x2_mult m43 (
        .A_in(A_in_packed[43]),
        .B_in(B_in_packed[43]),
        .C_out(C_out_packed[43])
    );
    mat2x2_mult m44 (
        .A_in(A_in_packed[44]),
        .B_in(B_in_packed[44]),
        .C_out(C_out_packed[44])
    );
    mat2x2_mult m45 (
        .A_in(A_in_packed[45]),
        .B_in(B_in_packed[45]),
        .C_out(C_out_packed[45])
    );
    mat2x2_mult m46 (
        .A_in(A_in_packed[46]),
        .B_in(B_in_packed[46]),
        .C_out(C_out_packed[46])
    );
    mat2x2_mult m47 (
        .A_in(A_in_packed[47]),
        .B_in(B_in_packed[47]),
        .C_out(C_out_packed[47])
    );
    mat2x2_mult m48 (
        .A_in(A_in_packed[48]),
        .B_in(B_in_packed[48]),
        .C_out(C_out_packed[48])
    );
    mat2x2_mult m49 (
        .A_in(A_in_packed[49]),
        .B_in(B_in_packed[49]),
        .C_out(C_out_packed[49])
    );
    mat2x2_mult m50 (
        .A_in(A_in_packed[50]),
        .B_in(B_in_packed[50]),
        .C_out(C_out_packed[50])
    );
    mat2x2_mult m51 (
        .A_in(A_in_packed[51]),
        .B_in(B_in_packed[51]),
        .C_out(C_out_packed[51])
    );
    mat2x2_mult m52 (
        .A_in(A_in_packed[52]),
        .B_in(B_in_packed[52]),
        .C_out(C_out_packed[52])
    );
    mat2x2_mult m53 (
        .A_in(A_in_packed[53]),
        .B_in(B_in_packed[53]),
        .C_out(C_out_packed[53])
    );
    mat2x2_mult m54 (
        .A_in(A_in_packed[54]),
        .B_in(B_in_packed[54]),
        .C_out(C_out_packed[54])
    );
    mat2x2_mult m55 (
        .A_in(A_in_packed[55]),
        .B_in(B_in_packed[55]),
        .C_out(C_out_packed[55])
    );
    mat2x2_mult m56 (
        .A_in(A_in_packed[56]),
        .B_in(B_in_packed[56]),
        .C_out(C_out_packed[56])
    );
    mat2x2_mult m57 (
        .A_in(A_in_packed[57]),
        .B_in(B_in_packed[57]),
        .C_out(C_out_packed[57])
    );
    mat2x2_mult m58 (
        .A_in(A_in_packed[58]),
        .B_in(B_in_packed[58]),
        .C_out(C_out_packed[58])
    );
    mat2x2_mult m59 (
        .A_in(A_in_packed[59]),
        .B_in(B_in_packed[59]),
        .C_out(C_out_packed[59])
    );
    mat2x2_mult m60 (
        .A_in(A_in_packed[60]),
        .B_in(B_in_packed[60]),
        .C_out(C_out_packed[60])
    );
    mat2x2_mult m61 (
        .A_in(A_in_packed[61]),
        .B_in(B_in_packed[61]),
        .C_out(C_out_packed[61])
    );
    mat2x2_mult m62 (
        .A_in(A_in_packed[62]),
        .B_in(B_in_packed[62]),
        .C_out(C_out_packed[62])
    );
    mat2x2_mult m63 (
        .A_in(A_in_packed[63]),
        .B_in(B_in_packed[63]),
        .C_out(C_out_packed[63])
    );    
endmodule
