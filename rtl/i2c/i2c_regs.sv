module i2c_regs
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

    // I2C Control Interface
    output logic                    i2c_en,
    output logic                    i2c_start,
    output logic                    i2c_rw_n,
    input  logic                    i2c_busy,
    input  logic                    i2c_rxvalid,
    input  logic                    i2c_nack,
    output logic [6:0]              i2c_addr,
    output logic [7:0]              i2c_txdata,
    input  logic [7:0]              i2c_rxdata,
    output logic [15:0]             i2c_clkdiv
);

    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // Internal Status Registers
    logic       rx_valid_reg;
    logic [7:0] rx_data_reg;
    logic       nack_reg;


    // ========================================================
    // DECODE LOGIC
    // ========================================================

    // Decode write and read address errors
    always_comb begin
        slverr   = (wr_addr == I2C_STATUS) || (wr_addr == I2C_RXDATA);
        wr_dcerr = !(wr_addr inside {I2C_CTRL, I2C_STATUS, I2C_ADDR, I2C_TXDATA, I2C_RXDATA, I2C_CFG});
        rd_dcerr = !(rd_addr inside {I2C_CTRL, I2C_STATUS, I2C_ADDR, I2C_TXDATA, I2C_RXDATA, I2C_CFG});
    end


    // ========================================================
    // REGISTER WRITE PATH
    // ========================================================

    // Register write operations
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            i2c_en     <= 1'b0;
            i2c_start  <= 1'b0;
            i2c_rw_n   <= 1'b0;
            i2c_addr   <= '0;
            i2c_txdata <= '0;
            i2c_clkdiv <= '0;
        end else begin
            if (wr_commit && (wr_addr == I2C_CTRL) && wstrb[0] && wdata[I2C_CTRL_START]) begin
                i2c_start <= 1'b1;
            end else begin
                i2c_start <= 1'b0;
            end

            if (wr_commit) begin
                case (wr_addr)
                    I2C_CTRL: begin
                        if (wstrb[0]) begin
                            i2c_en   <= wdata[I2C_CTRL_EN];
                            i2c_rw_n <= wdata[I2C_CTRL_RW_N];
                        end
                    end

                    I2C_ADDR: begin
                        if (wstrb[0]) begin
                            i2c_addr <= wdata[I2C_ADDR_MSB:I2C_ADDR_LSB];
                        end
                    end

                    I2C_TXDATA: begin
                        if (wstrb[0]) begin
                            i2c_txdata <= wdata[7:0];
                        end
                    end

                    I2C_CFG: begin
                        if (wstrb[0]) begin
                            i2c_clkdiv[7:0] <= wdata[I2C_CFG_CLKDIV_LSB +: 8];
                        end
                        if (wstrb[1]) begin
                            i2c_clkdiv[15:8] <= wdata[I2C_CFG_CLKDIV_MSB -: 8];
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
            I2C_CTRL:   rdata = {29'b0, i2c_rw_n, 1'b0, i2c_en};
            I2C_STATUS: rdata = {29'b0, nack_reg, rx_valid_reg, i2c_busy};
            I2C_ADDR:   rdata = {25'b0, i2c_addr};
            I2C_TXDATA: rdata = {24'b0, i2c_txdata};
            I2C_RXDATA: rdata = {24'b0, rx_data_reg};
            I2C_CFG:    rdata = {16'b0, i2c_clkdiv};
            default:    rdata = 32'b0;
        endcase
    end


    // ========================================================
    // INTERNAL REGISTERS UPDATES
    // ========================================================

    // Hardware updates for status and receive registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_valid_reg <= 1'b0;
            rx_data_reg  <= '0;
            nack_reg     <= 1'b0;
        end else begin
            if (i2c_rxvalid) begin
                rx_valid_reg <= 1'b1;
                rx_data_reg  <= i2c_rxdata;
            end else if (rd_commit && (rd_addr == I2C_RXDATA)) begin
                rx_valid_reg <= 1'b0;
            end

            if (i2c_nack)       nack_reg <= 1'b1;
            else if (i2c_start) nack_reg <= 1'b0;
        end
    end

endmodule
