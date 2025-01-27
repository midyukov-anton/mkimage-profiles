# step 4 is kicked off here but actually done by image.in/Makefile
ANSI_OK   ?= 1;32
ANSI_FAIL ?= 1;31

MAX_LINES = 200
MAX_ERRORS = 5
GOTCHA := ^(((\*\* )?(E:|[Ee]rror|[Ww]arning).*)|(.* (FAILURE|FATAL|ERROR|conflicts|Conflicts:|Depends:) .*)|(.* (Stop|failed|not found)\.)|(not allowed))$$

ifndef MKIMAGE_PROFILES
$(error this makefile is designed to be included in toplevel one)
endif

# try not to bog down the system, both CPU and I/O wise
ifdef NICE
START := nice $(shell ionice -c3 echo "ionice -c3" 2>/dev/null)
endif

# in kilobytes (a kilometer is 1024 meters, you know)
LOWSPACE = 1024

# it's also nice to know how long and much it takes
START += time -f "%E %PCPU %Mk"

# e2k* builds always run natively, and without setarch
ifneq (,$(findstring e2k,$(ARCH)))
USE_QEMU := 0
else
USE_QEMU ?= 1
endif

ifeq ($(USE_QEMU),1)

# /usr/bin/{i586,x86_64} are setarch(8) symlinks but arm is not;
# armh (armv7l) doesn't have any but should cope with qemu-arm.static;
# also check whether non-x86 build is running native
ifeq (,$(wildcard $(subst :,/$(ARCH) ,$(PATH):)))

EARCH := $(subst armh,arm,$(ARCH))

# for mips*el, `uname -m` never has 'el' suffix, but
# qemu-user-static binaries always do.
UARCH := $(subst mipsel,mips,$(EARCH))
UARCH := $(subst mips64el,mips64,$(UARCH))

ifeq (,$(findstring $(UARCH),$(shell uname -m)))
export GLOBAL_HSH_USE_QEMU=$(EARCH)
endif
else
START += $(ARCH)
endif
endif


# to be passed into distcfg.mk; suggestions are welcome
ifneq (,$(filter-out $(DIRECT_TARGETS),$(MAKECMDGOALS)))
IMAGEDIR ?= $(shell \
	if [ -d "$$HOME/out" -a -w "$$HOME/out" ]; then \
		echo "$$HOME/out"; \
	else \
		dir="`dirname $(BUILDDIR)`/out"; \
		mkdir -p "$$dir" && echo "$$dir" || echo "/tmp"; \
	fi; \
)
endif

LOGDIR ?= $(wildcard $(IMAGEDIR))

make-aptbox: ; @:
ifneq (0,$(CHECK))
	@mkdir -p $(BUILDDIR)/.work/pkgbox; \
	mkdir -p $(BUILDDIR)/.work/.cache; \
	mkdir -p $(BUILDDIR)/.work/.out; \
	APTCONF=$(wildcard $(APTCONF)); \
	mkaptbox --without-stuff --target=$(ARCH) $${APTCONF:+--apt-config=$$APTCONF} -- $(BUILDDIR)/.work/pkgbox
endif

# actual build starter
# NB: our output MUST go into stderr to escape POSTPROC
build-image: make-aptbox profile/populate
	@{ \
	if [ -n "$(CHECK)" ]; then \
		echo "$(TIME) skipping actual image build (CHECK is set)"; \
		exit; \
	fi; \
	if [ -z "$(QUIET)" ]; then \
		echo -n "$(TIME) starting image build"; \
		if [ -n "$(DEBUG)" ]; then \
			echo ": tail -f $(BUILDLOG)" $(SHORTEN); \
		else \
			echo " (coffee time)"; \
		fi; \
	fi; \
	if $(START) $(MAKE) -C $(BUILDDIR)/ $(LOG); then \
		DURATION="(`tail -1 $(BUILDLOG) | cut -f1 -d.`)"; \
		tail -n $(MAX_LINES) "$(BUILDLOG)" $(SHORTEN) \
		| if [ -z "$(QUIET)" ]; then \
			echo "$(TIME) done $$DURATION"; \
			GREP_COLOR="$(ANSI_OK)" \
			  grep --color=auto '^\*\* image: .*$$' ||:; \
		else \
			echo -n "$(TIME) $$DURATION "; \
			sed -rn 's/^\*\* image: (.*)$$/\1/p'; \
		fi; \
		RETVAL=0; \
	else \
		RETVAL=$$?; \
		echo -n "$(TIME) failed, see log"; \
		if [ -z "$(DEBUG)" -o -n "$(QUIET)" ]; then \
			echo ": $(BUILDLOG)" $(SHORTEN); \
		else \
			echo " above"; \
		fi; \
		if [ -z "$(DEBUG)" ]; then \
			echo "$(TIME) (you might want to rerun with DEBUG=1)"; \
		fi; \
		tail -n $(MAX_LINES) "$(BUILDLOG)" \
		| GREP_COLOR="$(ANSI_FAIL)" \
		  egrep --color=auto -m "$(MAX_ERRORS)" "$(GOTCHA)"; \
		df -P $(BUILDDIR) | awk 'END { if ($$4 < $(LOWSPACE)) \
			{ print "NB: low space on "$$6" ("$$5" used)"}}'; \
	fi; \
	if [ -n "$(BELL)" ]; then echo -ne '\a'; fi; \
	exit $$RETVAL; \
	} >&2
