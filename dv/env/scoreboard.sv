class scoreboard;

    mailbox #(axi_txn) mon2scb;
    mailbox mon2scb_rst;

    mailbox #(spi_txn) spi2scb;

    mailbox #(i2c_txn) i2c2scb;

    axi_reg_model reg_model;
    int count, errors;

    function new(mailbox #(axi_txn) mon2scb, mailbox mon2scb_rst, mailbox #(spi_txn) spi2scb, mailbox #(i2c_txn) i2c2scb);
        this.mon2scb = mon2scb;
        this.mon2scb_rst = mon2scb_rst;
        this.spi2scb = spi2scb;
        this.i2c2scb = i2c2scb;
        reg_model = new();
        count = 0;
        errors = 0;
    endfunction

    task run();
        fork
            forever begin
                axi_txn mon_txn;
                logic [1:0] exp_resp;
                mon2scb.get(mon_txn);

                if (mon_txn.is_write) begin
                    exp_resp = reg_model.write(mon_txn.addr, mon_txn.wdata, mon_txn.wstrb);
                    if (mon_txn.resp !== exp_resp) begin
                        $error("[write] addr=0x%0h: expected resp=%0d, got %0d", mon_txn.addr, exp_resp, mon_txn.resp);
                        errors++;
                    end
                end else begin
                    logic [31:0] exp_rdata;
                    exp_resp = reg_model.read(mon_txn.addr, exp_rdata);
                    if (mon_txn.resp !== exp_resp || (!$isunknown(exp_rdata) && (mon_txn.rdata !== exp_rdata))) begin
                        $error("[read] addr=0x%0h: expected resp=%0d rdata=0x%0h, got resp=%0d rdata=0x%0h",
                            mon_txn.addr, exp_resp, exp_rdata, mon_txn.resp, mon_txn.rdata);
                        errors++;
                    end
                end

                count++;
            end

            forever begin
                spi_txn txn_spi;
                spi2scb.get(txn_spi);

                if (txn_spi.mosi_sampled !== txn_spi.mosi_expected) begin
                    $error("[spi] MOSI mismatch: expected=0x%0h, got=0x%0h", txn_spi.mosi_expected, txn_spi.mosi_sampled);
                    errors++;
                end

                count++;
            end

            forever begin
                i2c_txn txn_i2c;
                i2c2scb.get(txn_i2c);

                if (txn_i2c.addr_sampled !== txn_i2c.addr_expected) begin
                    $error("[i2c] address mismatch: expected=0x%0h, got=0x%0h", txn_i2c.addr_expected, txn_i2c.addr_sampled);
                    errors++;
                end
                if (txn_i2c.rw_n_sampled !== txn_i2c.rw_n_expected) begin
                    $error("[i2c] direction mismatch: expected=%0d, got=%0d", txn_i2c.rw_n_expected, txn_i2c.rw_n_sampled);
                    errors++;
                end
                if (!txn_i2c.rw_n_sampled && txn_i2c.txdata_sampled !== txn_i2c.txdata_expected) begin
                    $error("[i2c] TXDATA mismatch: expected=0x%0h, got=0x%0h", txn_i2c.txdata_expected, txn_i2c.txdata_sampled);
                    errors++;
                end

                count++;
            end

            forever begin
                bit dummy;
                mon2scb_rst.get(dummy);
                reg_model.reset();
            end
        join
    endtask

endclass
