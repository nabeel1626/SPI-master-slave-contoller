`timescale 1ns / 1ps

module spi_master_slave_modes_tb();

    parameter CLKS_PER_HALF_BIT = 2;
    parameter CLK_PERIOD        = 10;

    reg        i_Rst_L;
    reg        i_Clk;

    reg  [7:0] m_TX_Byte [0:3];
    reg        m_TX_DV   [0:3];
    wire       m_TX_Ready[0:3];
    wire       m_RX_DV   [0:3];
    wire [7:0] m_RX_Byte [0:3];

    reg  [7:0] s_TX_Byte [0:3];
    reg        s_TX_DV   [0:3];
    wire       s_TX_Ready[0:3];
    wire       s_RX_DV   [0:3];
    wire [7:0] s_RX_Byte [0:3];

    wire       spi_clk  [0:3];
    wire       spi_mosi [0:3];
    wire       spi_miso [0:3];
    wire       spi_ss_l [0:3];

    genvar mode;
    generate
        for (mode = 0; mode < 4; mode = mode + 1) begin : pair
            spi_master #(
                .SPI_MODE(mode),
                .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
            ) master_inst (
                .i_Rst_L(i_Rst_L),
                .i_Clk(i_Clk),
                .i_TX_Byte(m_TX_Byte[mode]),
                .i_TX_DV(m_TX_DV[mode]),
                .o_TX_Ready(m_TX_Ready[mode]),
                .o_RX_DV(m_RX_DV[mode]),
                .o_RX_Byte(m_RX_Byte[mode]),
                .o_SPI_Clk(spi_clk[mode]),
                .o_SPI_MOSI(spi_mosi[mode]),
                .o_SPI_SS_L(spi_ss_l[mode]),
                .i_SPI_MISO(spi_miso[mode])
            );

            spi_slave #(
                .SPI_MODE(mode)
            ) slave_inst (
                .i_Rst_L(i_Rst_L),
                .i_Clk(i_Clk),
                .i_SPI_Clk(spi_clk[mode]),
                .i_SPI_SS_L(spi_ss_l[mode]),
                .i_SPI_MOSI(spi_mosi[mode]),
                .i_TX_Byte(s_TX_Byte[mode]),
                .i_TX_DV(s_TX_DV[mode]),
                .o_SPI_MISO(spi_miso[mode]),
                .o_RX_DV(s_RX_DV[mode]),
                .o_RX_Byte(s_RX_Byte[mode]),
                .o_TX_Ready(s_TX_Ready[mode])
            );
        end
    endgenerate

    integer i;

    always begin
        #(CLK_PERIOD/2) i_Clk = ~i_Clk;
    end

    initial begin
        i_Clk = 1'b0;
        i_Rst_L = 1'b0;
        for (i = 0; i < 4; i = i + 1) begin
            m_TX_Byte[i] = 8'h00;
            m_TX_DV[i]   = 1'b0;
            s_TX_Byte[i] = 8'h00;
            s_TX_DV[i]   = 1'b0;
        end

        $dumpfile("spi_master_slave_modes_tb.vcd");
        $dumpvars(0, spi_master_slave_modes_tb);

        #(CLK_PERIOD * 5);
        i_Rst_L = 1'b1;
        #(CLK_PERIOD * 5);

        run_mode_transfer(0, 8'hA5, 8'h3C);
        run_mode_transfer(1, 8'h5A, 8'hC3);
        run_mode_transfer(2, 8'hAA, 8'h55);
        run_mode_transfer(3, 8'hFF, 8'h00);

        #(CLK_PERIOD * 100);
        $display("===== SPI mode coverage simulation complete =====");
        $finish;
    end

    task run_mode_transfer(input integer mode_index, input [7:0] master_data, input [7:0] slave_data);
        begin
            $display("\n===== MODE %0d =====", mode_index);
            wait(m_TX_Ready[mode_index] && s_TX_Ready[mode_index]);
            #(CLK_PERIOD);
            slave_load(mode_index, slave_data);
            master_load(mode_index, master_data);
            wait(m_RX_DV[mode_index] && s_RX_DV[mode_index]);
            #(CLK_PERIOD);
            $display("MODE %0d: master sent 0x%02h, slave received 0x%02h", mode_index, master_data, s_RX_Byte[mode_index]);
            $display("MODE %0d: slave sent 0x%02h, master received 0x%02h", mode_index, slave_data, m_RX_Byte[mode_index]);
            if (m_RX_Byte[mode_index] != slave_data || s_RX_Byte[mode_index] != master_data) begin
                $display("MODE %0d: FAIL", mode_index);
            end else begin
                $display("MODE %0d: PASS", mode_index);
            end
        end
    endtask

    task slave_load(input integer mode_index, input [7:0] data);
        begin
            s_TX_Byte[mode_index] = data;
            s_TX_DV[mode_index]   = 1'b1;
            #(CLK_PERIOD);
            s_TX_DV[mode_index]   = 1'b0;
        end
    endtask

    task master_load(input integer mode_index, input [7:0] data);
        begin
            m_TX_Byte[mode_index] = data;
            m_TX_DV[mode_index]   = 1'b1;
            #(CLK_PERIOD);
            m_TX_DV[mode_index]   = 1'b0;
        end
    endtask

endmodule
