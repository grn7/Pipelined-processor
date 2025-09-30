# 🚀 Pipelined RISC-V Processor: A Journey into High-Performance CPU Design

Welcome to our implementation of a 5-stage pipelined RISC-V processor\! This project is more than just a bunch of SystemVerilog files; it's a deep dive into the fascinating world of computer architecture, where we turn simple logic gates into a powerful computing engine.

## ✨ Key Features

  * ** blazing\_fast: 5-Stage Pipelined Architecture:** We're talking about a classic 5-stage pipeline (IF, ID, EX, MEM, WB) that allows the processor to work on multiple instructions simultaneously, boosting performance significantly.
  * **🧠 Intelligent Hazard Detection:** Our processor is smart enough to detect and handle data hazards, preventing incorrect results and ensuring the integrity of your programs.
  * **forwarding: Data Forwarding for Maximum Efficiency:** Why wait when you can forward? The built-in forwarding unit minimizes stalls by cleverly routing data from later pipeline stages back to where it's needed most.
  * **🔮 Crystal Ball Branch Prediction:** Our branch predictor uses a 2-bit saturating counter to make educated guesses about the outcome of branch instructions, minimizing pipeline flushes and keeping the instruction flow smooth.
  * **💻 RISC-V Instruction Set Support:** This processor understands a subset of the elegant and powerful RISC-V instruction set, including R-type, I-type, S-type, and B-type instructions.

## 🛠️ The Pipeline Stages

Here's a quick look at the journey an instruction takes through our processor:

1.  **Instruction Fetch (IF):** Fetches the next instruction from memory.
2.  **Instruction Decode (ID):** Decodes the instruction and fetches the required operands from the register file.
3.  **Execute (EX):** Performs the actual computation using the ALU.
4.  **Memory Access (MEM):** Reads from or writes to data memory.
5.  **Write Back (WB):** Writes the result of the computation back to the register file.

## 🎮 Supported Instructions

This processor can handle a variety of RISC-V instructions, including:

  * **R-type:** `ADD`, `SUB`, `AND`, `OR`
  * **I-type:** `LD`, `ADDI`
  * **S-type:** `SD`
  * **B-type:** `BEQ`, `BNE`

## 🚀 Quick Start

Ready to see this processor in action? Follow these simple steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/pipelined-processor.git
    ```
2.  **Navigate to the project directory:**
    ```bash
    cd pipelined-processor
    ```
3.  **Compile and run the simulation:**
    ```bash
    iverilog -o pipeline_cpu -s pipeline_cpu_tb src/*.sv testbench/*.sv
    vvp pipeline_cpu
    ```

## 🧪 Testing

The included testbench (`pipeline_cpu_tb.sv`) runs a Fibonacci sequence program to put the processor through its paces. It also includes a performance monitor to track key metrics like Cycles Per Instruction (CPI). You can find the program and data files in the `programs` directory.

## 🙌 Contributing

Got ideas for how to make this processor even better? Contributions are always welcome\! Feel free to fork the repository, make your changes, and submit a pull request.

## 📜 License

This project is currently unlicensed. Feel free to add a license that suits your needs.
