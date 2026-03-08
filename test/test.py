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
    await uart_sink.read(count=1)
    await uart_sink.read(count=1)
    
    await uart_source.write([0b10001000]) # command to return value in sensor register
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0] & 0b00111111) << 6) + (data_b1[0] & 0b00111111)
    assert data_combined == 0b000000_000001
    

    dut._log.info("check write sensor value, should be 0b110010001101")
    await uart_source.write([0b00110010]) # write 110010xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01001101]) # write xxxxxx001101
    await uart_source.wait()
    # result should be 110010001101
    await uart_sink.read(count=1)
    await uart_sink.read(count=1)
    
    await uart_source.write([0b10001000]) # command to return value in sensor register
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0] & 0b00111111) << 6) + (data_b1[0] & 0b00111111)
    assert data_combined == 0b110010_001101


    dut._log.info("test software reset")
    await uart_source.write([0b10000000])
    await uart_source.wait()
    
    await uart_source.write([0b10001000]) # command to return value in sensor register
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0] & 0b00111111) << 6) + (data_b1[0] & 0b00111111)
    assert data_combined == 0b0


    dut._log.info("test set Kp")
    await uart_source.write([0b11000011]) # write 0011
    await uart_source.wait()
    
    dut._log.info("test set Ki")
    await uart_source.write([0b11010110]) # write 0110
    await uart_source.wait()
    
    await uart_source.write([0b10001010]) # command to return values in Kp, Ki
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_Kp = ((data_b0[0] & 0b00001111))
    data_Ki = ((data_b1[0] & 0b00001111))
    assert data_Kp == 0b0011
    assert data_Ki == 0b0110

    
    dut._log.info("test set the setpoint")
    await uart_source.write([0b10010001]) # write 0001xxxxxxxx
    await uart_source.wait()
    await uart_source.write([0b10100110]) # write xxxx0110xxxx
    await uart_source.wait()
    await uart_source.write([0b10111111]) # write xxxxxxxx1111
    await uart_source.wait()
    
    await uart_source.write([0b10001001]) # command to return value in setpoint register
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0] & 0b00111111) << 6) + (data_b1[0] & 0b00111111)
    assert data_combined == 0b0001_0110_1111


    dut._log.info("set sensor value less than setpoint")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if returned output is positive")
    data_1_b0 = await uart_sink.read(count=1)
    data_1_b1 = await uart_sink.read(count=1)
    data_1_combined = ((data_1_b0[0] & 0b00111111) << 6) + (data_1_b1[0] & 0b00111111)
    # convert to signed
    data_1_signed = 0
    if data_1_combined >= 0x800:
        data_1_signed = data_1_combined - 0x1000
    else:
        data_1_signed = data_1_combined

    await ClockCycles(dut.clk, 5000)

    assert data_1_signed > 0

    
    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is greater than before 1")
    data_2_b0 = await uart_sink.read(count=1)
    data_2_b1 = await uart_sink.read(count=1)
    data_2_combined = ((data_2_b0[0] & 0b00111111) << 6) + (data_2_b1[0] & 0b00111111)
    # convert to signed
    data_2_signed = 0
    if data_2_combined >= 0x800:
        data_2_signed = data_2_combined - 0x1000
    else:
        data_2_signed = data_2_combined

    await ClockCycles(dut.clk, 5000)
    
    assert data_2_signed > data_1_signed
    

    
    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is greater than before 2")
    data_3_b0 = await uart_sink.read(count=1)
    data_3_b1 = await uart_sink.read(count=1)
    data_3_combined = ((data_3_b0[0] & 0b00111111) << 6) + (data_3_b1[0] & 0b00111111)
    # convert to signed
    data_3_signed = 0
    if data_3_combined >= 0x800:
        data_3_signed = data_3_combined - 0x1000
    else:
        data_3_signed = data_3_combined

    await ClockCycles(dut.clk, 5000)
    
    assert data_3_signed > data_2_signed

    
    dut._log.info("test accumulated error: should be greater than 0")
    await uart_source.write([0b10001011])
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0]) << 8) + (data_b1[0])
    # convert to signed
    data_signed = 0
    if data_combined >= 0x8000:
        data_signed = data_combined - 0x10000
    else:
        data_signed = data_combined

    await ClockCycles(dut.clk, 5000)

    assert data_signed > 0

    
    dut._log.info("test reset accumulated error")
    await uart_source.write([0b10000001])
    await uart_source.wait()

    await ClockCycles(dut.clk, 5000)

    await uart_source.write([0b10001011])
    await uart_source.wait()
    data_b0 = await uart_sink.read(count=1)
    data_b1 = await uart_sink.read(count=1)
    data_combined = ((data_b0[0]) << 8) + (data_b1[0])
    # convert to signed
    data_signed = 0
    if data_combined >= 0x8000:
        data_signed = data_combined - 0x10000
    else:
        data_signed = data_combined
        
    await ClockCycles(dut.clk, 5000)

    assert data_signed == 0b0


    dut._log.info("same sensor value")
    await uart_source.write([0b00000000]) # write 000000xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01101111]) # write xxxxxx101111
    await uart_source.wait()
    dut._log.info("test if new data is less than before")
    data_4_b0 = await uart_sink.read(count=1)
    data_4_b1 = await uart_sink.read(count=1)
    data_4_combined = ((data_4_b0[0] & 0b00111111) << 6) + (data_4_b1[0] & 0b00111111)
    # convert to signed
    data_4_signed = 0
    if data_4_combined >= 0x800:
        data_4_signed = data_4_combined - 0x1000
    else:
        data_4_signed = data_4_combined

    await ClockCycles(dut.clk, 5000)
    
    assert data_4_signed < data_3_signed

    
    dut._log.info("reset accumulated error")
    await uart_source.write([0b10000001])
    await uart_source.wait()

    
    dut._log.info("much larger sensor value")
    await uart_source.write([0b00111111]) # write 111111xxxxxx
    await uart_source.wait()
    await uart_source.write([0b01111111]) # write xxxxxx111111
    await uart_source.wait()
    dut._log.info("test if new data is negative")
    data_5_b0 = await uart_sink.read(count=1)
    data_5_b1 = await uart_sink.read(count=1)
    data_5_combined = ((data_5_b0[0] & 0b00111111) << 6) + (data_5_b1[0] & 0b00111111)


    # convert to signed
    data_5_signed = 0
    if data_5_combined >= 0x800:
        data_5_signed = data_5_combined - 0x1000
    else:
        data_5_signed = data_5_combined

    await ClockCycles(dut.clk, 5000)
    
    assert data_5_signed < 0