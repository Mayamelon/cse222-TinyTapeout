<!---

This file is used to generate your project data sheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The Tiny PI Controller implements a simple UART interface and internal PI compute module.

The PI compute module can be used for simple control systems applications where the D term is not necessary, such as in a motor controller.

It can be sent constantly updating sensor values over UART and responds with the computed PI value.
The Kp, Ki, and Setpoint values can also be configured over UART and will hold their values until changed. The device can also be set to reset over UART without needing to use the hardware reset pin.

Due to space constraints, the Kp and Ki constants bit shift the P and I terms instead of multiplying them

## How to use it

The UART communication must be 1 start, 8 data, 1 stop, no parity
The controller can be sent various commands by changing the structure of the data in the message

- 00xxxxxx - sets the upper 6 bits [11:6] of the internal sensor register to the lower 6 bits [5:0] of the message
- 01xxxxxx - sets the lower 6 bits [5:0] of the internal sensor register to the lower 6 bits [5:0] of the message and runs the controller. This will also accumulate error
- 1xxxxxxx - The controller will allow itself to be configured or respond about internal register values:
  - 10000000 - Resets the controller. This is the same as pulling the external reset pin down
  - 10000001 - Resets the accumulated error for the I term of the controller. Note that the accumulated error is stored internally as a 16 bit signed integer
  - 1000001x - Does nothing.
  - 100001xx - Does nothing.
  - 10001000 - Instructs the controller to respond over TX with what is stored in its internal sensor register.
  - 10001001 - Instructs the controller to respond over TX with what is stored in its internal setpoint register.
  - 10001010 - Instructs the controller to respond over TX with what is stored in its internal Kp and Ki registers.
  - 10001011 - Instructs the controller to respond over TX with what is stored in its internal accumulated error register.
  - 100011xx - Does nothing.
  - 1001xxxx - Sets the upper 4 bits [11:8] of the setpoint to the lower 4 bits of the message [3:0]
  - 1010xxxx - Sets the middle 4 bits [7:4] of the setpoint to the lower 4 bits of the message [3:0]
  - 1011xxxx - Sets the lower 4 bits [3:0] of the setpoint to the lower 4 bits of the message [3:0]
  - 1100xxxx - sets the Kp value [3:0] to the value in the last 4 bits [3:0]. The Kp and Ki value formats are listed below
  - 1101xxxx - sets the Ki value [3:0] to the value in the last 4 bits [3:0]. The Kp and Ki value formats are listed below
  - 111xxxxx - Does nothing.

### Note the setpoint and sensor inputs are unsigned 12 bit values

### UART Transmissions

Upon receiving a 01xxxxxx message, the controller will read its internal sensor register and immediately outputs the resulting computed value over on the TX line. This operation takes 2 UART frames and has the following format:

- 00xxxxxx - The upper 6 bits [11:6] of the output are sent first, with the 00 header
- 01xxxxxx - The lower 6 bits [5:0] are then sent, with the 01 header
- The full output value [11:0] is signed with 2s complement and bit 11 is the sign bit

Upon receiving a 10001001 message, the controller wil respond with what is stored on its internal sensor register. This operation takes 2 UART frames and has the following format:

- 00xxxxxx - The upper 6 bits [11:6] of the sensor register are sent first, with the 00 header
- 01xxxxxx - he lower 6 bits [5:0] of the sensor register are then sent, with the 01 header
- The full sensor value [11:0] is unsigned

Upon receiving a 10001010 message, the controller wil respond with what is stored on its internal setpoint register. This operation takes 2 UART frames and has the following format:

- 00xxxxxx - The upper 6 bits [11:6] of the setpoint register are sent first, with the 00 header
- 01xxxxxx - he lower 6 bits [5:0] of the setpoint register are then sent, with the 01 header
- The full setpoint value [11:0] is unsigned

Upon receiving a 10001011 message, the controller wil respond with what is stored on its internal Kp and Ki registers. This operation takes 2 UART frames and has the following format:

- 0000xxxx - The Kp register is sent first with the bits [3:0] and the 0000 header
- 0001xxxx - The Ki register is then sent with the bits [3:0] and the 0001 header
- See the section below on Kp and Ki value formats

Upon receiving a 10001100 message, the controller wil respond with what is stored on its internal accumulated error register. This operation takes 2 UART frames and has the following format:

- xxxxxxxx - The upper 8 bits [15:8] of the accumulated error register are sent first
- xxxxxxxx - he lower 8 bits [7:0] of the accumulated error register are then sent.
- The full accumulated error register value [15:0] is signed with 2s complement and bit 15 is the sign bit

### Kp and Ki value formats

Due to space constraints, the chip cannot implement a multiplier for the P and I terms. Instead, it performs bit shifts on the error and accumulated error values and sums these to form the output.

- Kp - determines how much to shift error by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the P term
- Ki - determines how much to shift accumulated error by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the I term

## External hardware

The Tiny PI Controller requires a 12Mhz external clock and a device capable of UART communication with 115200 baud rate a slower or faster clock can be provided, and the UART baud rate changes proportionally (ie a 6Mhz external clock -> 57600 UART baud rate)

The device supports up to 48Mhz external clock with a UART baud rate of 460800

## Future changes

- Change the interface to be SPI instead of UART for faster communication
- Increase the size of the chip to allow for an internal multiplier instead of shifts for the Kp and Ki constants
- Allow the chip to report the accumulated I term
