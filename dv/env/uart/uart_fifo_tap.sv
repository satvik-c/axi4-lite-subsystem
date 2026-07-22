// ========================================================
// Taps the DUT's FIFO port activity and replays it into the FIFO reference model
// ========================================================

module uart_fifo_tap
(
    input logic       clk,
    input logic       rst_n,
    input logic       wr_en,
    input logic [7:0] wr_data,
    input logic       rd_en,
    input logic [7:0] rd_data,
    input logic       full,
    input logic       empty
);

    // Replay accepted FIFO port activity into the transmit queue model
    always_ff @(posedge clk) begin
        if (rst_n) begin
            if (wr_en && (!full || rd_en)) uart_fifo_model::push(wr_data, rd_en);
            else if (wr_en && full && !rd_en) uart_fifo_model::drop();
            if (rd_en && (!empty || wr_en)) uart_fifo_model::pop(wr_en);
        end
    end

endmodule
