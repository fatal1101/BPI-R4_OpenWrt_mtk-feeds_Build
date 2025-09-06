# BPI-R4_OpenWrt_mtk-feeds_Build

Build Openwrt with the latest kernel and the latest mtk-feeds...

I have been playing around testing different methods of adding and removing patches and files without having to modify the main script itself, to try and make the process as simple as posible.

Anyway, I have ended up with this method after trying various others ways, including using patch itself to automate, but it was getting way to complex going down that rabit hole. 

So back to basics it is and this is what I end up with.. 

# **To build with the latest kernel and mtk-feeds**

1. You can change branches "openwrt-24.10" , "master" , "main" etc...

2. If you want to build with the latest kernel and mtk commits leave both OPENWRT_COMMIT="" & MTK_FEEDS_COMMIT="" empty, or you can set specific commits with the full commit hash.

3. I have add an optional function to clone from a local repo instead of pointing to the openwrt or mtk-openwrt-feeds repos to clone.
     * saves a lot of time when testing but it is optional and by default will clone from the online repos

4. Add two directories to place all patches and files into, one for "openwrt-patches" and the other for all "mtk-patches" 
     * Inside each direcory you drop in all your patches in to the corresponding target (openwrt or mtk)
	 * Inside each directory there is two files "openwrt-add-patch" and "openwrt-remove"
	 * To add or remove a file or a patch to the build just enter the full target path into the file - target/linux/generic/backport-6.6/999-some.patch
	 * The script will seach each file at the start of the build and process all entries and apply them to the targets entered.. or remove
	 
5. You can use custom config files and scripts. 
	 * Add any custom wireless, network config files to "/files/etc/config/wireless" and it will be included in the built image.
	 * Add any custom uci-defaults script into "openwrt-patches/files/etc/uci-defaults/" and it will be built into the image.

6. Added an option at the end of a successfully build, that prompt the usre if they want to enter into "make menuconfig" to add what ever packages or changes you need.
     * When prompted either enter (yes/no): The default is 'no' or let it time out after 10 seconds and it will continue and existing the script.
	 * If 'yes' enter into the make menuconfig and make the changes you need and save, it will continue the build process with and build new images with your changes changes.

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
   
   `sudo chmod 775 -R mtk-openwrt_build.sh`

3. **Run the Script**:  
   * Make the script executable:  
     `chmod \+x mtk-openwrt_build.sh`
     
   * Execute the script:  
     `./mtk-openwrt_build.sh`

## **Notes**
Please note - Using the latest kernels with the mtk-feeds can be unstable and problematic using them on a main router.


