module spi_master
#(
    // ========================================================
    // PARAMETERS
    // ========================================================

    parameter DATA_WIDTH      = 8,
    parameter CS_SETUP_CYCLES = 0,
    parameter CS_HOLD_CYCLES  = 0,

    // Internal localparams
    localparam MAX_WAIT_CYCLES = (CS_SETUP_CYCLES > CS_HOLD_CYCLES) ? CS_SETUP_CYCLES : CS_HOLD_CYCLES,
    localparam WAIT_W          = (MAX_WAIT_CYCLES > 1) ? $clog2(MAX_WAIT_CYCLES) : 1
)(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                        clk,
    input  logic                        rst_n,

    // Runtime Configuration
    input  logic                        cpol,
    input  logic                        cpha,
    input  logic [15:0]                 clk_div,

    // Control Interface
    input  logic                        en,
    input  logic                        start,
    input  logic [DATA_WIDTH-1:0]       tx_data,
    output logic [DATA_WIDTH-1:0]       rx_data,
    output logic                        rx_valid,
    output logic                        busy,

    // SPI Physical Interface
    input  logic                        miso,
    output logic                        mosi,
    output logic                        sclk,
    output logic                        cs_n
);

    // ========================================================
    // FSM STATES TYPEDEF
    // ========================================================

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        SHIFT,
        HOLD
    } spi_state_t;


    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // FSM States
    spi_state_t current_state;
    spi_state_t next_state;

    // Captured Configuration Registers
    logic [15:0] reg_clk_div;
    logic        reg_cpol;
    logic        reg_cpha;

    // SCLK Generation
    logic [15:0] sclk_counter;
    logic        sclk_int;
    logic        sclk_en;
    logic        leading_strobe;
    logic        trailing_strobe;
    logic        drive_strobe;
    logic        sample_strobe;

    // Counters & Status
    logic [WAIT_W-1:0]             wait_counter;
    logic [$clog2(DATA_WIDTH)-1:0] bit_counter;
    logic                          setup_done;
    logic                          hold_done;
    logic                          word_done;

    // Datapath
    logic [DATA_WIDTH-1:0] tx_shift;
    logic [DATA_WIDTH-1:0] rx_shift;
    logic                  load_tx_shift;
    logic                  drive_bit;
    logic                  sample_bit;
    logic                  hold_msb;


    // ========================================================
    // CONFIGURATION CAPTURE
    // ========================================================

    // Capture configuration parameters on start trigger
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            reg_cpol    <= 1'b0;
            reg_cpha    <= 1'b0;
            reg_clk_div <= 16'd1;
        end else if (current_state == IDLE && start && en) begin
            reg_cpol    <= cpol;
            reg_cpha    <= cpha;
            reg_clk_div <= (clk_div == 16'd0) ? 16'd1 : clk_div;
        end
    end


    // ========================================================
    // CLOCK GENERATION & STROBES
    // ========================================================

    // Generate internal SCLK clock and counter
    always_ff @(posedge clk) begin
        if (!rst_n || !sclk_en) begin
            sclk_counter <= '0;
            sclk_int     <= 1'b0;
        end else if (sclk_counter == (reg_clk_div - 16'd1)) begin
            sclk_counter <= '0;
            sclk_int     <= ~sclk_int;
        end else begin
            sclk_counter <= sclk_counter + 1'b1;
        end
    end

    assign leading_strobe  = (sclk_en && sclk_counter == (reg_clk_div - 16'd1) && sclk_int == 1'b0);
    assign trailing_strobe = (sclk_en && sclk_counter == (reg_clk_div - 16'd1) && sclk_int == 1'b1);

    // Set drive and sample strobe signals depending on CPHA
    assign drive_strobe  = reg_cpha ? leading_strobe : trailing_strobe;
    assign sample_strobe = reg_cpha ? trailing_strobe : leading_strobe;


    // ========================================================
    // SETUP & HOLD WAIT COUNTER
    // ========================================================

    assign setup_done = (CS_SETUP_CYCLES == 0) ? 1'b1 : (wait_counter == CS_SETUP_CYCLES - 1);
    assign hold_done  = (CS_HOLD_CYCLES  == 0) ? 1'b1 : (wait_counter == CS_HOLD_CYCLES - 1);

    // Increment wait counter during setup and hold states
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wait_counter <= '0;
        end else if (current_state == SETUP || current_state == HOLD) begin
            wait_counter <= wait_counter + 1'b1;
        end else begin
            wait_counter <= '0;
        end
    end


    // ========================================================
    // FSM
    // ========================================================

    assign word_done = (trailing_strobe && bit_counter == $bits(bit_counter)'(DATA_WIDTH - 1));

    // Sequential state register for the FSM
    always_ff @(posedge clk) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // Next-state transition combinational logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:    if (start && en) next_state = SETUP;
            SETUP:   if (setup_done)  next_state = SHIFT;
            SHIFT:   if (word_done)   next_state = HOLD;
            HOLD:    if (hold_done)   next_state = IDLE;
            default:                  next_state = IDLE;
        endcase
    end

    // Output control signals combinational logic
    always_comb begin
        cs_n          = 1'b0;
        busy          = 1'b1;
        sclk_en       = 1'b0;
        load_tx_shift = 1'b0;
        drive_bit     = 1'b0;
        sample_bit    = 1'b0;

        case (current_state)
            IDLE: begin
                cs_n = 1'b1;
                busy = 1'b0;
                if (start && en) load_tx_shift = 1'b1;
            end
            SETUP: begin
                // Wait for setup phase completion
            end
            SHIFT: begin
                sclk_en = 1'b1;
                if (drive_strobe)       drive_bit  = 1'b1;
                else if (sample_strobe) sample_bit = 1'b1;
            end
            HOLD: begin
                // Wait for hold phase completion
            end
        endcase
    end


    // ========================================================
    // DATAPATH & PHYSICAL OUTPUTS
    // ========================================================

    assign sclk     = sclk_int ^ reg_cpol;
    assign mosi     = tx_shift[DATA_WIDTH-1];
    assign rx_data  = rx_shift;
    assign hold_msb = (reg_cpha == 1'b1 && bit_counter == '0);

    // Shift registers and bit counter updates
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bit_counter <= '0;
            tx_shift    <= '0;
            rx_shift    <= '0;
            rx_valid    <= 1'b0;
        end else begin
            rx_valid <= word_done ? 1'b1 : 1'b0;

            if (load_tx_shift) begin
                tx_shift <= tx_data;
            end else if (drive_bit && !hold_msb) begin
                tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
            end

            if (sample_bit) begin
                rx_shift <= {rx_shift[DATA_WIDTH-2:0], miso};
            end

            if (current_state == IDLE) begin
                bit_counter <= '0;
            end else if (trailing_strobe) begin
                if (bit_counter == $bits(bit_counter)'(DATA_WIDTH - 1)) begin
                    bit_counter <= '0;
                end else begin
                    bit_counter <= bit_counter + 1'b1;
                end
            end
        end
    end

endmodule
