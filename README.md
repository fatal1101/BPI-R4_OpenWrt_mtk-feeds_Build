# BPI-R4_OpenWrt_mtk-feeds_Build

Build with the latest Openwrt kernels and the latest mtk-openwrt-feeds...

This is my latest build script which incorperates the "rsync" function to improve the handling of scripts and patches. I've also include a new option to clone the main repos from a local repo. 

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
   
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev python3-setuptools swig unzip zlib1g-dev file wget dos2unix rsync`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_OpenWrt_mtk-feeds_Build.git`
   
   `sudo chmod 775 -R BPI-R4_OpenWrt_mtk-feeds_Build`

3. **Run the Script**:  
   * Make the script executable:  
     `chmod +x mtk-openwrt_build.sh`
     
   * Execute the script:  
     `./mtk-openwrt_build.sh`
	 
### **For latest compiled bpi-r4 sysupgradeb/sdcard images can be downloaded from mediafire..**

Images with the eeprom patch applied.. I've removed mld from the wireless config in this image due to the current driver issue with mld.
Images for BE14 with the eeprom issue - https://www.mediafire.com/file/46qk77uoh2davtd/BPI_R4_Images-with-eeprom-fix-19.09.2025.zip

Standard images with no eeprom patched with mld..
Images for BE14 without the eeprom issue - https://www.mediafire.com/file/61h5fw875hzzz54/BPI_R4_Images-with-no-eeprom-fix-19.09.2025.zip

## **Notes**

Updated patch to "0130-mtk-mt76-mt7996-fix-kernel-6.104-EEPROM-0s.patch" 

Mediatek are now deleting all patches in the "openwrt/package/kernel/mt76/patches/" directory, unless they follow the correct mtk patch format. I've renamed this patch to follow this new format which stops it from being auto removed from the build.











