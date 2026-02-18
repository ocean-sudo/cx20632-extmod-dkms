obj-m += snd-hda-codec-conexant.o
snd-hda-codec-conexant-y := conexant.o
ccflags-y += -I$(src)

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

.PHONY: all modules clean

all: modules

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
