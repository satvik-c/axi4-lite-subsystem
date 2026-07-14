module uart_wrapper
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // UART Control Interface
    input  logic                    tx_en,
    input  logic                    rx_en,
    output logic                    tx_ready,
    output logic                    tx_empty,
    input  logic [7:0]              tx_data,
    input  logic                    tx_push,
    output logic [7:0]              rx_data,
    output logic                    rx_valid,
    output logic                    rx_perr,

    // Configuration
    input  logic [15:0]             baud_div,
    input  logic                    parity_en,
    input  logic                    parity_mode,
    input  logic                    stop_bits,

    // Physical Interface
    output logic                    tx_out,
    input  logic                    rx_in
);

    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FIFO Interface Signals
    logic       wr_en;
    logic [7:0] wr_data;
    logic       rd_en;
    logic [7:0] rd_data;
    logic       full;
    logic       empty;

    // Transmitter Interface Signals
    logic tx_start;
    logic tx_busy;

    // Receiver Interface Signals
    logic rx_valid_internal;
    logic rx_perr_internal;


    // ========================================================
    // FIFO INSTANTIATION
    // ========================================================

    // Instantiate transmit FIFO queue
    uart_fifo fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .full    (full),
        .empty   (empty)
    );


    // ========================================================
    // TRANSMITTER INSTANTIATION
    // ========================================================

    // Instantiate UART transmitter
    uart_tx tx (
        .clk         (clk),
        .rst_n       (rst_n),
        .tx_start    (tx_start),
        .tx_data     (rd_data),
        .baud_div    (baud_div),
        .parity_en   (parity_en),
        .parity_mode (parity_mode),
        .stop_bits   (stop_bits),
        .tx_busy     (tx_busy),
        .tx_out      (tx_out)
    );


    // ========================================================
    // RECEIVER INSTANTIATION
    // ========================================================

    // Instantiate UART receiver
    uart_rx rx (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx_en       (rx_en),
        .baud_div    (baud_div),
        .parity_en   (parity_en),
        .parity_mode (parity_mode),
        .stop_bits   (stop_bits),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid_internal),
        .rx_error    (),
        .rx_perr     (rx_perr_internal),
        .rx_in       (rx_in)
    );


    // ========================================================
    // DATAPATH ASSIGNMENTS
    // ========================================================

    // Assign FIFO writes and status outputs
    assign wr_en    = tx_push;
    assign wr_data  = tx_data;
    assign tx_ready = !full;
    assign tx_empty = empty && !tx_busy;
    assign rx_valid = rx_valid_internal && rx_en;
    assign rx_perr  = rx_perr_internal && rx_en;


    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [1:0] {
        IDLE,
        START,
        WAIT
    } tx_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS (FSM)
    // ========================================================

    // FSM States
    tx_state_t current_state;
    tx_state_t next_state;


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state transition
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // Next-state and control outputs combinational logic
    always_comb begin
        rd_en      = 1'b0;
        tx_start   = 1'b0;
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (tx_en && !empty && !tx_busy) begin
                    rd_en      = 1'b1;
                    next_state = START;
                end
            end

            START: begin
                tx_start   = 1'b1;
                next_state = WAIT;
            end

            WAIT: begin
                if (!tx_busy) begin
                    if (tx_en && !empty) begin
                        rd_en      = 1'b1;
                        next_state = START;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
