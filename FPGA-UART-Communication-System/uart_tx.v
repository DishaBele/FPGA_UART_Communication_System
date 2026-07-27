`timescale 1ns / 1ps

module uart_tx (
    input clk,                    // 100 MHz clock
    input reset,                  // Asynchronous reset
    input [7:0] data_in,          // 8-bit data to transmit
    input send,                   // Signal to start transmission
    output reg tx,                // Serial output (UART TX line)
    output reg busy               // Indicates transmitter is busy
);

    // UART Parameters
    parameter CLK_FREQ = 100_000_000;  // 100 MHz
    parameter BAUD_RATE = 9600;        // 9600 bps
    parameter CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;  // 10417 cycles

    // FSM States
    parameter IDLE = 2'b00;
    parameter START_BIT = 2'b01;
    parameter DATA_BITS = 2'b10;
    parameter STOP_BIT = 2'b11;

    reg [1:0] state, next_state;
    reg [13:0] baud_counter;      // Counter for baud rate timing
    reg [3:0] bit_index;          // Index for 8 data bits
    reg [7:0] data_buffer;        // Holds data during transmission

    // State Machine
    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Combinational Logic for Next State
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:
                if (send)
                    next_state = START_BIT;

            START_BIT:
                if (baud_counter == CYCLES_PER_BIT - 1)
                    next_state = DATA_BITS;

            DATA_BITS:
                if ((baud_counter == CYCLES_PER_BIT - 1) && (bit_index == 7))
                    next_state = STOP_BIT;

            STOP_BIT:
                if (baud_counter == CYCLES_PER_BIT - 1)
                    next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    // Baud Counter Logic
    always @(posedge clk or negedge reset) begin
        if (!reset)
            baud_counter <= 0;
        else if (state != IDLE)
            if (baud_counter == CYCLES_PER_BIT - 1)
                baud_counter <= 0;
            else
                baud_counter <= baud_counter + 1;
        else
            baud_counter <= 0;
    end

    // Bit Index and Data Buffer
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            bit_index <= 0;
            data_buffer <= 0;
        end
        else if (state == IDLE) begin
            bit_index <= 0;
            if (send)
                data_buffer <= data_in;  // Capture input data
        end
        else if ((state == DATA_BITS) && (baud_counter == CYCLES_PER_BIT - 1))
            bit_index <= bit_index + 1;
    end

    // TX Output and Busy Flag
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            tx <= 1'b1;      // UART idle state is HIGH
            busy <= 1'b0;
        end
        else begin
            busy <= (state != IDLE);

            case (state)
                IDLE:
                    tx <= 1'b1;

                START_BIT:
                    tx <= 1'b0;  // Start bit is LOW

                DATA_BITS:
                    tx <= data_buffer[bit_index];  // LSB first

                STOP_BIT:
                    tx <= 1'b1;  // Stop bit is HIGH

                default:
                    tx <= 1'b1;
            endcase
        end
    end

endmodule