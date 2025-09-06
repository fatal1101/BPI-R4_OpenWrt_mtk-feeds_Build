# BPI-R4_OpenWrt_mtk-feeds_Build

Build Openwrt with the latest kernel and the latest mtk-feeds...

This build sctipt is in the experimental stage and very similar to the SnapShot Build Script, which find and sets the latest commits on both the openwrt and the mtk-feeds.

# **To build with the latest kernel and mtk-feeds**

1. You can change branches "openwrt-24.10" , "master" , "main" etc...

2. If you want to build with the latest commits leave both OPENWRT_COMMIT="" & MTK_FEEDS_COMMIT="" empty, or you can specific commits, with the full hash.

3. Created a new "openwrt-patches" and "mtk-patches" directories which all patches and files in the correct dir tree will be applied to the build.. 
     * e.g.. "openwrt-patches/target/linux/mediatek/patches-6.6/some.patch" will be applied to the "openwrt/target/linux/mediatek/patches-6.6/some.patch" directory.
     * If you want to remove a patch just remove it fron the openwrt-patches directory.. e.g. "openwrt-patches/target/linux/mediatek/patches-6.6/some.patch".
	 * Add any custom wireless, network config files to "openwrt-patches/files/etc/config/wireless" and it will be included in the built image.
	 * Add any custom uci-defaults script into "openwrt-patches/files/etc/uci-defaults/" and it will be built into the image.

4. You can place any custom .config files in side the "config" directory to use.

5. If you want to remvoe a patch or file from the build place it in the "openwrt-patches-remove" or "mtk-patches-remove" dir and it will be removed from the build..
     * e.g.. "mtk-patches-remove/24.10/patches-feeds/108-strongswan-add-uci-support.patch" and it will be removed from the "mtk-feeds/21.02/patches-feeds/" directory.
	 * e.g.. "openwrt-patches-remove/24.10/patches-feeds/some.patch" and it will be removed from the "openwrt//24.10/patches-feeds/" directory.

6. Added an option that prompt the usre during the build process to use the "make menuconfig" to add what ever packages or changes you need.
     * When prompted either enter (yes/no): The default is 'no' or let it time out after 10 seconds and it will continue use the existing .config in the config folder.
	 * If 'yes' enter into the make menuconfig and make the changes you need and save, it will continue the build process with your new .config changes.
	 * A new .config.new file will be saved in the config directory.. To make it the default config to use for your next build, just rename it from .config.new to .config

7. Error Checks - All scripts and patches will be auto chacked with dos2unix and corrected if needed. 

8. Permissions - All scripts, patches and folders used will have the correct permissins applied during the build process.

## **How to Use**

1. **Prerequisites**: Ensure you have a compatible build environment, such as **Ubuntu 24.04 LTS**. You will also need to install `dos2unix` & `rsync`:  
   `sudo apt update`
   
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \\`
   
   `gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev \\`
   
   `file wget dos2unix rsync`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_OpenWrt_mtk-feeds_Build.git`
   
   `sudo chmod 776 -R mtk-openwrt_build.sh`

3. **Run the Script**:  
   * Make the script executable:  
     `chmod \+x mtk-openwrt_build.sh`
     
   * Execute the script:  
     `./mtk-openwrt_build.sh`

## **Notes**
Please note - Using the latest kernels with the mtk-feeds can be unstable and problematic using them on a main router.


