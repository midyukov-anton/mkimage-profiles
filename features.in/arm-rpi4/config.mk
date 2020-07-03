ifeq (,$(filter-out aarch64 armh,$(ARCH)))
use/arm-rpi4: use/bootloader/uboot
	@$(call add_feature)
	@$(call add,THE_PACKAGES,u-boot-tools)
	@$(call add,THE_PACKAGES,rpi4-boot-switch)
	@$(call add,THE_PACKAGES,rpi4-boot-nouboot-filetrigger)
	@$(call add,THE_PACKAGES,rpi4-boot-uboot-filetrigger)
	@$(call add,THE_PACKAGES,firmware-bcm4345)
	@$(call add,THE_PACKAGES,brcm-patchram-plus)
	@$(call add,THE_PACKAGES,rpi4-resize-rootpart)
	@$(call add,DEFAULT_SERVICES_ENABLE,attach-bluetooth)

endif