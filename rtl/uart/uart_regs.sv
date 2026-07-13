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
    output logic                    uart_tx_en,
    output logic                    uart_rx_en,
    input  logic                    uart_tx_ready,
    input  logic                    uart_tx_empty,
    output logic [7:0]              uart_tx_data,
    output logic                    uart_tx_push,
    input  logic [7:0]              uart_rx_data,
    input  logic                    uart_rx_valid,
    input  logic                    uart_rx_perr,
    output logic [15:0]             uart_baud_div,
    output logic                    uart_parity_en,
    output logic                    uart_parity_mode,
    output logic                    uart_stop_bits
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
            uart_tx_en       <= 1'b0;
            uart_rx_en       <= 1'b0;
            uart_tx_data     <= '0;
            uart_tx_push     <= 1'b0;
            uart_baud_div    <= '0;
            uart_parity_en   <= 1'b0;
            uart_parity_mode <= 1'b0;
            uart_stop_bits   <= 1'b0;
        end else begin
            uart_tx_push <= 1'b0;
            if (wr_commit) begin
                case (wr_addr)
                    UART_CTRL: begin
                        if (wstrb[0]) begin
                            uart_tx_en <= wdata[UART_CTRL_TXEN];
                            uart_rx_en <= wdata[UART_CTRL_RXEN];
                        end
                    end

                    UART_TXDATA: begin
                        if (wstrb[0]) begin
                            uart_tx_data <= wdata[7:0];
                            uart_tx_push <= 1'b1;
                        end
                    end

                    UART_CFG: begin
                        if (wstrb[0]) begin
                            uart_baud_div[7:0] <= wdata[UART_CFG_BAUDDIV_LSB +: 8];
                        end
                        if (wstrb[1]) begin
                            uart_baud_div[15:8] <= wdata[UART_CFG_BAUDDIV_MSB -: 8];
                        end
                        if (wstrb[2]) begin
                            uart_parity_en   <= wdata[UART_CFG_PARITYEN];
                            uart_parity_mode <= wdata[UART_CFG_PARITYMODE];
                            uart_stop_bits   <= wdata[UART_CFG_STOPBITS];
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
            UART_CTRL:   rdata = {30'b0, uart_rx_en, uart_tx_en};
            UART_STATUS: rdata = {27'b0, rx_perr_reg, rx_overrun_reg, rx_valid_reg, uart_tx_empty, uart_tx_ready};
            UART_TXDATA: rdata = {24'b0, uart_tx_data};
            UART_RXDATA: rdata = {24'b0, rx_data_reg};
            UART_CFG:    rdata = {13'b0, uart_stop_bits, uart_parity_mode, uart_parity_en, uart_baud_div};
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
            if (uart_rx_valid) begin
                rx_data_reg <= uart_rx_data;
            end

            if (uart_rx_valid) begin
                rx_valid_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_valid_reg <= 1'b0;
            end

            if (uart_rx_valid && rx_valid_reg && !(rd_commit && (rd_addr == UART_RXDATA))) begin
                rx_overrun_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_overrun_reg <= 1'b0;
            end

            if (uart_rx_perr) begin
                rx_perr_reg <= 1'b1;
            end else if (rd_commit && (rd_addr == UART_RXDATA)) begin
                rx_perr_reg <= 1'b0;
            end
        end
    end

endmodule
