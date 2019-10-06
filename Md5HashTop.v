`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Algorithms to architecture(Assignment 2) 
// Engineer: saranya006@e.ntu.edu.sg
// 
// Create Date:    18:56:46 01/05/2017 
// Design Name:    MD5 Hashing Algorithm
// Module Name:    Md5HashTop 
// Project Name:   Md5Hashing
// Target Devices: Sparten 6
// Tool versions:  14.3
// Description:    Receive the chunk of data through serial interface, perform MD5 algorithm 
//                 to find the digest of the data and return 128 bit digest via serial to terminal device.
//
// Dependencies:   Sparton 6 kit, Uart Module, Serial terminl program
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// terminal data will be ended with "EOF" signal which will be detected by the program for end of the chunk data.
//////////////////////////////////////////////////////////////////////////////////
module Md5HashTop(
	 input clk_in,
	 input reset,
	 input rx,
	 output tx
    );
	 
	 wire clk;

	 wire clk_ibufg;
    wire clk_int;
    IBUFG clk_ibufg_inst (.I(clk_in), .O(clk_ibufg));
    BUFG clk_bufg_inst (.I(clk_ibufg), .O(clk));
	 

	 wire err;
	 wire received;
	 wire [7:0] rx_byte;
	 wire [7:0] tx_byte;
	 wire tx_enable;
	 wire tx_active;
	 wire rx_active;

	 
uart #(.CLOCK_DIVIDE(217)) UartRxTx(
                                   .clk(clk),                             // The master clock for this module
                                   .rst(reset),                           // Synchronous reset.
                                   .rx(rx),                               // Incoming serial line
                                   .tx(tx),                               // Outgoing serial line
                                   .transmit(tx_enable),                   // Signal to transmit
                                   .tx_byte(tx_byte),                     // Byte to transmit
                                   .received(received),                   // Indicated that a byte has been received.
                                   .rx_byte(rx_byte),                     // Byte received
                                   .is_receiving(rx_active),              // Low when receive line is idle.
                                   .is_transmitting(tx_active),           // Low when transmit line is idle.
                                   .recv_error(err)                       // Indicates error in receiving packet.
                                   );

 
Md5Hash hash(
               .clk(clk),                             // The master clock for this module
               .reset(reset),                         // Synchronous reset.
					.rx_byte(rx_byte),                     // Byte received	
					.received(received),
					.is_transmitting(tx_active),           // Low when transmit line is idle.
					.transmit(tx_enable),                  // Signal to transmit
					.tx_byte(tx_byte)                      // Byte to transmit
            );
				  
					  
endmodule
