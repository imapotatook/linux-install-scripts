#!/bin/bash

function ascii {
	#Added ASCII Art cause why not                                                                                        
	echo	' HI COOK :)     '
}

function cont {
	read -r -p "[SUCCESS] Continue to next step? [Y/n] " cont
	case $cont in
		[Nn][oO]|[nN] )
			exit
			;;
		*)
			;;
	esac
}

function set-time {
	echo "Setting time...."
	rc-service ntpd start
}

function partition {
	read -r -p "Do you want to do partioning? [y/N] " resp
	case "$resp" in
		[yY][eE][sS]|[yY])
			echo "gdisk will be used for partioning"
			read -r -p "which drive you want to partition (exapmle /dev/sda)? " drive
			# Using gdisk for GPT, if you want to use MBR replace it with fdisk
			cfdisk "$drive"
			;;
		*)
			;;
	esac
	cont
}

function mounting {
	read -r -p "which is your root partition? " rootp
	mkfs.btrfs -f "$rootp"
	mount "$rootp" /mnt
    btrfs su cr /mnt/@
    btrfs su cr /mnt/@var
    btrfs su cr /mnt/@opt
    btrfs su cr /mnt/@tmp
    umount /mnt
	mount -o noatime,commit=120,compress=zstd,subvol=@ "$rootp" /mnt
	mkdir /mnt/{home,boot,var,opt,tmp}
	umount /mnt
	read -r -p "which is your boot partition? " bootp
	read -r -p "Do you want to format your boot partition? [y/N] " response
	case "$response" in
		[yY][eE][sS]|[yY])
			mkfs.fat -F32 "$bootp"
			;;
		*)
			;;
	esac	
	read -r -p "Do you want to use a seperate home partition? [y/N] " responseh
        case "$responseh" in
		    [yY][eE][sS]|[yY])
			    read -r -p "which is your home partition? " homep
			    read -r -p "Do you want to format your home partition? [y/N] " rhome
			    case "$rhome" in
				    [yY][eE][sS]|[yY])
					mkfs.btrfs -f "$homep"
		    ;;
        *)
		    ;;
		esac
    esac
	if [[ $responseh =~ ([yY][eE][sS]|[yY])$ ]]; then
		    mount "$homep" /mnt
		    btrfs su cr /mnt/@home
		    umount /mnt
		    mount -o noatime,commit=120,compress=zstd,subvol=@ "$rootp" /mnt
		    mount -o noatime,commit=120,compress=zstd,subvol=@home "$homep" /mnt/home
    else 
	        mount "$rootp" /mnt
	        btrfs su cr /mnt/@home
	        umount /mnt
		    mount -o noatime,commit=120,compress=zstd,subvol=@ "$rootp" /mnt
	        mount -o noatime,commit=120,compress=zstd,subvol=@home "$rootp" /mnt/home
    fi
		mount "$bootp" /mnt/boot
        mount -o noatime,commit=120,compress=zstd,subvol=@opt "$rootp" /mnt/opt
        mount -o noatime,commit=120,compress=zstd,subvol=@tmp "$rootp" /mnt/tmp
	    mount -o subvol=@var "$rootp" /mnt/var
	cont
}

function base {
	echo "Starting installation of packages in selected root drive..."
	sleep 1
	pacman -Syy	
	pacman-key --init
	pacman-key --populate
	basestrap /mnt \
				base \
				openrc \
				elogind-openrc \
				diffutils \
				e2fsprogs \
				bluez \
				bluez-utils \
				bluez-openrc \
				inetutils \
				less \
				linux \
				linux-firmware \
				logrotate \
				man-db \
				man-pages \
				nano \
				texinfo \
				usbutils \
				which \
				base-devel \
				networkmanager \
				networkmanager-openrc \
				sudo \
				bash-completion \
				git \
				vim \
				exfat-utils \
				ntfs-3g \
				grub \
				os-prober \
				efibootmgr \
				htop \
				vlc \
				pacman-contrib \
				ttf-hack \
                intel-ucode \
                btrfs-progs \
				reflector \
				dosfstools \
				exfatprogs
	genfstab -U /mnt >> /mnt/etc/fstab
	cont
}

function set-timezone {
    echo "Set your timezone "
    read -r -p "What country do you live in? (Capitalize first letter):" country
    read -r -p "What city do you live in? (Capitalize first letter):" city
    artix-chroot /mnt bash -c "ln -sf /usr/share/zoneinfo/$country/$city /etc/localtime && exit"
    cont
}


function install-gnome {
	artix-chroot /mnt bash -c "pacman -S gnome gdm-openrc gnome-tweaks papirus-icon-theme && exit"
	artix-chroot /mnt bash -c "rc-update add gdm default && exit"
	# Editing gdm's config for disabling Wayland as it does not play nicely with Nvidia
	artix-chroot /mnt bash -c "sed -i 's/#W/W/' /etc/gdm/custom.conf && exit"
}
function install-xfce {
	artix-chroot /mnt bash -c "pacman -S xfce4 xfce4-goodies gstreamer0.10-base-plugins dbus gtk-engines gtk-engine-murrine gnome-themes-standard && exit" 
}
function install-kde {
	artix-chroot /mnt bash -c "pacman -S xorg plasma sddm sddm-openrc plasma-wayland-protocols plasma-wayland-session && exit"
	artix-chroot /mnt bash -c "rc-update add sddm default && exit"
	artix-chroot /mnt bash -c "pacman -S ark dolphin ffmpegthumbs libadwaita gnome-keyring gwenview kaccounts-integration kate kdialog khotkeys kio-extras ksystemlog okular print-manager pipewire alacritty latte-dock htop vscodium zsh \
	ark audiocd-kio dolphin dolphin-plugins filelight kcalc kcron kdegraphics-thumbnailers kdenetwork-filesharing kdesdk-kio kdesdk-thumbnailers kdialog \
	kio-gdrive kompare markdownpart partitionmanager skanlite skanpage svgpart kio-zeroconf pipewire-zeroconf xdg-desktop-portal kvantum wireplumber && exit"
}
function install-hyprland {
	artix-chroot /mnt bash -c "pacman -S hyprland && exit"
}

function de {
	echo -e "Choose a Desktop Environment or Window Manager to install: \n"
	echo -e "1. GNOME \n2. Xfce \n3. KDE \n4. None"
	read -r -p "DE: " desktope
	case "$desktope" in
		1)
			install-gnome
			;;
		2)
			install-xfce
			;;
		3)
			install-kde
			;;
		4)
			install-hyprland
			;;
		*)
			;;
	esac
	cont
}

function installgrub {
	read -r -p "Install GRUB bootloader? [Y/n] " igrub
	if [[ $igrub =~ ([nN][oO]|[nN])$ ]]; then
		cont	 
	else 
		echo -e "Installing GRUB.."
		artix-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --removable && grub-mkconfig -o /boot/grub/grub.cfg && exit"
	fi
	cont
}

function archroot {
	read -r -p "Enter the username: " uname
	read -r -p "Enter the hostname: " hname

	echo -e "Setting up Language\n"
	artix-chroot /mnt bash -c "hwclock --systohc && sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf && exit"

	echo -e "Setting up Hostname\n"
	artix-chroot /mnt bash -c "echo $hname > /etc/hostname && echo 127.0.0.1	$hname > /etc/hosts && echo ::1	$hname >> /etc/hosts && echo 127.0.1.1	$hname.localdomain	$hname >> /etc/hosts && exit"

	echo "Set Root password"
	artix-chroot /mnt bash -c "passwd && useradd -mG wheel $uname && echo 'set user password' && passwd $uname && sed -i '85s/#/ /' /etc/sudoers && exit"

    echo "add btrfs module to mkinitcpio"
    artix-chroot /mnt bash -c "sed -i '7s/(/(btrfs/' /etc/mkinitcpio.conf && mkinitcpio -P && exit"

	echo -e "enabling services...\n"
	artix-chroot /mnt bash -c "rc-update add bluetooth && exit"
	artix-chroot /mnt bash -c "rc-update add NetworkManager default && exit"
	
	#echo -e "enabling paccache timer...\n"
	#artix-chroot /mnt bash -c "systemctl enable paccache.timer && exit"

	echo -e "Editing configuration files...\n"
	# Enabling multilib in pacman
	artix-chroot /mnt bash -c "sed -i '93s/#\[/\[/' /etc/pacman.conf && sed -i '94s/#I/I/' /etc/pacman.conf && pacman -Syu && sleep 1 && exit"
	# Tweaking pacman, uncomment options Color, TotalDownload and VerbosePkgList
	artix-chroot /mnt bash -c "sed -i '34s/#C/C/' /etc/pacman.conf && sed -i '35s/#T/T/' /etc/pacman.conf && sed -i '37s/#V/V/' /etc/pacman.conf && sleep 1 && exit"

	cont
}

function install-amd {
	artix-chroot /mnt bash -c "pacman -S mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon && exit"
	artix-chroot /mnt bash -c "pacman -S libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau && exit"
}
function install-intel {
	artix-chroot /mnt bash -c "pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel && exit" 
	artix-chroot /mnt bash -c "pacman -S libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau && exit"
}
function install-nvidia {
	artix-chroot /mnt bash -c "pacman -S nvidia nvidia-settings nvidia-utils lib32-nvidia-utils && exit"	
}

function install-firefox {
	artix-chroot /mnt bash -c "pacman -S firefox && exit"
}
function install-firefoxn {
	artix-chroot /mnt bash -c "pacman -S firefox-nightly && exit"
}
function install-librewolf {
	artix-chroot /mnt bash -c "pacman -S librewolf && exit"
}
function install-google {
	artix-chroot /mnt bash -c "pacman -S google-chrome && exit"
}
function install-ugchromium {
	artix-chroot /mnt bash -c "pacman -S ungoogled-chromium && exit"
}


function browsers {
	echo -e "Choose what browser you want to install \n"
	echo -e "1. Firefox \n2. Firefox Nightly \n3. Librewolf \n4. Google Chrome \n5. Ungoogled Chromium \n6. None"
	echo -e "you will need chaotic-aur installed for (firefox nightly, librewolf, ungoogled chromium)"
	read -r -p "Browers [1/2/3/4/5/6]:" browser
	case "$browser" in
	    1)
		    install-firefox
			;;
		2)
		    install-firefoxn
			;;
		3)
		    install-Librewolf
			;;
		4)
		    install-Google
			;;
		5)
		    install-ugchromium
			;;
		*)
		    ;;
	esac
	cont
}
function graphics {
	echo -e "Choose Graphic card drivers to install: \n"
	echo -e "1. AMD \n2. Nvidia \n3. Intel \n4. None"
	read -r -p "Drivers [1/2/3/4]: " drivers
	case "$drivers" in
		1)
			install-amd
			;;
		2)
			install-nvidia
			;;
		3)
		    install-intel
			;;
		*)
			;;
	esac
	cont
}

function paru {
	artix-chroot /mnt bash -c "pacman -S paru && exit"
}

function yay { 
	artix-chroot /mnt bash -c "pacman -S yay && exit"
}

function aur-helper {
	echo -e "choose which aur helper you want to install: \n"
	echo -e "1. Paru \n2. Yay \n3. None"
    read -r -p "aur hepler [1/2/3]: " aurhelp
	case "$aurhelp" in
	1)
	    paru
		;;
	2)
	    yay
		;;
	*)
	    ;;
	esac
	cont 
}

function installsteam {
	read -r -p "Do you want to install steam? [y/N] " isteam
	case "$isteam" in
		[yY][eE][sS]|[yY])
			artix-chroot /mnt bash -c "pacman -S steam steam-native-runtime && exit"
			;;
		*)
			;;
	esac
        read -r -p "Do you want to install steam tinker launch? [y/N] " stl
        case "$stl" in
		    [yY][eE][sS]|[yY])
		        artix-chroot /mnt bash -c "pacman -S steamtinkerlaunch && exit"
			    ;;
		    *)
		        ;;	
	    esac
	cont
}

function additional {
	read -r -p "Do you want to install fun stuff? [y/N] " funyes # because why not
	case "$funyes" in
		[yY][eE][sS]|[yY])
			pacstrap /mnt sl neofetch lolcat cmatrix
			;;
		*)
			;;
	esac
}

function chaotic-aur {
	read -r -p "Do you want to add the Chaotic-aur repo [y/N] " chaotic
	if [[ $chaotic =~ ([nN][oO]|[nN])$ ]]; then
	cont 
	else
	    artix-chroot /mnt bash -c "pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com && pacman-key --lsign-key FBA220DFC880C036 && exit" 
		artix-chroot /mnt bash -c "pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && exit"
		artix-chroot /mnt bash -c "echo '[chaotic-aur]' >> /etc/pacman.conf && echo Include = '/etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf && pacman -Sy && exit"
	fi
	cont
}


function full-installation {
	set-time
	partition
	mounting
	base
	archroot
	chaotic-aur
	aur-helper
    set-timezone
	de
	installgrub
	graphics
	installsteam
	additional
	browsers
	echo "Installation complete. Reboot you lazy bastard."
}

function step-installation {
	echo "These steps are available for installion:"
	echo "1. set-time"
	echo "2. partioning"
	echo "3. mounting"
	echo "4. base installation"
	echo "5. archroot"
	echo "6. adding chaotic-aur repo"
	echo "7. installing aur helper"
    echo "8. set-timezone"
	echo "9. installing a Desktop Environment"
	echo "10. installing grub"
	echo "11. graphics drivers"
	echo "12. installing steam"
	echo "13. additional stuff"
	echo "14. installing browsers"
	read -r -p "Enter the number of step : " stepno

	array=(set-time partition mounting base archroot chaotic-aur aur-helper set-timezone de installgrub graphics installsteam additional browsers)
	#array=(ascii ascii ascii)
	stepno=$((stepno-1))
	while [ $stepno -lt ${#array[*]} ]
	do
		${array[$stepno]}
		stepno=$((stepno+1))
	done
}

function main {
	echo "1. Start full installation"
	echo "2. Start from a specific step"
	read -r -p "What would you like to do? [1/2] " what
	case "$what" in
		2)
			step-installation
			;;
		*)
			full-installation
			;;
	esac
}

ascii
read -r -p "Start Installation? [Y/n] " starti
case "$starti" in
	[nN][oO]|[nN])
		;;
	*)
		main
		;;
esac