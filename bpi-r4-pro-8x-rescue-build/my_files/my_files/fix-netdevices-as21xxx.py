#!/usr/bin/env python3
# Fix: Kbuild generates aeon_as21xxx.ko, not as21xxx.ko
p = "package/kernel/linux/modules/netdevices.mk"
lines = open(p).readlines()
new = [l.replace("as21xxx.ko", "aeon_as21xxx.ko") if "as21xxx.ko" in l else l for l in lines]
open(p, "w").writelines(new)
print("netdevices.mk: as21xxx.ko -> aeon_as21xxx.ko")
