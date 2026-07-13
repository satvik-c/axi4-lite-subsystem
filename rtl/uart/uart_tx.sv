module uart_tx (
    input logic clk,
    input logic rst_n,
    input logic tx_start,
    input logic [7:0] tx_data,
    input logic [15:0] baud_div,
    input logic parity_en,
    input logic parity_mode,  // 0 = even, 1 = odd
    input logic stop_bits,    // 0 = one stop bit, 1 = two stop bits
    output logic tx_busy,
    output logic tx_out
);

    localparam DATA_BITS = 8;
    localparam CNT_W = $clog2(DATA_BITS);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP
    } uart_state_t;

// ====================== COUNTER/FLAGS =========================================== //

    logic [CNT_W-1:0] counter;

    logic data_done;
    assign data_done = (counter == CNT_W'(DATA_BITS - 1));

    logic stop_done;
    assign stop_done = (counter == CNT_W'(stop_bits));

// ================================================================================ //
    logic baud_tick, enable;
    logic [DATA_BITS-1:0] shift_register;
    logic parity_bit;

    logic load_data, shift_data;
    logic clear_counter, inc_counter;
    logic calculate_parity;

    baud_gen gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .div(baud_div),
        .baud_tick(baud_tick)
    );

// ========================= FSM =================================== //

    uart_state_t CS, NS;

    always_ff @(posedge clk) begin
        if (!rst_n) CS <= IDLE;
        else CS <= NS;
    end

    always_comb begin
        NS = CS;
        case (CS)
            IDLE: if (tx_start) NS = START;
            START: if (baud_tick) NS = DATA;
            DATA: if (baud_tick && data_done) begin
                if (parity_en) NS = PARITY;
                else NS = STOP;
            end
            PARITY: if (baud_tick) NS = STOP;
            STOP: if (baud_tick && stop_done) NS = IDLE;
            default: NS = CS;
        endcase
    end

    always_comb begin
        tx_busy = 1;
        enable = 1;
        tx_out = 1;

        load_data = 0;
        shift_data = 0;
        clear_counter = 0;
        inc_counter = 0;
        calculate_parity = 0;

        case (CS)
            IDLE: begin
                tx_busy = tx_start;
                enable = 0;
                tx_out = 1;
                if (tx_start) begin
                    load_data = 1; // DATAPATH
                    calculate_parity = 1; // DATAPATH
                end
            end
            START: begin
                tx_out = 0;
            end
            DATA: begin
                tx_out = shift_register[0];
                if (baud_tick) begin
                    inc_counter = 1; // DATAPATH
                    shift_data = 1; // DATAPATH
                end
            end
            PARITY: begin
                tx_out = parity_bit;
            end
            STOP: begin
                tx_out = 1;
                if (baud_tick) inc_counter = 1; // DATAPATH
            end
            default: tx_out = 1;
        endcase

        if (CS != NS) clear_counter = 1; // DATAPATH
    end

// ======================= DATAPATH ============================== //

    always_ff @(posedge clk) begin
        if (!rst_n || clear_counter) counter <= '0;
        else if (inc_counter) counter <= counter + 1;
        if (load_data) shift_register <= tx_data;
        else if (shift_data) shift_register <= shift_register >> 1;
        if (calculate_parity) begin
            if (!parity_mode) parity_bit <= ^tx_data;
            else parity_bit <= ~^tx_data;
        end
    end

endmodule
