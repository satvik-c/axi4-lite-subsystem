module uart_rx (
    input logic clk, rst_n, rx_in,
    input logic [15:0] baud_div,
    input logic parity_en,
    input logic parity_mode,  // 0 = even, 1 = odd
    input logic stop_bits,    // 0 = one stop bit, 1 = two stop bits
    output logic [7:0] rx_data,
    output logic rx_valid,
    output logic rx_error,
    output logic rx_perr
);

    localparam DATA_BITS = 8;
    localparam BIT_COUNTER_W = $clog2(DATA_BITS);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP,
        RECOVERY
    } uart_state_t;

    uart_state_t CS, NS;
    logic enable, os_tick;
    logic [3:0] os_counter; // 16x oversampling always
    logic [BIT_COUNTER_W-1:0] bit_counter;

    logic clear_counters, inc_bit_counter, load_shift_rx_data, update_framing, update_parity;

    logic data_done, stop_done;
    assign data_done = (bit_counter == DATA_BITS - 1);
    assign stop_done = (bit_counter == BIT_COUNTER_W'(stop_bits));

    logic rx_parity_error;
    logic prev_rx_in;

    logic [15:0] os_div;
    assign os_div = baud_div >> 4; // 16x oversampling

    baud_gen gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .div(os_div),
        .baud_tick(os_tick)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) CS <= IDLE;
        else CS <= NS;
    end

    always_comb begin
        NS = CS;
        case (CS)
            IDLE: if (!rx_in && prev_rx_in) NS = START;
            START: if (os_tick && os_counter == 8) begin
                if (rx_in == 0) NS = DATA;
                else NS = IDLE;
            end
            DATA: if (os_tick && os_counter == 15 && data_done) begin
                if (parity_en) NS = PARITY;
                else NS = STOP;
            end
            PARITY: if (os_tick && os_counter == 15) NS = STOP;
            STOP: if (os_tick && os_counter == 15 && stop_done) begin
                if (rx_in && !rx_parity_error) NS = IDLE;
                else NS = RECOVERY;
            end
            RECOVERY: if (rx_in) NS = IDLE;
            default: NS = CS;
        endcase
    end

    always_comb begin
        enable = 1;
        clear_counters = 0;
        inc_bit_counter = 0;
        load_shift_rx_data = 0;
        update_framing = 0;
        update_parity = 0;

        case (CS)
            IDLE: ;
            START: ;
            DATA: if (os_tick && os_counter == 15) begin
                    load_shift_rx_data = 1;
                    inc_bit_counter = 1;
            end
            PARITY: if (os_tick && os_counter == 15) begin
                update_parity = 1;
            end
            STOP: if (os_tick && os_counter == 15) begin
                if (stop_done) update_framing = 1;
                inc_bit_counter = 1;
            end
            RECOVERY: enable = 0;
            default: ;
        endcase

        if (CS != NS) clear_counters = 1; // clear both os_counter and bit_counter
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            os_counter <= '0;
            bit_counter <= '0;
            rx_data <= '0;
            rx_valid <= 0;
            rx_error <= 0;
            rx_perr <= 0;
            rx_parity_error <= 0;
            prev_rx_in <= 0;
        end
        else begin
            rx_valid <= 0;
            rx_error <= 0;
            rx_perr <= 0;
            prev_rx_in <= rx_in;
            // ========= COUNTERS ============= //

            if (clear_counters) begin
                os_counter <= '0;
                bit_counter <= '0;
            end
            else begin
                if (os_tick) os_counter <= os_counter + 1;
                if (inc_bit_counter) bit_counter <= bit_counter + 1;
            end

            // ========= SHIFT REGISTER ============= //

            if (load_shift_rx_data) begin
                rx_data <= {rx_in, rx_data[DATA_BITS-1:1]};
            end

            // ========= UPDATE FLAGS ============= //

            if (update_parity) begin
                if (!parity_mode) rx_parity_error <= ^rx_data ^ rx_in;
                else rx_parity_error <= ~(^rx_data ^ rx_in);
            end

            if (update_framing) begin
                if (rx_in == 1 && rx_parity_error == 0) rx_valid <= 1;
                else rx_error <= 1;
                rx_perr <= rx_parity_error;
                rx_parity_error <= 0;
            end
        end
    end

endmodule
