# LPR-based-on-Cortex-M3-in-FPGA
This project is for Integrated circuit design contest (China) in Mid-2021. We build a LPR (only for Chinese license plate) project based on Digilent Nexy4-DDR with ARM Cortex™-M3 core. Of course, there are still some problems in the system. The project is more about the hardware level. To know more about the algorithm part, github has a lot of ultra excellent programs. We follow open source agreements, so we decide to upload the entire project.

**//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Be sure to follow open source agreements !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!//**



**<----------------------------------- Part 1: Description of system requirements --------------------------------------->**


The scenario for this project is to automate access the parking lot. Some of the identification solutions currently in use, such as automated systems operating in x86 architecture environments, may have slow license plate identification speeds and low access efficiency for parking lot vehicles due to ambient noise interference, and this work will improve the identification system in this regard.

This is an embedded chip system designed to automate *image acquisition*, *transmission*, *recognition*, *display* and *voice broadcasting* functions, in the specific implementation, the first is to build processing units - using ARM Cortex-M3 DesignStart architecture processor on the Nexys4-DDR board construction system. The Chinese characters, letters, and numbers in the image will be processed using convolutional neural networks, and the ARM architecture will have significant hardware acceleration advantages, and finally, the results will be fed back to the display via the SPI bus interface of the system on the ARM chip. When the vehicle is in the "entry" state, the system sends the recognized vehicle number and the acquired system time to the cloud and outputs "welcome" audio through the peripheral, and when the vehicle is in the "away" state, the system sends the recognized vehicle number and the acquired system time to the cloud, calculates the parking fee, and outputs the "safe journey" audio through the audio peripheral.

The following features are implemented：
1. image acquisition
2. data transmission
3. image recognition
4. Words and real-time video display
5. Sound
6. Ethernet connection(WLAN)



**<--------------------------- Part 2: Hardware and software division and task assignment ----------------------------->**


We have a hardware acceleration core. It can reach all functions about image reconition and accelerate processiong speed. A typical image recognition process involves the following aspects:
1. Image grayscale transformation: rgb to gray
2. Image edge detection
3. License plate positioning
4. Divalode: convert to Black and white images
5. Character split
6. Character normalization
7. Identification of license plates

The model we built use a two-stage AHB bus structure —— Only ultra high speed peripheral can be Mounted on the first AHB structure, including Cortex-M3 core, DDR controller, DMA block, ITCM and DTCM. APB and the secondary AHB are connected to the primary AHB bus by a synchronous bridge. AHB bus maybe need more ports that are not enough in the bus. So we can change *cmsdk_ahb_busmatrix_l1.xml* or *cmsdk_ahb_busmatrix_l2.xml* content to generate new AHB bus with more ports. The build process requires **WSL(Windows Subsystem for Linux)** support. For more about using **WSL** to genarate new AHB bus, you can visit https://aijishu.com/a/1060000000095018. 

The following peripherals are connected to the APB bus:
1. SD card
2. I2S audio interface
3. UART interface
4. LCD HMI

The following peripherals are connected to the *L2_AHB* bus:
1. OV5640 Camera device
2. HDMI
3. Ethernet
4. GPIO interface



**<---------------------------------- Part 3: RTL level design ------------------------------------>**


We use Verilog HDL to build this system. The application used for development is Xilinx Vivado 2019.2. Please confirm your Vivado version before use. *.xpr* project file is available, and you can find it in the path *$ vivado/cortex_M3_verification.zip*. To avoid compatibility error, we strongly advise you build project by yourself.



