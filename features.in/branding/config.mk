# NB: release part of branding goes to install2 feature
use/branding:
	@$(call add_feature)

# license notes, if any
use/branding/notes: use/branding
	@$(call add,THE_BRANDING,notes)

# NB: not every distro might have all the branding of its own
use/branding/full: use/branding/notes use/syslinux/ui/gfxboot \
	use/grub/ui/gfxboot
	@$(call add,THE_BRANDING,alterator bootloader graphics)
	@$(call add,THE_BRANDING,indexhtml slideshow)
ifeq (,$(filter-out i586 x86_64,$(ARCH)))
	@$(call add,THE_BRANDING,bootsplash)
endif

use/branding/complete: use/branding/full use/plymouth/full
	@$(call add,INSTALL2_BRANDING,notes slideshow)

# http://altlinux.org/branding/slideshow
use/branding/slideshow/once: use/branding
	@$(call add,INSTALL2_BRANDING_SLIDESHOW,once:true)
	@$(call xport,INSTALL2_BRANDING_SLIDESHOW)
