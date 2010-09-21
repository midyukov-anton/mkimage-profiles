# build up distribution's configuration
#
# NB: distro/ targets should be defined here,
# see toplevel Makefile's $(DISTRO) assignment
CONFIG = $(BUILDDIR)/.config.mk

# source initial feature snippets
-include features.in/*/config.mk

# put(), add(), set(), tags()
#
# package list names are considered relative to pkg/lists/
#
#  $(VAR) will be substituted before writing them to $(CONFIG);
# $$(VAR) will remain unsubstituted util $(CONFIG) is included
#         and their value requested (so the variable referenced
#         can change its value during configuration _before_
#         it's actually used)
#
# tags can do boolean expressions: (tag1 && !(tag2 || tag3))
include functions.mk

# request particular image subprofile inclusion
sub/%:
	@$(call add,SUBPROFILES,$(@:sub/%=%))

distro/init:
	@echo "** starting distro configuration build process"
	@:> $(CONFIG)

distro/base: distro/init sub/stage1 use/syslinux use/syslinux/localboot.cfg
	@$(call set,KFLAVOUR,std-def)
	@$(call set,IMAGE_INIT_LIST,+branding-$$(BRANDING)-release)
	@$(call set,BRANDING,altlinux-desktop)	###
	@$(call set,KERNEL_PACKAGES,kernel-image-$$(KFLAVOUR))

distro/installer: distro/base sub/install2 use/syslinux/install2.cfg
	@#$(call put,BRANDING=altlinux-sisyphus)	###
	@$(call set,BASE_LISTS,base kernel)
	@$(call set,INSTALL2_PACKAGES,installer-distro-server-light-stage2)	###

distro/server-base: distro/installer sub/main use/syslinux/ui-menu use/memtest
	@$(call add,BASE_LISTS,server-base kernel-server)

distro/server-light: distro/server-base use/hdt
	@$(call set,KFLAVOUR,ovz-smp)	# override default
	@$(call set,BRANDING,sisyphus-server-light)
	@$(call add,DISK_LISTS,kernel-wifi)
	@$(call add,BASE_LISTS,$(call tags,base server))
	@$(call add,GROUPS,dns-server http-server ftp-server kvm-server)
	@$(call add,GROUPS,ipmi mysql-server dhcp-server mail-server)
	@$(call add,GROUPS,monitoring diag-tools)

# bootloader test target
distro/syslinux: distro/base use/syslinux/ui-gfxboot \
		 use/hdt use/memtest boot/isolinux

boot/%: distro/init
	@$(call set,BOOTLOADER,$*)
