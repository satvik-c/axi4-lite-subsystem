// ========================================================
// Captures one sampled UART transmit frame: data, parity, and framing config
// ========================================================

class uart_tx_txn;

    // Sampled TX byte, parity, and the frame config observed on the wire
    logic [7:0] data_sampled;
    logic       parity_sampled;
    logic       parity_en;
    logic       parity_mode;
    logic       stop_bits;

endclass
