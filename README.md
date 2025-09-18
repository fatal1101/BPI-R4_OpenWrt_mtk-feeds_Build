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

Images for BE14 without the eeprom issue - https://www.mediafire.com/file/tkrt60a2nig7ke8/BPI_R4_Images-with-no-eeprom-fix-13.09.2025.zip

Images for BE14 with the eeprom issue - https://www.mediafire.com/file/dpm3s39j2satbxm/BPI_R4_Images-with-eeprom-patch-13.09.2025.zip

## **Notes**

Testing the new "99999-mt7996-eeprom-fix-0s.patch" is now complete and I can confim this new patch works.. While testing the new patch I was getting some strange behaviour..

1. - On first boot after loading the new image the maximum transmit power was only showing one value e.g : `255 dBm (2147483647 mW)`

2. - First reboot - This garbage value would disaper after and the Maximum transmit power drop down menu would populate with the correct values

3. - When setting the Maximum transmit power to e.g : 17dBm and saving, the garbage value: `255 dBm (2147483647 mW)` would return.

4. - After another reboot this would correct and the Maximum transmit power would show correctly as `17dBm` but the current power would show full power e.g `27 dBm`

The Chain of Evidence in the Logs

5. hostapd Fails on MLD
The most direct clue is this error from hostapd

`daemon.err hostapd: MLD: Failed to re-add link 4 in MLD ap-mld-1`
This is a specific, fatal error showing that hostapd is failing while trying to manage the multiple links (the "M" in MLD) for the single MLD interface (ap-mld-1).

6. hostapd Fails to Set the Channel
Because the driver is now in a confused state after the MLD error, it starts refusing basic commands. This leads to the second key error, which repeats endlessly:

`daemon.err hostapd: nl80211: Frequency set failed: -1 (Operation not permitted)`
This is hostapd trying to set the channel for one of the APs, but the driver is rejecting the command. This is a direct consequence of the initial MLD setup failure.

7. netifd is Stuck in a Loop
The log shows netifd repeatedly trying to tear down and restart my Wi-Fi interfaces. For example:

`daemon.notice hostapd: Restart interface for phy phy0.2`
This happens because netifd sees that hostapd failed (due to the errors above) and its response is to try and restart the entire process, which leads back to Step 1, creating the infinite loop.

The Definitive Proof
The most powerful piece of evidence is when I removed the MLD configuration from my /etc/config/wireless file, the problem goes away completely.

The Final Diagnosis
The root cause of all the strange `255 dBm (2147483647 mW)` garbage value, the empty drop-down menu, and the netifd instability is a bug in the mt76 driver's Multi-Link Operation (MLD) code.

My faulty BE14 containing 0s was the first problem, which this new kernel patch fixes. But that fix then exposed this second, deeper bug in the Wi-Fi 7 driver's. By removing the MLD configuration, I successfully bypassing that bug and the patch works perfectly.

Bad news for those with the really bad BE14 cards, currently while you have mld configured in your wireless config, no patch will fix this issue, until the deeper bug in the Wi-Fi 7 driver's is fixed first.

Good news is if your happey with no mld then this patch works perfectly, and once the current bug with the Wi-Fi 7 mld driver is fixed it will work perfectly for mld as well.









