

# ATmega328P Matrix Keypad Security Lock

A low-level embedded system written in **AVR Assembly** for the ATmega328P (Arduino Uno/Nano). This project implements a secure keypad entry system with password validation, a retry-limit lockout, and external hardware button overrides.

## 🚀 Features

* **Matrix Keypad Scanning:** Efficiently scans a 4x4 or 3x4 matrix keypad using PORTD.
* **Security Logic:** * Pre-defined 4-digit password (`1234`).
* **Attempt Limit:** Users have 3 attempts before a lockout state occurs.
* **Reset Sequence:** Includes a hidden reset password (`9876`) to clear lockout states.


* **Hardware Indicators:** Visual feedback via LEDs (PORTB) indicating success, failure, and remaining attempts.
* **Manual Overrides:** Dedicated hardware buttons for immediate `LOCK` and `UNLOCK` states via PORTC.
* **Debouncing:** Software-based delay loop to prevent mechanical switch bouncing.

## 🛠️ Hardware Requirements

* **Microcontroller:** ATmega328P
* **Input:** 3x4 or 4x4 Matrix Keypad
* **Output:** 4x LEDs (Success, Fail, and 2x Status LEDs for binary attempt counting)
* **Buttons:** 2x Tactile Push Buttons (Lock/Unlock)

## 🖇️ Pin Mapping

| Component | Port Pin | Function |
| --- | --- | --- |
| **Keypad Rows** | PD4 - PD7 | Outputs (Scanning) |
| **Keypad Cols** | PD0 - PD3 | Inputs (Sensing) |
| **Success LED** | PB0 | High when unlocked |
| **Fail LED** | PB1 | High when locked/failed |
| **Status LEDs** | PB2, PB3 | Binary representation of attempts |
| **Lock Button** | PC1 | Manual reset to locked state |
| **Unlock Button** | PC2 | Manual bypass to unlocked state |

## 💻 Logic Flow

1. **Initialization:** Clears registers, sets Data Direction Registers (DDR), and turns on status LEDs.
2. **Wait for Input:** The system polls the keypad and the hardware buttons simultaneously.
3. **Key Extraction:** When a key is pressed, the code identifies the row and column, then pulls the corresponding digit from Program Memory (`.CSEG`).
4. **Verification:** * If `#` is pressed, the code compares the input buffer against the stored password.
* If successful, `SUCCESS_LED` triggers.
* If failed, the attempt counter decrements, and the binary LEDs update.


5. **Lockout/Reset:** If attempts reach zero, the user must enter the specific `resetdigit` sequence to regain access.

## ⚙️ How to Build the Simulation

1. Open the project in **Microchip Studio** (formerly Atmel Studio).
2. Ensure `m328pdef.inc` is included in your project path.
3. Assemble the `.asm` file to generate the `.hex` file.
4. Flash to the ATmega328P using an ISP programmer (like USBasp) or via the Arduino bootloader using `avrdude`.

