<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# Tiny PI Controller

## How it works

The Tiny PI Controller implements a simple UART interface and internal PI compute module.

The PI compute module can be used for simple control systems applications where the D term is not necessary, such as in a motor controller.

It can be sent constantly updating sensor values over UART and responds with the computed PI value.
The Kp, Ki, and Setpoint values can also be configured over UART and will hold their values until changed. The device can also be set to reset over UART without needing to use the hardware reset pin.

Due to space constraints, the Kp and Ki constants bit shift the P and I terms instead of multiplying them

## How to use it

The UART communicationm must be 1 start, 8 data, 1 stop, no parity
The controller can be sent various commands by changing the structure of the data in the message
- 00xxxxxx - sets the upper 6 bits [11:6] of the internal sensor register to the lower 6 bits [5:0] of the message
- 01xxxxxx - sets the lower 6 bits [5:0] of the internal sensor register to the lower 6 bits [5:0] of the message and runs the controller. This will also accumulate error
- 1xxxxxxx - halts the controller and allows for it to be configured:
  - 1000xxx0 - resets the controller. This is the same as pulling the external reset pin down
  - 1000xxx1 - resets the accumulated error for the I term of the controller
  - 1001xxxx - Sets the upper 4 bits [11:8] of the setpoint to the lower 4 bits of the message [3:0] 
  - 1010xxxx - Sets the middle 4 bits [7:4] of the setpoint to the lower 4 bits of the message [3:0]
  - 1011xxxx - Sets the lower 4 bits [3:0] of the setpoint to the lower 4 bits of the message [3:0]
  - 1100xxxx - sets the Kp value [3:0] to the value in the last 4 bits [3:0]. The Kp and Ki value formats are listed below
  - 1101xxxx - sets the Ki value [3:0] to the value in the last 4 bits [3:0]. The Kp and Ki value formats are listed below
  - 111xxxxx - Does nothing.


Upon recieving a 01xxxxxx message, the controller will read its internal sensor register and immediately output the resulting computed value over on the TX line. This operation takes 2 UART frames and has the following format:
- 00xxxxxx - The upper 6 bits [11:6] of the output are sent first, with the 00 header
- 01xxxxxx - the lower 6 bits [5:0] are then sent, with the 01 header

### Note the sensor and setpoint are unsiged values 12 bit values. The output is signed in 2s complement and is 12 bits, where the MSB is the sign bit

### Kp and Ki value formats:
Due to space constraints, the chip cannot implement a multiplier for the P and I terms. Instead, it performs bit shifts on the error and accumulated error values and sums these.
- Kp - determines how much to shift error by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the P term
- Ki - determines how much to shift accumulated error by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the I term

## External hardware

The Tiny PI Controller requires a 12Mhz external clock and a device capable of UART communication with 115200 baudrate a slower or faster clock can be provided, and the UART baudrate changes proportionally (ie a 6Mhz external clock -> 57600 UART baudrate)

The device supports up to 48Mhz external clock with a UART baudrate of 460800

## Future changes

- Change the interface to be SPI instead of UART for faster communication
- Increase the size of the chip to allow for an internal multiplier instead of shifts for the Kp and Ki constants