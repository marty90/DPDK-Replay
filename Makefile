ifeq ($(RTE_SDK),)
$(error "Please define RTE_SDK environment variable")
endif

# Default target, can be overriden by command line or environment
RTE_TARGET ?= x86_64-native-linuxapp-gcc

include $(RTE_SDK)/mk/rte.vars.mk

LDLIBS = -lpcap -lpthread -lm
#LDFLAGS = -Wl,--rpath -Wl,/usr/local/lib

# binary name
APP = dpdk-replay

# all source are stored in SRCS-y
SRCS-y := src/main_replay_copy_2_cores.c 

CFLAGS += -O3
#CFLAGS += -g
#CFLAGS += $(WERROR_FLAGS)

include $(RTE_SDK)/mk/rte.extapp.mk



