module uart_tx
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    // Internal localparams
    localparam DATA_BITS = 8,
    localparam CNT_W     = $clog2(DATA_BITS)
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Transmit Control Interface
    input  logic                    tx_start,
    input  logic [7:0]              tx_data,

    // Configuration
    input  logic [15:0]             baud_div,
    input  logic                    parity_en,
    input  logic                    parity_mode,  // 0 = even, 1 = odd
    input  logic                    stop_bits,    // 0 = one stop bit, 1 = two stop bits

    // Physical Output Interface
    output logic                    tx_busy,
    output logic                    tx_out
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP
    } uart_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    uart_state_t current_state;
    uart_state_t next_state;

    // Counters
    logic [CNT_W-1:0] counter;

    // Baud Tick Signals
    logic baud_tick;
    logic enable;

    // Shift Register and Parity
    logic [DATA_BITS-1:0] shift_register;
    logic                 parity_bit;

    // Control Strobes
    logic load_data;
    logic shift_data;
    logic clear_counter;
    logic inc_counter;
    logic calculate_parity;

    // Status Signals
    logic data_done;
    logic stop_done;


    // ========================================================
    // DATAPATH ASSIGNMENTS
    // ========================================================

    assign data_done = (counter == CNT_W'(DATA_BITS - 1));
    assign stop_done = (counter == CNT_W'(stop_bits));


    // ========================================================
    // BAUD GENERATION
    // ========================================================

    // Instantiate baud generator for tx timing
    baud_gen gen (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (enable),
        .div       (baud_div),
        .baud_tick (baud_tick)
    );


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state transition
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (tx_start) next_state = START;
            end

            START: begin
                if (baud_tick) next_state = DATA;
            end

            DATA: begin
                if (baud_tick && data_done) begin
                    if (parity_en) next_state = PARITY;
                    else           next_state = STOP;
                end
            end

            PARITY: begin
                if (baud_tick) next_state = STOP;
            end

            STOP: begin
                if (baud_tick && stop_done) next_state = IDLE;
            end

            default: next_state = current_state;
        endcase
    end

    // Combinational output signals and control strobes
    always_comb begin
        tx_busy          = 1'b1;
        enable           = 1'b1;
        tx_out           = 1'b1;
        load_data        = 1'b0;
        shift_data       = 1'b0;
        clear_counter    = 1'b0;
        inc_counter      = 1'b0;
        calculate_parity = 1'b0;

        case (current_state)
            IDLE: begin
                tx_busy = tx_start;
                enable  = 1'b0;
                tx_out  = 1'b1;
                if (tx_start) begin
                    load_data        = 1'b1;
                    calculate_parity = 1'b1;
                end
            end

            START: begin
                tx_out = 1'b0;
            end

            DATA: begin
                tx_out = shift_register[0];
                if (baud_tick) begin
                    inc_counter = 1'b1;
                    shift_data  = 1'b1;
                end
            end

            PARITY: begin
                tx_out = parity_bit;
            end

            STOP: begin
                tx_out = 1'b1;
                if (baud_tick) begin
                    inc_counter = 1'b1;
                end
            end

            default: begin
                tx_out = 1'b1;
            end
        endcase

        if (current_state != next_state) clear_counter = 1'b1;
    end


    // ========================================================
    // DATAPATH REGISTER UPDATES
    // ========================================================

    // Sequential datapath register updates
    always_ff @(posedge clk) begin
        if (!rst_n || clear_counter) counter <= '0;
        else if (inc_counter)        counter <= counter + 1'b1;

        if (load_data)       shift_register <= tx_data;
        else if (shift_data) shift_register <= shift_register >> 1;

        if (calculate_parity) begin
            if (!parity_mode) parity_bit <= ^tx_data;
            else              parity_bit <= ~^tx_data;
        end
    end

endmodule
