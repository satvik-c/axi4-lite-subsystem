// ========================================================
// Bound assertions checking the skid buffer's full-state backpressure
// ========================================================

module skid_buffer_sva
(
    input logic       clk,
    input logic       rst_n,
    input logic       up_valid,
    input logic       up_ready,
    input logic       down_valid,
    input logic       down_ready,
    input logic [1:0] current_state
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    localparam FULL = 2'd2;

    // W1: READY is deasserted while the skid buffer is full
    W1: assert property (current_state == FULL |-> !up_ready);

    // W2: handshake signals only change on a state transition
    W2_up_ready:   assert property ($changed(up_ready) |-> $changed(current_state));
    W2_down_valid: assert property ($changed(down_valid) |-> $changed(current_state));

endmodule
