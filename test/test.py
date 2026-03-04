# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from cocotbext.uart import UartSource, UartSink


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 83.33 ns (12 MHz)
    clock = Clock(dut.clk, 83.33, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rx_in.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 100)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")
    
    await ClockCycles(dut.clk, 1)

    dut._log.info("initializing UART interface")
    uart_source = UartSource(dut.rx_in, baud=115200, bits=8)
    uart_sink = UartSink(dut.tx_out, baud=115200, bits=8)
    
    await ClockCycles(dut.clk, 10)

    dut._log.info("check write sensor value, should be 0b000000000001")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01000001]) # write xxxxxx000001
    await uart_source.wait()

    # result should be 000000000001
    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b000000000001
    

    dut._log.info("check write sensor value, should be 0b110010001101")
    await uart_source.write([0b00110010]) # write 110010xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01001101]) # write xxxxxx001101
    await uart_source.wait()
    
    # result should be 110010001101
    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b110010001101


    
    dut._log.info("test software reset")
    await uart_source.write([0b10000000])
    await uart_source.wait()

    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b0

    