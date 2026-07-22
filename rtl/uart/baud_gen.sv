// ========================================================
// Free-running baud-rate tick generator shared by the UART transmitter and receiver
// ========================================================

module baud_gen
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Controls
    input  logic                    enable,
    input  logic [15:0]             div,

    // Outputs
    output logic                    baud_tick
);


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // Baud Generation Counter
    logic [15:0] baud_counter;
    logic [15:0] safe_div;


    // ========================================================
    // BAUD GENERATION LOGIC
    // ========================================================

    // Clamp a zero divisor to avoid underflow below
    assign safe_div = (div == 16'd0) ? 16'd1 : div;

    // Generate baud tick when counter reaches divisor
    assign baud_tick = (baud_counter >= (safe_div - 16'd1));

    // Baud rate counter update
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            baud_counter <= '0;
        end else begin
            if (baud_tick || !enable) baud_counter <= '0;
            else                      baud_counter <= baud_counter + 1'b1;
        end
    end

endmodule
