`timescale 1ns / 1ps

module tb_systolic_16x16_mult_matrix_flattened;
    parameter WIDTH = 16;
    parameter MATRIX_SIZE = 16;

    logic clk, rst, start;
    logic [WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] A_flat, B_flat;
    logic [2*WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] C_flat;
    logic done;

    integer i, j;

    // DUT instantiation
    systolic_16x16_mult_matrix_flattened #(.WIDTH(WIDTH), .MATRIX_SIZE(MATRIX_SIZE)) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A_flat(A_flat),
        .B_flat(B_flat),
        .C_flat(C_flat),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Helper task to display a matrix from a packed vector
    task display_matrix(input logic [WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] mat, input string name);
        integer i, j;
        $display("%s:", name);
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            $write("  ");
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                $write("%0d ", mat[WIDTH*(MATRIX_SIZE*i+j) +: WIDTH]);
            end
            $write("\n");
        end
    endtask

    // Helper task to display 32-bit output matrix
    task display_matrix32(input logic [2*WIDTH*MATRIX_SIZE*MATRIX_SIZE-1:0] mat, input string name);
        integer i, j;
        $display("%s:", name);
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            $write("  ");
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                $write("%0d ", mat[2*WIDTH*(MATRIX_SIZE*i+j) +: 2*WIDTH]);
            end
            $write("\n");
        end
    endtask

    // Display signals and matrices on every positive clock edge
    always @(posedge clk) begin
        $display("TB Time %0t | rst=%b start=%b done=%b", $time, rst, start, done);
        display_matrix(A_flat, "TB Matrix A");
        display_matrix(B_flat, "TB Matrix B");
        display_matrix32(C_flat, "TB Matrix C");
        $display("-----------------------------------------------------");
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        #10;
        rst = 0;

        // Initialize inputs (A = i+j, B = identity matrix)
        for (i = 0; i < MATRIX_SIZE; i = i + 1)
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                A_flat[WIDTH*(MATRIX_SIZE*i+j) +: WIDTH] = i + j;
                B_flat[WIDTH*(MATRIX_SIZE*i+j) +: WIDTH] = (i == j) ? 16'd1 : 16'd0;
            end

        #10;
        start = 1;
        #10;
        // start = 0;
        #150 // Wait a while for computation (adjust as needed)

        // Wait for done signal
        //#wait (done == 1);
        #10;

        $display("Result matrix C:");
        display_matrix32(C_flat, "C");

        $finish;
    end
endmodule
