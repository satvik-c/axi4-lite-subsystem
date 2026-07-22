// ========================================================
// Register offset enums and bit-index localparams for SPI, I2C, and UART
// ========================================================

package regs_pkg;

    typedef enum logic [5:0] {
        SPI_CTRL   = 6'h00, // 0x00
        SPI_STATUS = 6'h01, // 0x04
        SPI_TXDATA = 6'h02, // 0x08
        SPI_RXDATA = 6'h03, // 0x0C
        SPI_CFG    = 6'h04  // 0x10
    } spi_offset_t;

    localparam int SPI_CTRL_EN    = 0;
    localparam int SPI_CTRL_START = 1;

    localparam int SPI_STATUS_BUSY    = 0;
    localparam int SPI_STATUS_RXVALID = 1;

    localparam int SPI_CFG_CPOL       = 0;
    localparam int SPI_CFG_CPHA       = 1;
    localparam int SPI_CFG_CLKDIV_LSB = 16;
    localparam int SPI_CFG_CLKDIV_MSB = 31;


    typedef enum logic [5:0] {
        I2C_CTRL   = 6'h00, // 0x00
        I2C_STATUS = 6'h01, // 0x04
        I2C_ADDR   = 6'h02, // 0x08
        I2C_TXDATA = 6'h03, // 0x0C
        I2C_RXDATA = 6'h04, // 0x10
        I2C_CFG    = 6'h05  // 0x14
    } i2c_offset_t;

    localparam int I2C_CTRL_EN    = 0;
    localparam int I2C_CTRL_START = 1;
    localparam int I2C_CTRL_RW_N  = 2;

    localparam int I2C_STATUS_BUSY    = 0;
    localparam int I2C_STATUS_RXVALID = 1;
    localparam int I2C_STATUS_NACK    = 2;

    localparam int I2C_ADDR_LSB = 0;
    localparam int I2C_ADDR_MSB = 6;

    localparam int I2C_CFG_CLKDIV_LSB = 0;
    localparam int I2C_CFG_CLKDIV_MSB = 15;


    typedef enum logic [5:0] {
        UART_CTRL   = 6'h00, // 0x00
        UART_STATUS = 6'h01, // 0x04
        UART_TXDATA = 6'h02, // 0x08
        UART_RXDATA = 6'h03, // 0x0C
        UART_CFG    = 6'h04  // 0x10
    } uart_offset_t;

    localparam int UART_CTRL_TXEN = 0;
    localparam int UART_CTRL_RXEN = 1;

    localparam int UART_STATUS_TXREADY   = 0;
    localparam int UART_STATUS_TXEMPTY   = 1;
    localparam int UART_STATUS_RXVALID   = 2;
    localparam int UART_STATUS_RXOVERRUN = 3;
    localparam int UART_STATUS_RXPERR    = 4;

    localparam int UART_CFG_BAUDDIV_LSB = 0;
    localparam int UART_CFG_BAUDDIV_MSB = 15;
    localparam int UART_CFG_PARITYEN    = 16;
    localparam int UART_CFG_PARITYMODE  = 17;
    localparam int UART_CFG_STOPBITS    = 18;

endpackage
