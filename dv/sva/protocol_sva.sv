// ========================================================
// Bound assertions checking AXI4-Lite channel protocol compliance
// ========================================================

module protocol_sva
(
    axi4_lite_if vif
);

    default clocking cb @(posedge vif.ACLK); endclocking
    default disable iff (!vif.ARESETn);

    // B1: VALID holds until the corresponding READY handshake
    property valid_until_ready(valid, ready);
        (valid && !ready) |=> valid;
    endproperty

    B1_AW: assert property (valid_until_ready(vif.AWVALID, vif.AWREADY));
    B1_W:  assert property (valid_until_ready(vif.WVALID, vif.WREADY));
    B1_B:  assert property (valid_until_ready(vif.BVALID, vif.BREADY));
    B1_AR: assert property (valid_until_ready(vif.ARVALID, vif.ARREADY));
    B1_R:  assert property (valid_until_ready(vif.RVALID, vif.RREADY));

    // B2: payload stays stable while VALID is stalled
    property payload_stable(valid, ready, s1, s2);
        (valid && !ready) |=> ($stable(s1) && $stable(s2));
    endproperty

    B2_AW: assert property (payload_stable(vif.AWVALID, vif.AWREADY, vif.AWADDR, vif.AWPROT));
    B2_W:  assert property (payload_stable(vif.WVALID,  vif.WREADY,  vif.WDATA,  vif.WSTRB));
    B2_B:  assert property (payload_stable(vif.BVALID,  vif.BREADY,  vif.BRESP,  vif.BRESP));
    B2_AR: assert property (payload_stable(vif.ARVALID, vif.ARREADY, vif.ARADDR, vif.ARPROT));
    B2_R:  assert property (payload_stable(vif.RVALID,  vif.RREADY,  vif.RDATA,  vif.RRESP));

    // B3: VALID is low out of reset
    property reset_valid_low(valid);
        disable iff (0)
        (!vif.ARESETn || $rose(vif.ARESETn)) |-> !valid;
    endproperty

    B3_AW: assert property (reset_valid_low(vif.AWVALID));
    B3_W:  assert property (reset_valid_low(vif.WVALID));
    B3_B:  assert property (reset_valid_low(vif.BVALID));
    B3_AR: assert property (reset_valid_low(vif.ARVALID));
    B3_R:  assert property (reset_valid_low(vif.RVALID));

    // B4: no X on ready/payload while VALID is asserted
    property no_x_when_valid(valid, ready, s1, s2);
        valid |-> (!$isunknown(ready) && !$isunknown(s1) && !$isunknown(s2));
    endproperty

    B4_AW: assert property (no_x_when_valid(vif.AWVALID, vif.AWREADY, vif.AWADDR, vif.AWPROT));
    B4_W:  assert property (no_x_when_valid(vif.WVALID,  vif.WREADY,  vif.WDATA,  vif.WSTRB));
    B4_B:  assert property (no_x_when_valid(vif.BVALID,  vif.BREADY,  vif.BRESP,  vif.BRESP));
    B4_AR: assert property (no_x_when_valid(vif.ARVALID, vif.ARREADY, vif.ARADDR, vif.ARPROT));
    B4_R:  assert property (no_x_when_valid(vif.RVALID,  vif.RREADY,  vif.RDATA,  vif.RRESP));

    // B5: response never signals the reserved EXOKAY encoding
    B5_BRESP: assert property (vif.BRESP !== 2'b01);
    B5_RRESP: assert property (vif.RRESP !== 2'b01);

    // B6: write address/data accepted at most once per outstanding transaction
    logic aw_captured, w_captured;
    always_ff @(posedge vif.ACLK) begin
        if (!vif.ARESETn) begin
            aw_captured <= 1'b0;
            w_captured  <= 1'b0;
        end else if (vif.BVALID && vif.BREADY) begin
            aw_captured <= 1'b0;
            w_captured  <= 1'b0;
        end else begin
            if (vif.AWVALID && vif.AWREADY) aw_captured <= 1'b1;
            if (vif.WVALID  && vif.WREADY)  w_captured  <= 1'b1;
        end
    end

    B6_AW: assert property (aw_captured |-> !(vif.AWVALID && vif.AWREADY));
    B6_W:  assert property (w_captured  |-> !(vif.WVALID  && vif.WREADY));

    // B7: read address accepted at most once per outstanding transaction
    logic ar_captured;
    always_ff @(posedge vif.ACLK) begin
        if (!vif.ARESETn)
            ar_captured <= 1'b0;
        else if (vif.RVALID && vif.RREADY)
            ar_captured <= 1'b0;
        else if (vif.ARVALID && vif.ARREADY)
            ar_captured <= 1'b1;
    end

    B7_AR: assert property (ar_captured |-> !(vif.ARVALID && vif.ARREADY));

    // B8: write response follows address+data acceptance within 1-3 cycles
    wire aw_done = aw_captured || (vif.AWVALID && vif.AWREADY);
    wire w_done = w_captured || (vif.WVALID && vif.WREADY);

    B8: assert property ($rose(aw_done && w_done) |-> ##[1:3] vif.BVALID);

    // B9: read response follows address acceptance within 1-3 cycles
    wire ar_done = ar_captured || (vif.ARVALID && vif.ARREADY);

    B9: assert property ($rose(ar_done) |-> ##[1:3] vif.RVALID);

endmodule
