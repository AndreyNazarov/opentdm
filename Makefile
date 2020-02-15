### OpenTDM Makefile ###

CONFIG_FILE ?= .config

-include $(CONFIG_FILE)

ifndef CPU
    CPU := $(shell uname -m | sed -e s/i.86/i386/ -e s/amd64/x86_64/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/)
endif

ifndef REV
    REV := $(shell git rev-list --count HEAD)
endif

ifndef VER
    VER := r$(REV)~$(shell git rev-parse --short HEAD)
endif

CC ?= gcc
WINDRES ?= windres
STRIP ?= strip
RM ?= rm -f

CFLAGS ?= -O2 -g -Wall -Wno-unused -MMD $(INCLUDES)
LDFLAGS ?= -shared
LIBS ?=

ifdef CONFIG_WINDOWS
    LDFLAGS += -mconsole
    LDFLAGS += -Wl,--nxcompat,--dynamicbase
else
    CFLAGS += -fPIC -fvisibility=hidden
    LDFLAGS += -Wl,--no-undefined
endif

ifndef CONFIG_X86_NO_SSE_MATH
    ifeq ($(CPU),x86)
        CFLAGS += -msse2 -mfpmath=sse
    endif
    ifeq ($(CPU),i386)
        CFLAGS += -msse2 -mfpmath=sse
    endif
endif

CFLAGS += -DC_ONLY
CFLAGS += -DOPENTDM_VERSION='"$(VER)"' -DOPENTDM_REVISION=$(REV)
RCFLAGS += -DOPENTDM_VERSION='\"$(VER)\"' -DOPENTDM_REVISION=$(REV)

ifdef CONFIG_HTTP
    CURL_CFLAGS ?= $(shell pkg-config libcurl --cflags)
    CURL_LIBS ?= $(shell pkg-config libcurl --libs)
    CFLAGS += -DHAVE_CURL $(CURL_CFLAGS)
    LIBS += $(CURL_LIBS)
endif

OBJS := g_chase.o g_cmds.o g_combat.o g_func.o g_items.o g_main.o g_misc.o \
g_phys.o g_save.o g_spawn.o g_svcmds.o g_target.o g_tdm_client.o g_tdm_cmds.o \
g_tdm_core.o g_tdm_curl.o g_tdm_macros.o g_tdm_stats.o g_tdm_vote.o g_trigger.o \
g_utils.o g_weapon.o mt19937.o p_client.o p_hud.o p_menu.o p_view.o p_weapon.o \
g_tdm_votemenu.o q_shared.o

ifdef CONFIG_WINDOWS
    OBJS += sys_win32.o
    OBJS += opentdm.o
    ifdef CONFIG_HTTP
        LIBS += -lws2_32
    endif
    TARGET := game$(CPU).dll
else
    OBJS += sys_linux.o
    LIBS += -lm
    TARGET := game$(CPU).so
endif

all: $(TARGET)

default: all

.PHONY: all default clean strip

# Define V=1 to show command line.
ifdef V
    Q :=
    E := @true
else
    Q := @
    E := @echo
endif

-include $(OBJS:.o=.d)

%.o: %.c
	$(E) [CC] $@
	$(Q)$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.rc
	$(E) [RC] $@
	$(Q)$(WINDRES) $(RCFLAGS) -o $@ $<

$(TARGET): $(OBJS)
	$(E) [LD] $@
	$(Q)$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	$(E) [CLEAN]
	$(Q)$(RM) *.o *.d $(TARGET)

strip: $(TARGET)
	$(E) [STRIP]
	$(Q)$(STRIP) $(TARGET)

