module i2c_master
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                        clk,
    input  logic                        rst_n,

    // Runtime Configuration
    input  logic [15:0]                 clk_div,

    // Control Interface
    input  logic                        en,
    input  logic                        start,
    input  logic [6:0]                  addr,
    input  logic                        rw_n,
    input  logic [7:0]                  tx_data,
    output logic                        busy,
    output logic                        valid,
    output logic                        nack,
    output logic [7:0]                  rx_data,
    output logic                        rx_valid,

    // I2C Physical Interface
    output logic                        scl,
    inout  wire                         sda
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [2:0] {
        IDLE,
        START,
        ADDR,
        ADDR_ACK,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    i2c_state_t CS;
    i2c_state_t NS;

    // SDA Tri-State
    logic sda_oe;
    logic sda_in;

    // Tick Generator
    logic [15:0] tick_gen;
    logic [15:0] clk_div_reg;
    logic        tick;
    logic        tick_gen_en;

    // Tick Counter
    logic [1:0] tick_counter;

    // Datapath Registers
    logic [7:0] shift_reg;
    logic [2:0] bit_counter;
    logic       ack;

    // Transaction Configuration
    logic [6:0] addr_reg;
    logic [7:0] data_reg;
    logic       rw_n_reg;

    // Control & Status Wires
    logic load_addr;
    logic load_data;
    logic shift;
    logic clear_bit_counter;
    logic inc_bit_counter;
    logic sample_ack;
    logic sample_data;
    logic byte_done;
    logic bit_done;

    // FSM Control Signals
    logic scl_en;
    logic scl_comb;
    logic sda_oe_comb;


    // ========================================================
    // SDA TRI-STATE
    // ========================================================

    assign sda    = sda_oe ? 1'b0 : 1'bz;
    assign sda_in = sda;


    // ========================================================
    // TICK GENERATOR
    // ========================================================

    // Generate timing ticks based on configuration clock divider
    always_ff @(posedge clk) begin
        if (!rst_n || !tick_gen_en) begin
            tick_gen <= '0;
            tick     <= 1'b0;
        end else begin
            if (tick_gen == clk_div_reg - 16'd1) begin
                tick_gen <= '0;
                tick     <= 1'b1;
            end else begin
                tick_gen <= tick_gen + 16'd1;
                tick     <= 1'b0;
            end
        end
    end


    // ========================================================
    // TICK COUNTER
    // ========================================================

    // Count tick phases for sub-bit SCL clock cycle control
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tick_counter <= '0;
        end else if (tick) begin
            if (tick_counter == 2'd3) begin
                tick_counter <= '0;
            end else begin
                tick_counter <= tick_counter + 2'd1;
            end
        end
    end


    // ========================================================
    // DATAPATH
    // ========================================================

    assign rx_data   = shift_reg;
    assign nack      = !ack;
    assign byte_done = (tick_counter == 2'd3 && tick && bit_counter == 3'd7);
    assign bit_done  = (tick_counter == 2'd3 && tick);

    // Shift data and sample internal status on transaction bits
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            shift_reg   <= '0;
            bit_counter <= '0;
            ack         <= 1'b0;
        end else begin
            if (load_addr)         shift_reg   <= {addr_reg, rw_n_reg};
            if (load_data)         shift_reg   <= data_reg;
            if (shift)             shift_reg   <= shift_reg << 1;
            if (clear_bit_counter) bit_counter <= '0;
            if (inc_bit_counter)   bit_counter <= bit_counter + 3'd1;
            if (sample_ack)        ack         <= (sda_in == 1'b0);
            if (sample_data)       shift_reg   <= {shift_reg[6:0], sda_in};
        end
    end


    // ========================================================
    // FSM
    // ========================================================

    // Sequential state register for the state machine
    always_ff @(posedge clk) begin
        if (!rst_n) CS <= IDLE;
        else        CS <= NS;
    end

    // Capture configuration parameters on start trigger
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            clk_div_reg <= 16'd1;
            addr_reg    <= '0;
            rw_n_reg    <= 1'b0;
            data_reg    <= '0;
        end else if (CS == IDLE && start && en) begin
            clk_div_reg <= (clk_div == 16'd0) ? 16'd1 : clk_div;
            addr_reg    <= addr;
            rw_n_reg    <= rw_n;
            data_reg    <= tx_data;
        end
    end

    // Next-state transition combinational logic
    always_comb begin
        NS = CS;
        case (CS)
            IDLE:     if (start && en) NS = START;
            START:    if (bit_done)    NS = ADDR;
            ADDR:     if (byte_done)   NS = ADDR_ACK;
            ADDR_ACK: begin
                if (bit_done) begin
                    if (ack) NS = DATA;
                    else     NS = STOP;
                end
            end
            DATA:     if (byte_done)   NS = DATA_ACK;
            DATA_ACK: if (bit_done)    NS = STOP;
            STOP:     if (bit_done)    NS = IDLE;
            default:                   NS = STOP;
        endcase
    end

    // Control output generation combinational logic
    always_comb begin
        busy              = 1'b1;
        valid             = 1'b0;
        tick_gen_en       = 1'b1;
        scl_en            = 1'b0;
        sda_oe_comb       = 1'b0;
        load_addr         = 1'b0;
        load_data         = 1'b0;
        shift             = 1'b0;
        clear_bit_counter = 1'b0;
        inc_bit_counter   = 1'b0;
        sample_ack        = 1'b0;
        sample_data       = 1'b0;
        rx_valid          = 1'b0;

        case (CS)
            IDLE: begin
                sda_oe_comb = 1'b0;
                busy        = 1'b0;
                tick_gen_en = 1'b0;
                scl_en      = 1'b0;
            end
            START: begin
                sda_oe_comb       = 1'b1;
                scl_en            = 1'b0;
                clear_bit_counter = 1'b1;
                if (bit_done) load_addr = 1'b1;
            end
            ADDR: begin
                sda_oe_comb = !shift_reg[7];
                scl_en      = 1'b1;
                if (bit_done) begin
                    shift           = 1'b1;
                    inc_bit_counter = 1'b1;
                end
            end
            ADDR_ACK: begin
                sda_oe_comb       = 1'b0;
                scl_en            = 1'b1;
                clear_bit_counter = 1'b1;
                if (tick_counter == 2'd2 && tick) sample_ack = 1'b1;
                if (bit_done) begin
                    if (!rw_n_reg) load_data = 1'b1;
                end
            end
            DATA: begin
                sda_oe_comb = rw_n_reg ? 1'b0 : !shift_reg[7];
                scl_en      = 1'b1;
                if (rw_n_reg && tick_counter == 2'd2 && tick) sample_data = 1'b1;
                if (bit_done) begin
                    if (!rw_n_reg) shift = 1'b1;
                    inc_bit_counter = 1'b1;
                end
                if (byte_done && rw_n_reg) rx_valid = 1'b1;
            end
            DATA_ACK: begin
                sda_oe_comb       = 1'b0;
                scl_en            = 1'b1;
                clear_bit_counter = 1'b1;
                if (!rw_n_reg && tick_counter == 2'd2 && tick) sample_ack = 1'b1;
            end
            STOP: begin
                sda_oe_comb = 1'b1;
                scl_en      = 1'b1;
                if (tick_counter == 2'd2 && tick) scl_en = 1'b0;
                if (bit_done) valid = 1'b1;
            end
            default: ;
        endcase

        scl_comb = !scl_en ? 1'b1 : tick_counter[1];
    end

    // Sequential registers driving the physical outputs
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            scl    <= 1'b1;
            sda_oe <= 1'b0;
        end else begin
            scl    <= scl_comb;
            sda_oe <= sda_oe_comb;
        end
    end

endmodule
