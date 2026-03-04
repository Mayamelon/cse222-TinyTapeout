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
    
    await ClockCycles(dut.clk, 10)


    dut._log.info("check write sensor value, should be 0b000000000001")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01000001]) # write xxxxxx000001
    await uart_source.wait()
    # result should be 000000000001
    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b0000_0000_0001
    

    dut._log.info("check write sensor value, should be 0b110010001101")
    await uart_source.write([0b00110010]) # write 110010xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01001101]) # write xxxxxx001101
    await uart_source.wait()
    # result should be 110010001101
    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b1100_1000_1101

    
    await ClockCycles(dut.clk, 2000)


    dut._log.info("test software reset")
    await uart_source.write([0b10000000])
    await uart_source.wait()
    assert dut.user_project.uart_interface_inst.sensor_r.value == 0b0 # check that the internal sensor register is reset to 0

    dut._log.info("test set Kp")
    await uart_source.write([0b11000011]) # write 0011
    await uart_source.wait()
    assert dut.user_project.uart_interface_inst.Kp_o.value == 0b0011
    
    dut._log.info("test set Ki")
    await uart_source.write([0b11010110]) # write 0110
    await uart_source.wait()
    assert dut.user_project.uart_interface_inst.Ki_o.value == 0b0110

    
    dut._log.info("test set the setpoint")
    await uart_source.write([0b10010001]) # write 0001xxxxxxxx
    await uart_source.wait()
    await uart_source.write([0b10100110]) # write xxxx0110xxxx
    await uart_source.wait()
    await uart_source.write([0b10111111]) # write xxxxxxxx1111
    await uart_source.wait()
    assert dut.user_project.uart_interface_inst.setpoint_o.value == 0b0001_0110_1111

    uart_sink = UartSink(dut.tx_out, baud=115200, bits=8)


    dut._log.info("set sensor value less than setpoint")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if transmit occurs")
    data_1 = await uart_sink.read(count=1)
    data_1 += await uart_sink.read(count=1)

    await ClockCycles(dut.clk, 5000)

    assert int.from_bytes(data_1, byteorder='big', signed=True) > 0

    
    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is greater than before 1")
    data_2 = await uart_sink.read(count=1)
    data_2 += await uart_sink.read(count=1)

    await ClockCycles(dut.clk, 5000)
    
    assert int.from_bytes(data_2, byteorder='big', signed=True) > int.from_bytes(data_1, byteorder='big', signed=True)
    

    
    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is greater than before 2")
    data_3 = await uart_sink.read(count=1)
    data_3 += await uart_sink.read(count=1)

    await ClockCycles(dut.clk, 5000)
    
    assert int.from_bytes(data_3, byteorder='big', signed=True) > int.from_bytes(data_2, byteorder='big', signed=True)

    
    dut._log.info("test reset accumulated error")
    await uart_source.write([0b10000001])
    await uart_source.wait()


    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is less than before")
    data_4 = await uart_sink.read(count=1)
    data_4 += await uart_sink.read(count=1)

    await ClockCycles(dut.clk, 5000)
    
    assert int.from_bytes(data_4, byteorder='big', signed=True) < int.from_bytes(data_3, byteorder='big', signed=True)

    
    dut._log.info("reset accumulated error")
    await uart_source.write([0b10000001])
    await uart_source.wait()

    
    dut._log.info("much larger sensor value")
    await uart_source.write([0b00111111]) # write 111111xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01111111]) # write xxxxxx111111
    await uart_source.wait()
    dut._log.info("test if new data is negative")
    data_5 = await uart_sink.read(count=1)
    data_5 += await uart_sink.read(count=1)

    await ClockCycles(dut.clk, 5000)
    
    assert int.from_bytes(data_5, byteorder='big', signed=True) < 0