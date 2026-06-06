#!/usr/bin/env python3
# Fix AS21XXX_PHY: filogic config forces =y (built-in), must be =m for kmod packaging
p = "target/linux/mediatek/filogic/config-6.12"
t = open(p).read()
open(p, "w").write(t.replace("CONFIG_AS21XXX_PHY=y", "CONFIG_AS21XXX_PHY=m"))
print("AS21XXX_PHY: y -> m")
