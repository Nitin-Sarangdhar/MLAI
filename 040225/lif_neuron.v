module lif_neuron #(
  parameter MEMBRANE_THRESHOLD = 8,
  parameter MEMBRANE_DECAY = 1,
  parameter MEMBRANE_POTENTIAL_WIDTH = 8
) (
  input clk,
  input reset,
  input [MEMBRANE_POTENTIAL_WIDTH-1:0] synaptic_input,
  output reg spike_output
);

  reg [MEMBRANE_POTENTIAL_WIDTH-1:0] membrane_potential;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      membrane_potential <= 0;
      spike_output <= 0;
    end else begin
      // Leaky integration
      if (membrane_potential >= MEMBRANE_DECAY) begin
        membrane_potential <= membrane_potential + synaptic_input - MEMBRANE_DECAY;
      end else begin
        membrane_potential <= membrane_potential + synaptic_input;
      end

      // Spike generation and reset
      if (membrane_potential >= MEMBRANE_THRESHOLD) begin
        spike_output <= 1;
        membrane_potential <= 0; // Reset after spike
      end else begin
        spike_output <= 0;
      end
    end
  end

endmodule
