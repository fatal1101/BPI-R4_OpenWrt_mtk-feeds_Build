# BPI-R4_OpenWrt_mtk-feeds_Build

Build Openwrt with the latest kernel and latest mtk-openwrt-feeds... 

## **To build with the latest kernel and mtk-feeds**

1. You can change branches "openwrt-24.10" , "master" , "main" etc...

2. If you want to build with the latest kernel with the latest mtk commits leave both OPENWRT_COMMIT="" & MTK_FEEDS_COMMIT="" empty.

3. If  you want to target a specific commits use the full commit hash 

4. I have add an optional function to clone from a local repo instead of pointing to the openwrt or mtk-openwrt-feeds repos to clone.
     * saves a lot of time when testing but it is optional, default will clone from the online repos

5. Add two directories to place all patches and files into, one for "openwrt-patches" and the other for all "mtk-patches" 
     * Inside each direcory you drop in all your patches corresponding to the target (openwrt or mtk)
	 * Inside each directory there is two files "openwrt-add-patch" and "openwrt-remove"
	 * To add or remove a file or patch just enter the full target path into the file - target/linux/generic/backport-6.6/999-some.patch
	 * The script will search each file at the start of the build and process all entries and apply them to the targeted locations.. or remove
	 
6. You can use custom config files and scripts. 
	 * Add any custom wireless, network config files to "/files/etc/config/" directory and it will be included into the built image.
	 * Add any custom uci-defaults script into "openwrt-patches/files/etc/uci-defaults/" and it will be built into the image.

7. Added an option at the end of a successfully build, that will prompt the usre if they want to enter into "make menuconfig".. optional
     * When prompted either enter (yes/no): The default is 'no' or let it time out after 10 seconds and it will continue and existing the script.
	 * If 'yes' enter into the make menuconfig and make the changes you need and save, it will continue the build process and build a new images with your changes.

8. Error Checks - All scripts and patches will be auto chacked with dos2unix and corrected if needed. 

9. Permissions - All scripts, patches and folders used will have the correct permissins applied during the build process.

## **How to Use**

1. **Prerequisites**: A Compatible build environment, such as **Ubuntu 24.04 LTS**. You will also need to install `dos2unix` & `rsync`:
   
   `sudo apt update`  
   `sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib 
   gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev
   file wget dos2unix rsync`

2. **Clone repo**:

   `git clone https://github.com/Gilly1970/BPI-R4_OpenWrt_mtk-feeds_Build.git`
   
   `sudo chmod 775 -R mtk-openwrt_build.sh`

3. **Run the Script**:  
   * Make the script executable:  
     <sup>chmod \+x mtk-openwrt_build.sh</sup>
     
   * Execute the script:  
     <sup>./mtk-openwrt_build.sh</sup>

## **Notes**
Please note - Using the latest kernels with the mtk-feeds can be unstable and problematic using them on a main router.


