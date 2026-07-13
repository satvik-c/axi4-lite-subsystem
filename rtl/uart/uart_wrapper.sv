module uart_wrapper
(
    input logic clk,
    input logic rst_n,

    input logic tx_en,
    input logic rx_en,
    output logic tx_ready,
    output logic tx_empty,
    input logic [7:0] tx_data,
    input logic tx_push,
    output logic [7:0] rx_data,
    output logic rx_valid,
    output logic rx_perr,
    input logic [15:0] baud_div,
    input logic parity_en,
    input logic parity_mode,
    input logic stop_bits,
    output logic tx_out,
    input logic rx_in
);

    logic wr_en;
    logic [7:0] wr_data;
    logic rd_en;
    logic [7:0] rd_data;
    logic full;
    logic empty;

    uart_fifo #(
        .DEPTH(64)
    ) fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    logic tx_start;
    logic tx_busy;

    uart_tx tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(rd_data),
        .baud_div(baud_div),
        .parity_en(parity_en),
        .parity_mode(parity_mode),
        .stop_bits(stop_bits),
        .tx_busy(tx_busy),
        .tx_out(tx_out)
    );

    logic rx_valid_internal;
    logic rx_perr_internal;

    uart_rx rx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div),
        .parity_en(parity_en),
        .parity_mode(parity_mode),
        .stop_bits(stop_bits),
        .rx_data(rx_data),
        .rx_valid(rx_valid_internal),
        .rx_error(),
        .rx_perr(rx_perr_internal),
        .rx_in(rx_in)
    );

    assign wr_en = tx_push;
    assign wr_data = tx_data;

    assign tx_ready = !full;
    assign tx_empty = empty && !tx_busy;

    assign rx_valid = rx_valid_internal && rx_en;
    assign rx_perr = rx_perr_internal && rx_en;

    typedef enum logic [1:0] {
        IDLE,
        START,
        WAIT
    } tx_state_t;

    tx_state_t current_state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end

    always_comb begin
        rd_en = 0;
        tx_start = 0;
        next_state = current_state;
        case (current_state)
            IDLE: if (tx_en && !empty && !tx_busy) begin
                rd_en = 1;
                next_state = START;
            end
            START: begin
                tx_start = 1;
                next_state = WAIT;
            end
            WAIT: if (!tx_busy) begin
                if (tx_en && !empty) begin
                    rd_en = 1;
                    next_state = START;
                end
                else next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
