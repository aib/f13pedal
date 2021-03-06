CC = avr-gcc
CP = cp
AVRDUDE = avrdude
AVRDUDE_OPTS = -B 1
LUFA_DIR = ./LUFA

ARCH = ARCH_AVR8
DEVICE = atmega32u4
PROGRAMMER = usbtiny
PROGRAMMER_PORT = usb
F_CPU = 16000000
FUSE_H = 0b10011001
FUSE_L = 0b01011110

CFLAGS = -std=c99 -Wall -O2 -mmcu=$(DEVICE) -DF_CPU=$(F_CPU)UL -DF_USB=$(F_CPU)UL -DUSE_LUFA_CONFIG_HEADER -I.

.PHONY: all
all: pedal program

.PHONY: avrdude-test
avrdude-test:
	$(AVRDUDE) $(AVRDUDE_OPTS) -p $(DEVICE) -c $(PROGRAMMER) -P $(PROGRAMMER_PORT) -v

.PHONY: program
program: pedal.hex
	$(AVRDUDE) $(AVRDUDE_OPTS) -p $(DEVICE) -c $(PROGRAMMER) -P $(PROGRAMMER_PORT) -U flash:w:$<:i

.PHONY: program-fuses
program-fuses:
	$(AVRDUDE) $(AVRDUDE_OPTS) -p $(DEVICE) -c $(PROGRAMMER) -P $(PROGRAMMER_PORT) -U hfuse:w:$(FUSE_H):m -U lfuse:w:$(FUSE_L):m

.PHONY: clean
clean:
	$(RM) *.o *.elf *.hex

%.elf: %.o
	$(CC) -s $(CFLAGS) -o $@ $^

%.hex: %.elf
	avr-objcopy -j .text -j .data -O ihex $^ $@

.PHONY: pedal
lufakey: pedal.hex
	$(CP) pedal.hex main.hex
	avr-size main.hex

HIDClassDevice.o: $(LUFA_DIR)/Drivers/USB/Class/Device/HIDClassDevice.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
USBController_AVR8.o: $(LUFA_DIR)/Drivers/USB/Core/AVR8/USBController_AVR8.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
USBTask.o: $(LUFA_DIR)/Drivers/USB/Core/USBTask.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
Endpoint_AVR8.o: $(LUFA_DIR)/Drivers/USB/Core/AVR8/Endpoint_AVR8.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
EndpointStream_AVR8.o: $(LUFA_DIR)/Drivers/USB/Core/AVR8/EndpointStream_AVR8.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
USBInterrupt_AVR8.o: $(LUFA_DIR)/Drivers/USB/Core/AVR8/USBInterrupt_AVR8.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
DeviceStandardReq.o: $(LUFA_DIR)/Drivers/USB/Core/DeviceStandardReq.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^
Events.o: $(LUFA_DIR)/Drivers/USB/Core/Events.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(@F) $^

pedal.elf: pedal.o descriptor.o HIDClassDevice.o USBController_AVR8.o USBTask.o Endpoint_AVR8.o EndpointStream_AVR8.o USBInterrupt_AVR8.o DeviceStandardReq.o Events.o
	$(CC) -s $(CFLAGS) -o $@ $^
