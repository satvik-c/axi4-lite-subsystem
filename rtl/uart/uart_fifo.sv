module uart_fifo
#(
    parameter DEPTH = 16,
    localparam ADDR_W = $clog2(DEPTH)
)(
    input logic clk,
    input logic rst_n,

    input logic wr_en,
    input logic [7:0] wr_data,
    input logic rd_en,
    output logic [7:0] rd_data,
    output logic full,
    output logic empty
);

    logic [7:0] fifo [DEPTH];

    logic [ADDR_W:0] wr_ptr;
    logic [ADDR_W:0] wr_ptr_next;
    logic wr_valid;
    logic [ADDR_W:0] rd_ptr;
    logic [ADDR_W:0] rd_ptr_next;
    logic rd_valid;
    logic full_next;
    logic empty_next;

    assign wr_valid = wr_en && (!full || rd_en);
    assign rd_valid = rd_en && (!empty || wr_en);

    assign wr_ptr_next = wr_ptr + wr_valid;
    assign rd_ptr_next = rd_ptr + rd_valid;
    assign full_next = (wr_ptr_next == {~rd_ptr_next[ADDR_W], rd_ptr_next[ADDR_W-1:0]});
    assign empty_next = (rd_ptr_next == wr_ptr_next);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            full <= 0;
            empty <= 1;
        end
        else begin
            if (wr_valid) fifo[wr_ptr[ADDR_W-1:0]] <= wr_data;
            if (rd_valid) rd_data <= (empty) ? wr_data : fifo[rd_ptr[ADDR_W-1:0]];
            wr_ptr <= wr_ptr_next;
            rd_ptr <= rd_ptr_next;
            full <= full_next;
            empty <= empty_next;
        end
    end

`ifdef FORMAL

// W3 [assert] The UART transmit queue's pointer-derived occupancy remains within [0, 16].
// W4 [assert] The queue flags map correctly to occupancy (empty ⇔ occupancy == 0, full ⇔ occupancy == 16).
// W5 [assert] The queue does not overflow, except a write is accepted while full if a pop occurs the same cycle, leaving occupancy unchanged.
// W6 [assert] The queue does not underflow, except a pop is accepted while empty if a push occurs the same cycle, forwarding the pushed byte directly.
// W8 [assert] The queue's read output changes only on an accepted pop.

    initial assume(!rst_n);

    logic [ADDR_W:0] occupancy;
    assign occupancy = wr_ptr - rd_ptr;

    always_ff @(posedge clk) begin
        if (rst_n) assert (occupancy >= 0 && occupancy <= DEPTH);
    end

    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n)) begin
            if (full) assert (occupancy == DEPTH);
            if (empty) assert (occupancy == 0);
            if ($past(wr_en && rd_en && full)) assert ($past(occupancy) == occupancy);
            if ($past(rd_en && wr_en && empty)) assert ($past(occupancy) == occupancy && rd_data == $past(wr_data));
            if ($past(rd_data) !== rd_data) assert ($past(rd_valid));
        end
    end

    always_ff @(posedge clk) begin
        cover (full);
        cover (empty);
        cover (full && wr_en);
        cover (empty && rd_en);
    end

`endif

endmodule
