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


module sys4 #(
    parameter WIDTH = 16,  // reduced WIDTH from 16 to 8
    parameter MATRIX_SIZE = 16 // 4x4 matrix flattened to 16 elements
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             start,
    input  logic [WIDTH*MATRIX_SIZE-1:0] A_flat, // packed vector: {A[15],...,A[0]}
    input  logic [WIDTH*MATRIX_SIZE-1:0] B_flat, // packed vector: {B[15],...,B[0]}
    output logic [WIDTH*MATRIX_SIZE-1:0] C_flat, // packed vector: {C[15],...,C[0]}
    output logic            done
);

    // Internal input registers to mat2x2_mult units
    logic [4*WIDTH-1:0] A_in0_packed, B_in0_packed;
    logic [4*WIDTH-1:0] A_in1_packed, B_in1_packed;
    logic [4*WIDTH-1:0] A_in2_packed, B_in2_packed;
    logic [4*WIDTH-1:0] A_in3_packed, B_in3_packed;

    wire [127:0] C_out00_packed, C_out01_packed, C_out10_packed, C_out11_packed;

    reg [2:0] state;
    integer i, j;

    // Helper macro for bit slicing
    `define SLICE(vec, idx) vec[(idx)*WIDTH +: WIDTH]

    // Display block (optional, can be removed for synthesis)

    // Main state machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            C_flat <= '0;
        end else begin
            case (state)
                3'd0: begin
                    if (start) begin
                        // Top-left tile of A and B
                        A_in0_packed <= {`SLICE(A_flat,5), `SLICE(A_flat,4), `SLICE(A_flat,1), `SLICE(A_flat,0)};
                        B_in0_packed <= {`SLICE(B_flat,5), `SLICE(B_flat,4), `SLICE(B_flat,1), `SLICE(B_flat,0)};
                        // Top-left tile of A, top-right of B
                        A_in1_packed <= {`SLICE(A_flat,5), `SLICE(A_flat,4), `SLICE(A_flat,1), `SLICE(A_flat,0)};
                        B_in1_packed <= {`SLICE(B_flat,7), `SLICE(B_flat,6), `SLICE(B_flat,3), `SLICE(B_flat,2)};
                        // Bottom-left tile of A, top-left of B
                        A_in2_packed <= {`SLICE(A_flat,13), `SLICE(A_flat,12), `SLICE(A_flat,9), `SLICE(A_flat,8)};
                        B_in2_packed <= {`SLICE(B_flat,5), `SLICE(B_flat,4), `SLICE(B_flat,1), `SLICE(B_flat,0)};
                        // Bottom-left tile of A, top-right of B
                        A_in3_packed <= {`SLICE(A_flat,13), `SLICE(A_flat,12), `SLICE(A_flat,9), `SLICE(A_flat,8)};
                        B_in3_packed <= {`SLICE(B_flat,7), `SLICE(B_flat,6), `SLICE(B_flat,3), `SLICE(B_flat,2)};
                        state <= 3'd1;
                        done <= 1'b0;
                    end
                end



                3'd1: begin
                    // Write outputs from multipliers to C_flat
                    for (i = 0; i < 2; i = i + 1) begin
                        for (j = 0; j < 2; j = j + 1) begin
                            // Top-left
                            C_flat[(4*i+j)*WIDTH +: WIDTH] <= C_out00_packed[(2*i+j)*2*WIDTH +: WIDTH];
                            // Top-right
                            C_flat[(4*i+j+2)*WIDTH +: WIDTH] <= C_out01_packed[(2*i+j)*2*WIDTH +: WIDTH];
                            // Bottom-left
                            C_flat[(4*(i+2)+j)*WIDTH +: WIDTH] <= C_out10_packed[(2*i+j)*2*WIDTH +: WIDTH];
                            // Bottom-right
                            C_flat[(4*(i+2)+j+2)*WIDTH +: WIDTH] <= C_out11_packed[(2*i+j)*2*WIDTH +: WIDTH];
                        end
                    end

                    done <= 1'b0;
                    state <= 3'd2;
                end

                3'd2: begin
                    // Next set of tiles
                    A_in0_packed <= {`SLICE(A_flat,7), `SLICE(A_flat,6), `SLICE(A_flat,3), `SLICE(A_flat,2)};
                    B_in0_packed <= {`SLICE(B_flat,13), `SLICE(B_flat,12), `SLICE(B_flat,9), `SLICE(B_flat,8)};
                    A_in1_packed <= {`SLICE(A_flat,7), `SLICE(A_flat,6), `SLICE(A_flat,3), `SLICE(A_flat,2)};
                    B_in1_packed <= {`SLICE(B_flat,15), `SLICE(B_flat,14), `SLICE(B_flat,11), `SLICE(B_flat,10)};
                    A_in2_packed <= {`SLICE(A_flat,15), `SLICE(A_flat,14), `SLICE(A_flat,11), `SLICE(A_flat,10)};
                    B_in2_packed <= {`SLICE(B_flat,13), `SLICE(B_flat,12), `SLICE(B_flat,9), `SLICE(B_flat,8)};
                    A_in3_packed <= {`SLICE(A_flat,15), `SLICE(A_flat,14), `SLICE(A_flat,11), `SLICE(A_flat,10)};
                    B_in3_packed <= {`SLICE(B_flat,15), `SLICE(B_flat,14), `SLICE(B_flat,11), `SLICE(B_flat,10)};
                    done <= 1'b0;
                    state <= 3'd3;
                end

                3'd3: begin
                    // Add results to C_flat (accumulate)
                    for (i = 0; i < 2; i = i + 1) begin
                        for (j = 0; j < 2; j = j + 1) begin
                            // Top-left
                            C_flat[(4*i+j)*WIDTH +: WIDTH] <= C_out00_packed[(2*i+j)*2*WIDTH +: WIDTH] + C_flat[(4*i+j)*WIDTH +: WIDTH];
                            // Top-right
                            C_flat[(4*i+j+2)*WIDTH +: WIDTH] <= C_out01_packed[(2*i+j)*2*WIDTH +: WIDTH] + C_flat[(4*i+j+2)*WIDTH +: WIDTH];
                            // Bottom-left
                            C_flat[(4*(i+2)+j)*WIDTH +: WIDTH] <= C_out10_packed[(2*i+j)*2*WIDTH +: WIDTH] + C_flat[(4*(i+2)+j)*WIDTH +: WIDTH];
                            // Bottom-right
                            C_flat[(4*(i+2)+j+2)*WIDTH +: WIDTH] <= C_out11_packed[(2*i+j)*2*WIDTH +: WIDTH] + C_flat[(4*(i+2)+j+2)*WIDTH +: WIDTH];
                        end
                    end
                    done <= 1'b0;
                    state <= 3'd4;
                end

                3'd4: begin
                    done <= 1'b1;
                    state <= 3'd0;
                end
                default: begin
		    done <= 1'b1;
		    state <= 3'd0;
		end
	endcase
        end
    end

    // Undefine macro if used
    `undef SLICE

    // Instantiate 4 mat2x2 multipliers
    mat2x2_mult m0 (
        .A_in(A_in0_packed),
        .B_in(B_in0_packed),
        .C_out(C_out00_packed)
    );

    mat2x2_mult m1 (
        .A_in(A_in1_packed),
        .B_in(B_in1_packed),
        .C_out(C_out01_packed)
    );

    mat2x2_mult m2 (
        .A_in(A_in2_packed),
        .B_in(B_in2_packed),
        .C_out(C_out10_packed)
    );

    mat2x2_mult m3 (
        .A_in(A_in3_packed),
        .B_in(B_in3_packed),
        .C_out(C_out11_packed)
    );

endmodule
