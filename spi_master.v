module spi_master #(
    parameter SPI_MODE          = 0,
    parameter CLKS_PER_HALF_BIT = 2
)(
    input        i_Rst_L,
    input        i_Clk,

    // TX (MOSI)
    input  [7:0] i_TX_Byte,
    input        i_TX_DV,
    output       o_TX_Ready,

    // RX (MISO)
    output       o_RX_DV,
    output [7:0] o_RX_Byte,

    // SPI Interface
    output       o_SPI_Clk,
    output       o_SPI_MOSI,
    output       o_SPI_SS_L,
    input        i_SPI_MISO
);

    localparam IDLE     = 1'b0;
    localparam TRANSFER = 1'b1;

    wire w_CPOL = (SPI_MODE == 2) || (SPI_MODE == 3);
    wire w_CPHA = (SPI_MODE == 1) || (SPI_MODE == 3);

    reg        r_State;
    reg [4:0]  r_SPI_Clk_Count;
    reg [4:0]  r_SPI_Clk_Edges;
    reg        r_SPI_Clk;
    reg        r_Leading_Edge;
    reg        r_Trailing_Edge;

    reg [7:0]  r_TX_Byte;
    reg [3:0]  r_TX_Bit_Count;
    reg [3:0]  r_RX_Bit_Count;
    reg [7:0]  r_RX_Shift;

    reg        r_TX_Ready;
    reg        r_RX_DV;
    reg [7:0]  r_RX_Byte;
    reg        r_SPI_MOSI;
    reg        r_SPI_SS_L;

    assign o_TX_Ready = r_TX_Ready;
    assign o_RX_DV    = r_RX_DV;
    assign o_RX_Byte  = r_RX_Byte;
    assign o_SPI_Clk  = r_SPI_Clk;
    assign o_SPI_MOSI = r_SPI_MOSI;
    assign o_SPI_SS_L = r_SPI_SS_L;

    always @(posedge i_Clk or negedge i_Rst_L) begin
        if (!i_Rst_L) begin
            r_State         <= IDLE;
            r_SPI_Clk       <= w_CPOL;
            r_SPI_Clk_Count <= 0;
            r_SPI_Clk_Edges <= 0;
            r_Leading_Edge  <= 1'b0;
            r_Trailing_Edge <= 1'b0;
            r_TX_Ready      <= 1'b1;
            r_RX_DV         <= 1'b0;
            r_RX_Byte       <= 8'h00;
            r_SPI_MOSI      <= 1'b0;
            r_SPI_SS_L      <= 1'b1;
            r_TX_Bit_Count  <= 3'd7;
            r_RX_Bit_Count  <= 3'd7;
            r_RX_Shift      <= 8'h00;
        end else begin
            r_Leading_Edge  <= 1'b0;
            r_Trailing_Edge <= 1'b0;
            r_RX_DV         <= 1'b0;

            if (r_State == IDLE) begin
                r_SPI_Clk       <= w_CPOL;
                r_SPI_Clk_Count <= 0;
                r_SPI_Clk_Edges <= 0;
                r_SPI_SS_L      <= 1'b1;
                r_TX_Ready      <= 1'b1;
                if (i_TX_DV) begin
                    r_State         <= TRANSFER;
                    r_TX_Ready      <= 1'b0;
                    r_SPI_SS_L      <= 1'b0;
                    r_SPI_Clk_Edges <= 16;
                    r_SPI_Clk_Count <= 0;
                    r_TX_Byte       <= i_TX_Byte;
                    r_RX_Bit_Count  <= 3'd7;
                    if (!w_CPHA) begin
                        r_SPI_MOSI     <= i_TX_Byte[7];
                        r_TX_Bit_Count <= 3'd6;
                    end else begin
                        r_TX_Bit_Count <= 3'd7;
                    end
                end
            end else begin
                if (r_SPI_Clk_Edges > 0) begin
                    if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2 - 1) begin
                        r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                        r_Trailing_Edge <= 1'b1;
                        r_SPI_Clk_Count <= 0;
                        r_SPI_Clk       <= ~r_SPI_Clk;
                    end else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT - 1) begin
                        r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                        r_Leading_Edge  <= 1'b1;
                        r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
                        r_SPI_Clk       <= ~r_SPI_Clk;
                    end else begin
                        r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
                    end
                end

                if ((r_Leading_Edge && !w_CPHA) || (r_Trailing_Edge && w_CPHA)) begin
                    r_RX_Shift[r_RX_Bit_Count] <= i_SPI_MISO;
                    if (r_RX_Bit_Count == 0) begin
                        r_RX_Byte <= {r_RX_Shift[7:1], i_SPI_MISO};
                        r_RX_DV   <= 1'b1;
                    end
                    r_RX_Bit_Count <= r_RX_Bit_Count - 1;
                end

                if ((r_Leading_Edge && w_CPHA) || (r_Trailing_Edge && !w_CPHA)) begin
                    r_SPI_MOSI <= r_TX_Byte[r_TX_Bit_Count];
                    if (r_TX_Bit_Count != 0) begin
                        r_TX_Bit_Count <= r_TX_Bit_Count - 1;
                    end
                end

                if (r_SPI_Clk_Edges == 0) begin
                    r_State    <= IDLE;
                    r_SPI_SS_L <= 1'b1;
                    r_TX_Ready <= 1'b1;
                end
            end
        end
    end

endmodule