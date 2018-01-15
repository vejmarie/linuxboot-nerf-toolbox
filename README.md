# let's nerf your node

This repository does contain O/S level development related to NERF. NERF is the combination of linuxboot and u-root. It is driven by multiple hackers coming from Google, Horizon Computing Solutions and individuals. linuxboot aims to integrate a linux kernel as a UEFI DXE. The goal of the project is to use a simplified linux kernel to initialize low level hardware and improve provisioning process of servers by getting rid of as many UEFI services as we can. u-root is a user space image fully written in Go. Go improve code quality and security by reducing potential memory leak and being a natural multithreaded language. Getting rid of UEFI means low level modification regarding the initialization of host O/S running on top of linuxboot+u-root. You will find in this repo the proof of concept of these modifications that I am writing on my spare time. 

There are many good reasons to get rid of UEFI and rely on an open source low level firmware intialization process. Get in touch with me if you are missing some of them.

## Getting Started

Developing low level firmware and O/S requires an hardware plateform. Most of the code released within this repo is compatible with the Winterfell Dual Xeonv2 compute node issued from the Open Compute Project. This is an aging machine, still quite reliable, low cost, and which perform quite well. It does rely on a 16MB flash to host System BIOS and the stupid ME code far enough to develop O/S support on top of NERF. 

### Prerequisites

You must have a Winterfell node (get in touch with Horizon we can supply you one easily) or you have to know how to use qemu. NERF can be booted on qemu and you can boot on top of that the various installer standing there. Be warned that it is far much more fun to make it run on real hardware. If you have a winterfell machine you need to have a Flash burner as to rewrite the content of your system BIOS. Winterfell is coming with an ME implementation from Intel which is currently prohibiting flashrom to reflash the SPI Flash where the BIOS stands directly from a host O/S. I am working on getting rid of this totally stupid limitation with the linuxboot community but the hack is still something I need to understand. With an external flasher you need UEFITool, flashrom to make a backup of your original BIOS and hack it, as well as the latest release from this repo to boostrap your node. 

I am currently releasing images which works only on Serial Console. The Serial Console is available through the debug port of the server to which you must attach a debug card with an FTDI to USB adapter (3.3v). The speed of the console is 57600bauds by default. Please note that the ubuntu installer provided works fine with minicom as a terminal emulator, do not use screen you will get pure garbage.


### Installing

Installing software from this repo is a 2 steps process. You first need to install NERF within your BIOS. To do that download the nerf.ffs.ttyS0 from the release tree. Make a backup of your Winterfell BIOS with flashrom, open UEFITool, import the backup, look for the AMITSE DXE within the FFSv2 contained into your flash and replace it with nerf.ffs.ttyS0. Save your updated image, and burn it to your flash. Restart your Winterfell with the newly burnt flash. It shall boot straigth forward under a linux prompt.

Download the ubuntu iso file, and "burn" it to a USB stick with the dd command (dd if=ubun...iso of=/dev/sd[my usb device number] bs=4M). Plug the USB stick to the winterfell server. Reset the server as to get linuxboot discovery process run. Enter the boot -dryrun=false command and install ubuntu on your Winterfell machine. I am deploying currently Xenial, I know it is old, but this was the distro I was using when I started this work.

When the installation is done, unplug the stick reboot the server and you are good to go, with a fully functionnal NERFed Winterfell machine running Ubuntu Xenial.

## Running the tests

I don't have (yet) automated test. But you can recompile everything to check that the process works. The NERF image is coming from Guillaume Giamarchi build environment that you can find on his home repo https://github.com/ggiamarchi/nerf-winterfell . My repo contains the build process for Ubuntu Xenial. To launch the build you must make a fresh install of Xenial (16.04.3), the clone my repo, and execute the ./geniso command. Everything is automatized. It will recompile the kernel, the various deb, udeb required to update the ISO installer, and it will have the standard installer to get the relevant deb/udeb updated. Be ware that the whole process takes about 3 hours on a Winterfell machines with 2680v2 processors and 64GB of RAM (when run into a KVM Virtual Machine).

### And coding 

Feel free to help me to support more distros and spread the word. My next step is to support CentOS and netboot on NERFed machines. Most of the code is currently bash scripts (I know that is not super efficient, but it works, we can rewrite everything into a more relevant language if needed)


## Contributing

Clone the repo, send me PR and let's incorporate your code. Please note that the license is GPLv2 and that your code submission must come with this license term

## Authors

* **Jean-Marie Verdun (vejmarie)** - *Initial work* - [vejmarie](https://github.com/vejmarie)

## License

This project is licensed under the GPLv2 License 

## Acknowledgments

* The linuxboot team !
* The u-root team
* Special thanks to Ron Minnich who spent his last 25 years hacking system BIOS

