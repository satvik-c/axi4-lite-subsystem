// ========================================================
// Mirrors live UART config registers into a static class for the RX/TX BFMs to read
// ========================================================

class uart_dut_state;
    static logic [15:0] baud_div;
    static logic        parity_en;
    static logic        parity_mode;
    static logic        stop_bits;
endclass

module uart_regs_tap
(
    input logic [15:0] uart_baud_div,
    input logic        uart_parity_en,
    input logic        uart_parity_mode,
    input logic        uart_stop_bits
);

    always_comb begin
        uart_dut_state::baud_div    = uart_baud_div;
        uart_dut_state::parity_en   = uart_parity_en;
        uart_dut_state::parity_mode = uart_parity_mode;
        uart_dut_state::stop_bits   = uart_stop_bits;
    end

endmodule
