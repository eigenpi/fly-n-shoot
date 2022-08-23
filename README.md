1) Description

This project implements the classic Fly-n-Shoot game entirely in VHDL
and verifies its correct operation on real hardware, DE1-SoC FPGA board.

It is implemented by translating Unified Modeling Language (UML) Statecharts 
that describe the Fly-n-Shoot game as an event-driven embedded system
into synthesizable VHDL code, which uses the two-process coding style.

2) How to run

You need to use Intel Quartus II software to create a project and use all
the provided VHDL files + pin assignment file; synthesize and place & route
the design; then, generate the programming file. 
Alternaively, you could just use directly the provide .sof programming file.

Hardware needed: 
  --DE1-SoC board 
  --VGA monitor 
  --NEC Controller (optional)

See vhdl/README.setup.txt for details on how to connect the NEC Controller to the board.
However, the game can be played using the pushbuttons KEY0, KEY1, and KEY2 of 
the DE1-SoC board. The game can be played using either these buttons or the NEC Controller.

3) Resources

YouTube video with demonstration: 
  https://www.youtube.com/watch?v=EWZZK2uyEOw
  
Paper that describes translation from UML statecharts into VHDL code: 
  http://dejazzer.com/publications.html 

4) Credits

The following two excellent books:

  [1] Miro Samek, “Practical UML Statecharts in C/C++,” Second Edition, Elsevier, 2009.
  
  [2] Pong P. Chu, “FPGA Prototyping by VHDL Examples,” Wiley, 2008.
  
