`timescale 1ns / 1ps

module lif_neuron_tb;

  // Parameters
  parameter MEMBRANE_THRESHOLD = 8;
  parameter MEMBRANE_DECAY = 1;
  parameter MEMBRANE_POTENTIAL_WIDTH = 8;

  // Inputs
  reg clk;
  reg reset;
  reg [MEMBRANE_POTENTIAL_WIDTH-1:0] synaptic_input;

  // Outputs
  wire spike_output;

  // Instantiate the LIF neuron module
  lif_neuron #(
    .MEMBRANE_THRESHOLD(MEMBRANE_THRESHOLD),
    .MEMBRANE_DECAY(MEMBRANE_DECAY),
    .MEMBRANE_POTENTIAL_WIDTH(MEMBRANE_POTENTIAL_WIDTH)
  ) uut (
    .clk(clk),
    .reset(reset),
    .synaptic_input(synaptic_input),
    .spike_output(spike_output)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  // Test stimulus
  initial begin
    reset = 1;
    synaptic_input = 0;
    #10;
    reset = 0;

    // Apply different synaptic inputs and observe the output
    #20; synaptic_input = 1; // Below threshold
    #20; synaptic_input = 3; //still below threshold
    #20; synaptic_input = 8; // At threshold, should spike
    #20; synaptic_input = 10; //Above threshold, should spike.
    #20; synaptic_input = 0; // decay only.
    #20; synaptic_input = 5; //add input to the decayed value.
    #20; synaptic_input = 8; //should spike again.
    #20; synaptic_input = 0; // decay only.

    #100; // End simulation
    $finish;
  end

  // Monitor outputs
  initial begin
    $monitor("Time=%0t, clk=%b, reset=%b, synaptic_input=%d, spike_output=%b, membrane_potential=%d",
             $time, clk, reset, synaptic_input, spike_output, uut.membrane_potential);
  end

endmodule