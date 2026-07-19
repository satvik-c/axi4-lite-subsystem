class i2c_slave;

    virtual i2c_if.slave vif;
    axi_reg_model reg_model;

    mailbox #(i2c_txn) test2i2c;
    mailbox #(i2c_txn) i2c2scb;
    mailbox #(i2c_txn) i2c2cov;

    function new (
        virtual i2c_if.slave vif,
        axi_reg_model reg_model,
        mailbox #(i2c_txn) test2i2c,
        mailbox #(i2c_txn) i2c2scb,
        mailbox #(i2c_txn) i2c2cov
        );
        this.vif = vif;
        this.reg_model = reg_model;
        this.test2i2c = test2i2c;
        this.i2c2scb = i2c2scb;
        this.i2c2cov = i2c2cov;
    endfunction
    
    task run();
        forever begin
            i2c_txn txn;

            test2i2c.get(txn);

            @(negedge vif.sda iff vif.scl == 1);
            txn.addr_expected = reg_model.i2c_addr;
            txn.rw_n_expected = reg_model.i2c_rw_n;
            txn.txdata_expected = reg_model.i2c_txdata;

            vif.sda_oe = 0;
            
            for (int i = 6; i >= 0; i--) begin // addr (7 bits)
                @(posedge vif.scl);
                txn.addr_sampled[i] = vif.sda;
            end

            @(posedge vif.scl); // rw_n (1 bit)
            txn.rw_n_sampled = vif.sda;

            @(negedge vif.scl); // address ack/nack (1 bit)
            if (txn.nack) vif.sda_oe = 0;
            else vif.sda_oe = 1;

            @(negedge vif.scl); // end of ack/nack, slave write starts now
            vif.sda_oe = 0;

            if (!txn.nack) begin // jump to stop if slave nack'ed
                if (!txn.rw_n_sampled) begin // master writes (slave reads sda)
                    for (int i = 7; i >= 0; i--) begin
                        @(posedge vif.scl);
                        txn.txdata_sampled[i] = vif.sda;
                    end
                end else begin // master reads (slave writes sda)
                    vif.sda_oe = txn.rxdata[7] ? 0 : 1;
                    for (int i = 6; i >= 0; i--) begin
                        @(negedge vif.scl);
                        vif.sda_oe = txn.rxdata[i] ? 0 : 1;
                    end
                end

                @(negedge vif.scl); // data ack/nack (1 bit)
                if (!txn.rw_n_sampled) begin
                    if (txn.nack) vif.sda_oe = 0;
                    else vif.sda_oe = 1;
                end else begin
                    vif.sda_oe = 0;
                end
            end

            @(posedge vif.sda iff vif.scl == 1);
            vif.sda_oe = 0;
            i2c2scb.put(txn);
            i2c2cov.put(txn);            
        end
    endtask

endclass
