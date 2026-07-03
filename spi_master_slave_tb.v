`timescale 1ns / 1ps

module spi_master_slave_tb();

    parameter SPI_MODE          = 0;
    parameter CLKS_PER_HALF_BIT = 2;
    parameter CLK_PERIOD        = 10;

    // Common signals
    reg        i_Rst_L;
    reg        i_Clk;

    // Master TX
    reg  [7:0] m_TX_Byte;
    reg        m_TX_DV;
    wire       m_TX_Ready;

    // Master RX
    wire       m_RX_DV;
    wire [7:0] m_RX_Byte;

    // Slave TX
    reg  [7:0] s_TX_Byte;
    reg        s_TX_DV;
    wire       s_TX_Ready;

    // Slave RX
    wire       s_RX_DV;
    wire [7:0] s_RX_Byte;

    // SPI bus
    wire       o_SPI_Clk;
    wire       o_SPI_MOSI;
    wire       o_SPI_MISO;

    spi_master #(
        .SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
    ) master_inst (
        .i_Rst_L(i_Rst_L),
        .i_Clk(i_Clk),
        .i_TX_Byte(m_TX_Byte),
        .i_TX_DV(m_TX_DV),
        .o_TX_Ready(m_TX_Ready),
        .o_RX_DV(m_RX_DV),
        .o_RX_Byte(m_RX_Byte),
        .o_SPI_Clk(o_SPI_Clk),
        .i_SPI_MISO(o_SPI_MISO),
        .o_SPI_MOSI(o_SPI_MOSI)
    );

    spi_slave #(
        .SPI_MODE(SPI_MODE)
    ) slave_inst (
        .i_Rst_L(i_Rst_L),
        .i_Clk(i_Clk),
        .i_SPI_Clk(o_SPI_Clk),
        .i_SPI_MOSI(o_SPI_MOSI),
        .i_TX_Byte(s_TX_Byte),
        .i_TX_DV(s_TX_DV),
        .o_SPI_MISO(o_SPI_MISO),
        .o_RX_DV(s_RX_DV),
        .o_RX_Byte(s_RX_Byte),
        .o_TX_Ready(s_TX_Ready)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) i_Clk = ~i_Clk;
    end

    initial begin
        i_Clk      = 1'b0;
        i_Rst_L    = 1'b0;
        m_TX_Byte  = 8'h00;
        m_TX_DV    = 1'b0;
        s_TX_Byte  = 8'h00;
        s_TX_DV    = 1'b0;

        $dumpfile("spi_master_slave_tb.vcd");
        $dumpvars(0, spi_master_slave_tb);

        #(CLK_PERIOD * 5);
        i_Rst_L = 1'b1;
        #(CLK_PERIOD * 5);

        run_transfer(8'hA5, 8'h3C);
        run_transfer(8'h5A, 8'hC3);
        run_transfer(8'h55, 8'hAA);

        #(CLK_PERIOD * 200);
        $display("===== SPI master/slave simulation complete =====");
        $finish;
    end

    task run_transfer(input [7:0] master_data, input [7:0] slave_data);
        begin
            wait(m_TX_Ready && s_TX_Ready);
            #(CLK_PERIOD);
            $display("[%0t] Starting transfer: master=0x%02h slave=0x%02h ready(M/S)=%b/%b", $time, master_data, slave_data, m_TX_Ready, s_TX_Ready);
            slave_load(slave_data);
            master_send(master_data);
            wait(m_RX_DV);
            #(CLK_PERIOD);
            $display("[%0t] Master sent 0x%02h, received 0x%02h; Slave received 0x%02h", $time, master_data, m_RX_Byte, s_RX_Byte);
        end
    endtask

    task slave_load(input [7:0] data);
        begin
            s_TX_Byte = data;
            s_TX_DV   = 1'b1;
            #(CLK_PERIOD);
            s_TX_DV   = 1'b0;
            $display("[%0t] Slave load asserted data=0x%02h ready=%b", $time, data, s_TX_Ready);
        end
    endtask

    task master_send(input [7:0] data);
        begin
            m_TX_Byte = data;
            m_TX_DV   = 1'b1;
            #(CLK_PERIOD);
            m_TX_DV   = 1'b0;
            $display("[%0t] Master load asserted data=0x%02h ready=%b", $time, data, m_TX_Ready);
        end
    endtask

endmodule
