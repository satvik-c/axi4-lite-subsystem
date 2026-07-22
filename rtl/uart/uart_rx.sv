module uart_rx
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    // Internal localparams
    localparam DATA_BITS     = 8,
    localparam BIT_COUNTER_W = $clog2(DATA_BITS)
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Control
    input  logic                    rx_en,

    // UART Physical Interface
    input  logic                    rx_in,

    // Configuration
    input  logic [15:0]             baud_div,
    input  logic                    parity_en,
    input  logic                    parity_mode,  // 0 = even, 1 = odd
    input  logic                    stop_bits,    // 0 = one stop bit, 1 = two stop bits

    // Receive Interface
    output logic [7:0]              rx_data,
    output logic                    rx_valid,
    output logic                    rx_error,
    output logic                    rx_perr
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP,
        RECOVERY
    } uart_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    uart_state_t current_state;
    uart_state_t next_state;

    // Clock Enable & Tick
    logic        enable;
    logic        os_tick;
    logic [15:0] os_div;

    // Counters
    logic [3:0]               os_counter;
    logic [BIT_COUNTER_W-1:0] bit_counter;

    // Control Strobes
    logic clear_counters;
    logic inc_bit_counter;
    logic load_shift_rx_data;
    logic update_framing;
    logic update_parity;

    // Status & Handshake Signals
    logic data_done;
    logic stop_done;
    logic rx_parity_error;
    logic prev_rx_in;

    // Latched Configuration Registers
    logic [15:0] baud_div_reg;
    logic parity_en_reg;
    logic parity_mode_reg;
    logic stop_bits_reg;


    // ========================================================
    // DATAPATH ASSIGNMENTS
    // ========================================================

    assign data_done = (bit_counter == BIT_COUNTER_W'(DATA_BITS - 1));
    assign stop_done = (bit_counter == BIT_COUNTER_W'(stop_bits_reg));
    assign os_div    = baud_div_reg >> 4;


    // ========================================================
    // BAUD GENERATION
    // ========================================================

    // Instantiate baud generator for oversampling
    baud_gen gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .div(os_div),
        .baud_tick(os_tick)
    );


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state transition
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // Capture configuration parameters on transaction start
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            baud_div_reg    <= '0;
            parity_en_reg   <= 0;
            parity_mode_reg <= 0;
            stop_bits_reg   <= 0;
        end else if (current_state == IDLE && (!rx_in && prev_rx_in)) begin
            baud_div_reg    <= baud_div;
            parity_en_reg   <= parity_en;
            parity_mode_reg <= parity_mode;
            stop_bits_reg   <= stop_bits;
        end
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state = current_state;

        if (!rx_en) begin
            next_state = IDLE;
        end else begin
            case (current_state)
                IDLE: begin
                    if (!rx_in && prev_rx_in) next_state = START;
                end

                START: begin
                    if (os_tick && (os_counter == 4'd8)) begin
                        if (rx_in == 1'b0) next_state = DATA;
                        else               next_state = IDLE;
                    end
                end

                DATA: begin
                    if (os_tick && (os_counter == 4'd15) && data_done) begin
                        if (parity_en_reg) next_state = PARITY;
                        else           next_state = STOP;
                    end
                end

                PARITY: begin
                    if (os_tick && (os_counter == 4'd15)) next_state = STOP;
                end

                STOP: begin
                    if (os_tick && (os_counter == 4'd15) && stop_done) begin
                        if (rx_in && !rx_parity_error) next_state = IDLE;
                        else                           next_state = RECOVERY;
                    end
                end

                RECOVERY: begin
                    if (rx_in) next_state = IDLE;
                end

                default: next_state = current_state;
            endcase
        end
    end

    // Combinational output signals and control strobes
    always_comb begin
        enable             = rx_en;
        clear_counters     = 1'b0;
        inc_bit_counter    = 1'b0;
        load_shift_rx_data = 1'b0;
        update_framing     = 1'b0;
        update_parity      = 1'b0;

        case (current_state)
            IDLE:     ;
            START:    ;

            DATA: begin
                if (os_tick && (os_counter == 4'd15)) begin
                    load_shift_rx_data = 1'b1;
                    inc_bit_counter    = 1'b1;
                end
            end

            PARITY: begin
                if (os_tick && (os_counter == 4'd15)) begin
                    update_parity = 1'b1;
                end
            end

            STOP: begin
                if (os_tick && (os_counter == 4'd15)) begin
                    if (stop_done) update_framing = 1'b1;
                    inc_bit_counter = 1'b1;
                end
            end

            RECOVERY: begin
                enable = 1'b0;
            end

            default:  ;
        endcase

        if (current_state != next_state) clear_counters = 1'b1;
    end


    // ========================================================
    // DATAPATH AND FLAG UPDATES
    // ========================================================

    // Sequential register updates for datapath and status flags
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            os_counter      <= '0;
            bit_counter     <= '0;
            rx_data         <= '0;
            rx_valid        <= 1'b0;
            rx_error        <= 1'b0;
            rx_perr         <= 1'b0;
            rx_parity_error <= 1'b0;
            prev_rx_in      <= 1'b0;
        end else begin
            rx_valid   <= 1'b0;
            rx_error   <= 1'b0;
            rx_perr    <= 1'b0;
            prev_rx_in <= rx_in;

            // Update oversampling and bit counters
            if (clear_counters) begin
                os_counter  <= '0;
                bit_counter <= '0;
            end else begin
                if (os_tick)         os_counter  <= os_counter + 4'd1;
                if (inc_bit_counter) bit_counter <= bit_counter + 1'b1;
            end

            // Load received data into shift register
            if (load_shift_rx_data) begin
                rx_data <= {rx_in, rx_data[DATA_BITS-1:1]};
            end

            // Update parity calculation
            if (update_parity) begin
                if (!parity_mode_reg) rx_parity_error <= ^rx_data ^ rx_in;
                else                  rx_parity_error <= ~(^rx_data ^ rx_in);
            end

            // Update framing status and outputs
            if (update_framing) begin
                if ((rx_in == 1'b1) && (rx_parity_error == 1'b0)) rx_valid <= 1'b1;
                else                                              rx_error <= 1'b1;
                rx_perr         <= rx_parity_error;
                rx_parity_error <= 1'b0;
            end
        end
    end

endmodule
