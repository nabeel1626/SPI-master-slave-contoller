`timescale 1ns / 1ps

module spi_slave #(
    parameter SPI_MODE = 0
)(
    input        i_Rst_L,
    input        i_Clk,
    input        i_SPI_Clk,
    input        i_SPI_SS_L,
    input        i_SPI_MOSI,
    input  [7:0] i_TX_Byte,
    input        i_TX_DV,
    output       o_SPI_MISO,
    output       o_RX_DV,
    output [7:0] o_RX_Byte,
    output       o_TX_Ready
);

    wire w_CPOL = (SPI_MODE == 2) || (SPI_MODE == 3);
    wire w_CPHA = (SPI_MODE == 1) || (SPI_MODE == 3);

    reg [1:0] r_SPI_Clk_Sync;
    reg [1:0] r_SS_L_Sync;
    wire      w_SPI_Clk     = r_SPI_Clk_Sync[1];
    wire      w_SPI_Clk_Pre = r_SPI_Clk_Sync[0];
    wire      w_SS_L        = r_SS_L_Sync[1];
    wire      w_SS_L_Pre    = r_SS_L_Sync[0];
    wire      w_SS_Active   = (w_SS_L == 1'b0);
    wire      w_Leading_Edge  = (w_SPI_Clk_Pre == w_CPOL) && (w_SPI_Clk == ~w_CPOL);
    wire      w_Trailing_Edge = (w_SPI_Clk_Pre == ~w_CPOL) && (w_SPI_Clk == w_CPOL);

    reg signed [3:0] r_TX_Bit_Count;
    reg signed [3:0] r_RX_Bit_Count;
    reg [7:0]        r_TX_Shift;
    reg [7:0]        r_RX_Shift;
    reg              r_TX_Ready;
    reg              r_RX_DV;
    reg [7:0]        r_RX_Byte;
    reg              r_SPI_MISO;

    assign o_TX_Ready = r_TX_Ready;
    assign o_RX_DV    = r_RX_DV;
    assign o_RX_Byte  = r_RX_Byte;
    assign o_SPI_MISO = r_SPI_MISO;

    always @(posedge i_Clk or negedge i_Rst_L) begin
        if (!i_Rst_L) begin
            r_SPI_Clk_Sync <= {2{w_CPOL}};
            r_SS_L_Sync    <= 2'b11;
        end else begin
            r_SPI_Clk_Sync <= {r_SPI_Clk_Sync[1], i_SPI_Clk};
            r_SS_L_Sync    <= {r_SS_L_Sync[1], i_SPI_SS_L};
        end
    end

    always @(posedge i_Clk or negedge i_Rst_L) begin
        if (!i_Rst_L) begin
            r_TX_Bit_Count <= 3'd7;
            r_RX_Bit_Count <= 3'd7;
            r_TX_Shift     <= 8'h00;
            r_RX_Shift     <= 8'h00;
            r_TX_Ready     <= 1'b1;
            r_RX_DV        <= 1'b0;
            r_RX_Byte      <= 8'h00;
            r_SPI_MISO     <= 1'b0;
        end else begin
            r_RX_DV <= 1'b0;

            if (!w_SS_Active) begin
                r_TX_Ready <= 1'b1;
                r_RX_Bit_Count <= 3'd7;
                r_TX_Bit_Count <= 3'd7;
                r_SPI_MISO <= 1'b0;
            end else begin
                if (i_TX_DV && r_TX_Ready) begin
                    r_TX_Ready    <= 1'b0;
                    r_TX_Shift    <= i_TX_Byte;
                    r_RX_Bit_Count <= 3'd7;
                    if (!w_CPHA) begin
                        r_SPI_MISO     <= i_TX_Byte[7];
                        r_TX_Bit_Count <= 3'd6;
                    end else begin
                        r_TX_Bit_Count <= 3'd7;
                    end
                end

                if ((w_Leading_Edge && !w_CPHA) || (w_Trailing_Edge && w_CPHA)) begin
                    r_RX_Shift[r_RX_Bit_Count] <= i_SPI_MOSI;
                    if (r_RX_Bit_Count == 0) begin
                        r_RX_Byte <= {r_RX_Shift[7:1], i_SPI_MOSI};
                        r_RX_DV   <= 1'b1;
                    end
                    r_RX_Bit_Count <= r_RX_Bit_Count - 1;
                end

                if (!r_TX_Ready && ((w_Leading_Edge && w_CPHA) || (w_Trailing_Edge && !w_CPHA))) begin
                    r_SPI_MISO <= r_TX_Shift[r_TX_Bit_Count];
                    if (r_TX_Bit_Count == 0) begin
                        r_TX_Ready <= 1'b1;
                    end else begin
                        r_TX_Bit_Count <= r_TX_Bit_Count - 1;
                    end
                end
            end
        end
    end

endmodule
