# Tiny Tapeout PI Controller

## Test Status

![gds status](../../workflows/gds/badge.svg) ![docs status](../../workflows/docs/badge.svg) ![test status](../../workflows/test/badge.svg) ![fpga status](../../workflows/fpga/badge.svg)

## What does this project do?

The Tiny PI Controller implements a simple UART interface and internal PI compute module.

The PI compute module can be used for simple control systems applications where the D term is not necessary, such as in a motor controller.

It can be sent constantly updating sensor values over UART and responds with the computed PI value.
The Kp, Ki, and Setpoint values can also be configured over UART and will hold their values until changed. The device can also be set to reset over UART without needing to use the hardware reset pin.

Due to space constraints, the Kp and Ki constants bit shift the P and I terms instead of multiplying them

[Read the documentation for more information!](docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit <https://tinytapeout.com>.
