`timescale 1ns / 1ps

module uart_top (
    input clk,                    // 100 MHz clock
    input reset,                  // Asynchronous reset (active low)
    
    // TX Interface
    input [7:0] tx_data,          // 8-bit data to transmit
    input tx_send,                // Pulse to start transmission
    output tx,                    // Serial TX output
    output tx_busy,               // TX busy signal
    
    // RX Interface
    input rx,                     // Serial RX input
    output [7:0] rx_data,         // 8-bit data received
    output rx_valid               // Pulse when data valid
);

    // Instantiate UART Transmitter
    uart_tx tx_module (
        .clk(clk),
        .reset(reset),
        .data_in(tx_data),
        .send(tx_send),
        .tx(tx),
        .busy(tx_busy)
    );

    // Instantiate UART Receiver
    uart_rx rx_module (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

endmodule