// Snapshot of live I2C config registers, published for the slave BFM to read
class i2c_dut_state;
    static logic [6:0] addr;
    static logic       rw_n;
    static logic [7:0] txdata;
endclass

module i2c_regs_tap
(
    input logic [6:0] i2c_addr,
    input logic       i2c_rw_n,
    input logic [7:0] i2c_txdata
);

    always_comb begin
        i2c_dut_state::addr   = i2c_addr;
        i2c_dut_state::rw_n   = i2c_rw_n;
        i2c_dut_state::txdata = i2c_txdata;
    end

endmodule
