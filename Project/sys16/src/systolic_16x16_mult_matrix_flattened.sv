`timescale 1ns / 1ps
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


module systolic_16x16_mult_matrix_flattened #(
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



    reg [2:0] state;
    integer i, j, k, tile_row, tile_col, row_base, col_base, row_base_A, row_base_B, col_base_A, col_base_B;
    integer abs_row, abs_col, out_idx, packed_idx, pass_j;
    // Helper macro for bit slicing
    `define SLICE(vec, idx) vec[(idx)*WIDTH +: WIDTH]
    `define SLICE32(vec, idx) vec[(idx)*2*WIDTH +: 2*WIDTH]

    // Display block (optional, can be removed for synthesis)
    always @(posedge clk) begin
        $display("----- Multipliers inputs and outputs at time %0t (state %0d) (pass_j %0d)-----", $time, state, pass_j);

        for (int k = 0; k < 64; k++) begin
            $display("m%0d A_in: [%0d %0d; %0d %0d]",
                k, 
                A_in_packed[k][0*WIDTH +: WIDTH],  // A11
                A_in_packed[k][1*WIDTH +: WIDTH],  // A12
                A_in_packed[k][2*WIDTH +: WIDTH],  // A21
                A_in_packed[k][3*WIDTH +: WIDTH]   // A22
            );
            $display("m%0d B_in: [%0d %0d; %0d %0d]",
                k, 
                B_in_packed[k][0*WIDTH +: WIDTH],  // B11
                B_in_packed[k][1*WIDTH +: WIDTH],  // B12
                B_in_packed[k][2*WIDTH +: WIDTH],  // B21
                B_in_packed[k][3*WIDTH +: WIDTH]   // B22
            );
            $display("m%0d C_out: [%0d %0d; %0d %0d]",
                k, 
                C_out_packed[k][0*2*WIDTH +: 2*WIDTH],  // C11
                C_out_packed[k][1*2*WIDTH +: 2*WIDTH],  // C12
                C_out_packed[k][2*2*WIDTH +: 2*WIDTH],  // C21
                C_out_packed[k][3*2*WIDTH +: 2*WIDTH]   // C22
            );
            
        end

    end
    // Main state machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            C_flat <= '0;
            pass_j <= 0;
        end else begin
            case (state)
            // State 0: Load multiplier inputs for pass_j
                3'd0: begin
                    if (start) begin
                        for (tile_row = 0; tile_row < 8; tile_row = tile_row + 1) begin
                            for (tile_col = 0; tile_col < 8; tile_col = tile_col + 1) begin
                                k = tile_row * 8 + tile_col;

                                // A block for this pass: (tile_row, pass_j)
                                row_base_A = tile_row * 2;
                                col_base_A = pass_j * 2;

                                // B block for this pass: (pass_j, tile_col)
                                row_base_B = pass_j * 2;
                                col_base_B = tile_col * 2;

                                // Pack A_in
                                A_in_packed[k] <= {
                                    `SLICE(A_flat, 16*(row_base_A+1)+(col_base_A+1)),
                                    `SLICE(A_flat, 16*(row_base_A+1)+(col_base_A  )),
                                    `SLICE(A_flat, 16*(row_base_A  )+(col_base_A+1)),
                                    `SLICE(A_flat, 16*(row_base_A  )+(col_base_A  ))
                                };
                                // Pack B_in
                                B_in_packed[k] <= {
                                    `SLICE(B_flat, 16*(row_base_B+1)+(col_base_B+1)),
                                    `SLICE(B_flat, 16*(row_base_B+1)+(col_base_B  )),
                                    `SLICE(B_flat, 16*(row_base_B  )+(col_base_B+1)),
                                    `SLICE(B_flat, 16*(row_base_B  )+(col_base_B  ))
                                };
                            end
                        end
                        state <= 3'd1;
                        done <= 1'b0;
                    end
                end

                // State 1: Accumulate multiplier outputs for pass_j
                3'd1: begin
                    for (tile_row = 0; tile_row < 8; tile_row = tile_row + 1) begin
                        for (tile_col = 0; tile_col < 8; tile_col = tile_col + 1) begin
                            k = tile_row * 8 + tile_col;
                            for (i = 0; i < 2; i = i + 1) begin
                                for (j = 0; j < 2; j = j + 1) begin
                                    abs_row = 2*tile_row + i;
                                    abs_col = 2*tile_col + j;
                                    out_idx = 16*abs_row + abs_col;
                                    packed_idx = 2*i + j;
                                    // Accumulate
                                    C_flat[(out_idx)*2*WIDTH +: 2*WIDTH] <=
                                        C_flat[(out_idx)*2*WIDTH +: 2*WIDTH] +
                                        C_out_packed[k][packed_idx*2*WIDTH +: 2*WIDTH];
                                end
                            end
                        end
                    end
                    // Next pass or done
                    if (pass_j == 7) begin
                        state <= 3'd2;
                    end else begin
                        pass_j <= pass_j + 1;
                        state <= 3'd0;
                    end
                end

                // State 2: Done
                3'd2: begin
                    done <= 1'b1;
                    state <= 3'd2;
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
