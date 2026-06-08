#!/bin/bash
set -euo pipefail

# BPI-R4 Pro 8X - NAND rescue builder
# Produces: openwrt-mediatek-filogic-bananapi_bpi-r4-pro-snand-img.bin
# Run on Ubuntu VM, commit result to rescue/ directory.

rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-25.12 https://github.com/openwrt/openwrt.git openwrt
cd openwrt; git checkout 13ff2256e5dd9bc070f9a9c6a673bff4a9191837; cd -;

tar xzf /home/ipsec/mtk-feeds-cache.tar.gz

cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic prepare

scripts/feeds uninstall crypto-eip pce tops-tool

# BPI-R4 patches
\cp -r ../my_files/453-w-add-bpi-r4-nvme-dtso.patch target/linux/mediatek/patches-6.12/
\cp -r ../my_files/455-w-add-bpi-r4-pro-nvme-dtso.patch target/linux/mediatek/patches-6.12/
\cp -r ../my_files/450-w-nand-mmc-add-bpi-r4.patch package/boot/uboot-mediatek/patches/450-add-bpi-r4.patch
\cp -r ../my_files/451-w-add-bpi-r4-nvme.patch package/boot/uboot-mediatek/patches/451-add-bpi-r4-nvme.patch
\cp ../my_files/452-w-add-bpi-r4-nvme-rfb.patch package/boot/uboot-mediatek/patches/452-add-bpi-r4-nvme-rfb.patch
\cp ../my_files/454-w-add-bpi-r4-nvme-env.patch package/boot/uboot-mediatek/patches/454-add-bpi-r4-nvme-env.patch

# BPI-R4-Pro-8x patches
\cp -r ../my_files/bpi-r4-pro/patches-kernel/* target/linux/mediatek/patches-6.12/
\cp ../my_files/bpi-r4-pro/patches-uboot/471-add-bpi-r4-pro-8x.patch package/boot/uboot-mediatek/patches/
#\cp ../my_files/bpi-r4-pro/patches-uboot/472-add-bpi-r4-pro-8x-makefile.patch package/boot/uboot-mediatek/patches/
\cp ../my_files/bpi-r4-pro/uboot-mediatek-Makefile package/boot/uboot-mediatek/Makefile
\cp ../my_files/bpi-r4-pro/arm-trusted-firmware-mediatek-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
\cp -r ../my_files/w-sd-nand-mmc-nvme-ddr4-filogic.mk target/linux/mediatek/image/filogic.mk
mv target/linux/mediatek/image/filogic-extra.mk target/linux/mediatek/image/filogic-extra.mk.disabled

echo "CONFIG_BLK_DEV_NVME=y" >> target/linux/mediatek/filogic/config-6.12
echo "CONFIG_TASK_IO_ACCOUNTING=y" >> target/linux/mediatek/filogic/config-6.12
python3 -c 'content=open("package/kernel/linux/modules/netdevices.mk").read(); content=content.replace("  KCONFIG:=CONFIG_AS21XXX_PHY\n  FILES:= \\\n   $(LINUX_DIR)/drivers/net/phy/as21xxx.ko\n  AUTOLOAD:=$(call AutoLoad,18,as21xxx)", "  FILES:= \\\n   $(LINUX_DIR)/drivers/net/phy/aeon_as21xxx.ko\n  AUTOLOAD:=$(call AutoLoad,18,aeon_as21xxx)"); open("package/kernel/linux/modules/netdevices.mk","w").write(content)'
python3 -c 'content=open("target/linux/mediatek/filogic/config-6.12").read(); content=content.replace("CONFIG_AS21XXX_PHY=y", "CONFIG_AS21XXX_PHY=m"); open("target/linux/mediatek/filogic/config-6.12","w").write(content)'

\cp -r ../my_files/999-fitblk-02-w-add-bpi-r4-nvme-fitblk.patch target/linux/mediatek/patches-6.12


mkdir -p files/root/bpi-r4-install
\cp ../my_files/bpi-r4-install/install-emmc.sh files/root/bpi-r4-install/
chmod +x files/root/bpi-r4-install/install-emmc.sh
\cp ../my_files/bpi-r4-install/install-nvme.sh files/root/bpi-r4-install/
chmod +x files/root/bpi-r4-install/install-nvme.sh
\cp ../my_files/bpi-r4-install/install-nvme-unifi.sh files/root/bpi-r4-install/
chmod +x files/root/bpi-r4-install/install-nvme-unifi.sh

mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-hostname << 'EOF'
uci set system.@system[0].hostname='BPI-R4-Pro-8X-NAND-rescue'
uci commit system
EOF
\cp -r ../my_files/99-pro-8x-network files/etc/uci-defaults/
chmod +x files/etc/uci-defaults/99-pro-8x-network

\cp -r ../configs/my_defconfig-8x-rescue .config
make defconfig

echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-emmc-comb-4bg=y" >> .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-sdmmc-comb-4bg=y" >> .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-spim-nand-ubi-comb-4bg=y" >> .config

bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic build
