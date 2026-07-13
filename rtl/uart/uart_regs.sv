module uart_regs
    import regs_pkg::*;
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Write Interface
    input  logic                    wr_commit,
    input  logic [5:0]              wr_addr,
    input  logic [31:0]             wdata,
    input  logic [3:0]              wstrb,
    output logic                    slverr,
    output logic                    wr_dcerr,

    // Read Interface
    input  logic                    rd_commit,
    input  logic [5:0]              rd_addr,
    output logic [31:0]             rdata,
    output logic                    rd_dcerr,

    // UART Control Interface
    output logic                    tx_en,
    output logic                    rx_en,
    input  logic                    tx_ready,
    input  logic                    tx_empty,
    output logic [7:0]              tx_data,
    output logic                    tx_push,
    input  logic [7:0]              rx_data,
    input  logic                    rx_valid,
    input  logic                    rx_perr,
    output logic [15:0]             baud_div,
    output logic                    parity_en,
    output logic                    parity_mode,
    output logic                    stop_bits
);

    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // Internal Status Registers
    logic [7:0] rx_data_reg;
    logic       rx_valid_reg;
    logic       rx_overrun_reg;
    logic       rx_perr_reg;


    // ========================================================
    // DECODE LOGIC
    // ========================================================

    // Decode write and read address errors
    always_comb begin
        slverr   = (wr_addr == UART_STATUS) || (wr_addr == UART_RXDATA);
        wr_dcerr = !(wr_addr inside {UART_CTRL, UART_STATUS, UART_TXDATA, UART_RXDATA, UART_CFG});
        rd_dcerr = !(rd_addr inside {UART_CTRL, UART_STATUS, UART_TXDATA, UART_RXDATA, UART_CFG});
    end


    // ========================================================
    // REGISTER WRITE PATH
    // ========================================================

    // Register write operations
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_en       <= 1'b0;
            rx_en       <= 1'b0;
            tx_data     <= '0;
            tx_push     <= 1'b0;
            baud_div    <= '0;
            parity_en   <= 1'b0;
            parity_mode <= 1'b0;
            stop_bits   <= 1'b0;
        end else begin
            tx_push <= 1'b0;
            if (wr_commit) begin
                case (wr_addr)
                    UART_CTRL: begin
                        if (wstrb[0]) begin
                            tx_en <= wdata[UART_CTRL_TXEN];
                            rx_en <= wdata[UART_CTRL_RXEN];
                        end
                    end

                    UART_TXDATA: begin
                        if (wstrb[0]) begin
                            tx_data <= wdata[7:0];
                            tx_push <= 1'b1;
                        end
                    end

                    UART_CFG: begin
                        if (wstrb[0]) begin
                            baud_div[7:0] <= wdata[UART_CFG_BAUDDIV_LSB +: 8];
                        end
                        if (wstrb[1]) begin
                            baud_div[15:8] <= wdata[UART_CFG_BAUDDIV_MSB -: 8];
                        end
                        if (wstrb[2]) begin
                            parity_en   <= wdata[UART_CFG_PARITYEN];
                            parity_mode <= wdata[UART_CFG_PARITYMODE];
                            stop_bits   <= wdata[UART_CFG_STOPBITS];
                        end
                    end

                    default: ;
                endcase
            end
        end
    end


    // ========================================================
    // REGISTER READ PATH
    // ========================================================

    // Register read operations
    always_comb begin
        case (rd_addr)
            UART_CTRL:   rdata = {30'b0, rx_en, tx_en};
            UART_STATUS: rdata = {27'b0, rx_perr_reg, rx_overrun_reg, rx_valid_reg, tx_empty, tx_ready};
            UART_TXDATA: rdata = {24'b0, tx_data};
            UART_RXDATA: rdata = {24'b0, rx_data_reg};
            UART_CFG:    rdata = {13'b0, stop_bits, parity_mode, parity_en, baud_div};
            default:     rdata = 32'b0;
        endcase
    end


    // ========================================================
    // INTERNAL REGISTERS UPDATES
    // ========================================================

    // Hardware updates for status and receive registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_valid_reg   <= 1'b0;
            rx_overrun_reg <= 1'b0;
            rx_perr_reg    <= 1'b0;
            rx_data_reg    <= '0;
        end else begin
            if (rx_valid) begin
                rx_data_reg <= rx_data;
            end

            if (rx_valid) begin
                rx_valid_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_valid_reg <= 1'b0;
            end

            if (rx_valid && rx_valid_reg && !(rd_commit && (rd_addr == UART_RXDATA))) begin
                rx_overrun_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_overrun_reg <= 1'b0;
            end

            if (rx_perr) begin
                rx_perr_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_perr_reg <= 1'b0;
            end
        end
    end

endmodule
