# BPI-R4_OpenWrt_mtk-feeds_Build

Build with the latest Openwrt kernels and the latest mtk-openwrt-feeds...

This is my latest evolving build script which incorperates the "rsync" function to improve the handling of scripts and patches. I've also include a new option to clone the main repos from a local repo. 

## **To build with the latest kernel and mtk-openwrt-feeds**

1. You can change branches "openwrt-24.10" , "master" , "main" etc...

2. If you want to build with the latest openwrt-24.10 kernels and the latest mtk commits leave both OPENWRT_COMMIT="" & MTK_FEEDS_COMMIT="" empty.

3. If you want to target a specific commit use the full commit hash e.g... OPENWRT_COMMIT="b4b9288f2aa3dd1a759e5effbc8378f614bd5755"

4. I've add an optional function to clone from a local repo instead of pointing to the openwrt or mtk-openwrt-feeds repos to clone.
	* saves a lot of time when testing but it's optional, default will clone from the online repos
	 * I've added a new repo with a small shell script to automate the updating of both "openwrt" and "mtk-openwrt-feeds" local repositories, to keep them up to date.

5. Added two new directories to place all patches and files into, one for "openwrt-patches" and the other for all "mtk-patches" 
	 * Inside each direcory you drop in all your patches corresponding to the target (openwrt or mtk)
	 * Inside each directory there is two files "openwrt-add-patch" and "openwrt-remove"
	 * To add or remove a file or patch just enter the full target path into the file - target/linux/generic/backport-6.6/999-some.patch
	 * The cp -f function works likes this.. "Some-Makefile:package/base-files/Makefile"
	 * The mkdir -p function works like this.. Add the tree with the new dir  "Some-script.sh:files/etc/uci-defaults/new.sh" or "files/etc/uci-defaults/new.sh" in the correct add file.
	 * The script will search each of the files at the start of the build and process all entries applying them to the targets.. (or removing them)
	 
6. You can use custom config files and scripts. 
	 * Add any custom wireless, network config files to "/files/etc/config/" directory and it will be included into the built image.
	 * Add any custom uci-defaults script into "openwrt-patches/files/etc/uci-defaults/" and it will be built into the image.

7. Added an option at the end of a successfully build, that will prompt the usre if they want to enter into "make menuconfig".. 
	 * When prompted either enter (yes/no): The default is 'no' or let it time out after 10 seconds and it will continue and existing the script.
	 * If 'yes' enter into the make menuconfig and make the changes you need and save, it will continue the build process and build a new images with your custom changes.

8. Error Checks - All scripts and patches will be auto chacked with dos2unix and corrected if needed. 

9. Permissions - All scripts, patches and folders used will have the correct permissins applied during the build process.

## **How to Use**

1. **Prerequisites**: Ensure you have a compatible build environment, such as **Ubuntu 24.04 LTS**. You will also need to install `dos2unix` & `rsync`:  
   `sudo apt update` 
   
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget dos2unix rsync`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_OpenWrt_mtk-feeds_Build.git`
   
   `sudo chmod 775 -R mtk-openwrt_build.sh`

3. **Run the Script**:  
   * Make the script executable:  
     `chmod +x mtk-openwrt_build.sh`
     
   * Execute the script:  
     `./mtk-openwrt_build.sh`

## **Notes**
Please Note - The "99999-mt7996-eeprom-fix-0s.patch" is my own modified version of both the "99999_tx_power_check.patch" & "9997-use-tx_power-from-default-fw-if-EEPROM-contains-0s.patch" patches.. I've combined the same logic from both patches and applied it into the one patch.

root@OpenWrt:~# dmesg | grep mt7996
[    5.359751] FIT:          flat_dt sub-image 0x00685000..0x006858f0 "fdt-mt7988a-bananapi-bpi-r4-wifi-mt7996a" (ARM64 OpenWrt bananapi_bpi-r4 device tree overlay mt7988a-bananapi-bpi-r4-wifi-mt7996a)
[   14.564927] mt7996e_hif 0001:01:00.0: assign IRQ: got 124
[   14.570344] mt7996e_hif 0001:01:00.0: enabling device (0000 -> 0002)
[   14.576722] mt7996e_hif 0001:01:00.0: enabling bus mastering
[   14.582486] mt7996e 0000:01:00.0: assign IRQ: got 121
[   14.587545] mt7996e 0000:01:00.0: enabling device (0000 -> 0002)
[   14.593556] mt7996e 0000:01:00.0: enabling bus mastering
[   14.684236] mt7996e 0000:01:00.0: attaching wed device 0 version 3.0
[   14.815063] mt7996e_hif 0001:01:00.0: attaching wed device 1 version 3.0
[   15.144509] mt7996e 0000:01:00.0: HW/SW Version: 0x8a108a10, Build Time: 20250904203308a
[   15.250373] mt7996e 0000:01:00.0: WM Firmware Version: ____000000, Build Time: 20250904203304
[   15.295309] mt7996e 0000:01:00.0: DSP Firmware Version: ____000000, Build Time: 20250904202814
[   15.316818] mt7996e 0000:01:00.0: WA Firmware Version: ____000000, Build Time: 20250904203218
[   16.208804] mt7996e 0000:01:00.0: corrupted EEPROM detected, forcing default
[   16.232865] mt7996e 0000:01:00.0: registering led 'mt76-phy0'
[   31.777052] mt7996e 0000:01:00.0: Platform_type = 2, bypass_rro = 1, txfree_path = 0
[   36.642242] mt7996e 0000:01:00.0 phy0.1-ap0: entered allmulticast mode
[   36.648927] mt7996e 0000:01:00.0 phy0.1-ap0: entered promiscuous mode
[   36.795098] mt7996e 0000:01:00.0: mt76_add_chanctx: add 100 on mt76 band 1




