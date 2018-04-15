#!/bin/bash
INS_PROFILE="perfil_0.sh"

if [[ -f `pwd`/profiles/$INS_PROFILE ]]; then
  source `pwd`/profiles/$INS_PROFILE
else
  echo "missing file: $INS_PROFILE NO ENCONTRADO!"
  exit 1
fi

# Función que realiza pausas durante la Instalación
function pausa {
    if [ $AUTO != "True" ]; then
        echo  -e "\e[0;91mPress return to continue\e[0;97m"
        dummy_var=""
        read dummy_var
    fi
}

# Función que presenta el logotipo de Arch Linux y su versión
function logotipo {
     old_IFS=$IFS     # conserva el separador de campo
     IFS=''; cat .logo | while read line; do  echo  -e $line; done
     IFS=$old_IFS     # restablece el separador de campo predeterminado
}

# Función que valida la existencia del Dispositivo
function validar_device {
    DEVICE_OK="False"
    devices_list=(`lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme'`)
    for item in ${devices_list[@]}; do
        if [ $item == $DEVICE ]; then
            DEVICE_OK="True"
            break
        fi
    done
    if [ $DEVICE_OK == "False" ] ; then
        echo "El dispositivo $DEVICE no EXISTE!"
        exit 1
    fi
}

# Función que monta las Particiones del Sistema
function mount_point {
    echo -e "\e[1;36m\n********************************************"
    echo "* Guía de Instalación de Arch Linux - 2018 *"
    echo "********************************************"
    echo -e "\e[1;33m\nVerificación y validación de los puntos de montaje..."
    echo -e "=====================================================\e[0;97m"
    validar_device
    if [ -n "$PART_ROOT" ]; then
        mount /dev/$PART_ROOT /mnt
        # Verifica que la partición raíz haya sido montada satisfactoriamente
        if [ $? -eq 0 ]; then
            if [ -n "$PART_BOOT" ]; then
                # ADVERTENCIA: Si se va a instalar el bootloader SYSLINUX, es
                # necesario formatear la partición que contenga al /boot
                # como una partición de 32 bits:
                # mkfs.ext4 -O '^64bit' /dev/sda?
                e2label /dev/$PART_BOOT Arch
                mkdir /mnt/boot 2> /dev/null
                mount /dev/$PART_BOOT /mnt/boot
            fi
            if [ -n "$PART_ESP" ]; then
                # ADVERTENCIA: Si el sistema a instalar va a crear una partición ESP,
                # asegúrese que sea formateada como FAT32 y un tamaño de al menos
                # 100M, siendo esta generalmente la primera partición:
                # mkfs.vfat -F32 /dev/sda1
                mkdir -p /mnt/boot/efi 2> /dev/null
                mount /dev/$PART_ESP /mnt/boot/efi
            fi
            if [ -n "$PART_HOME" ]; then
                mkdir /mnt/home 2> /dev/null
                mount /dev/$PART_HOME /mnt/home
            fi
        else
            exit 1
        fi
    else
        exit 1;
    fi
    lsblk $DEVICE
    echo -ne "\n¿Los Puntos de Montaje son Correctos? [S/n]"
    RTA=""
    read RTA
    case "$RTA" in
        [nN][oO]|[nN])
            umount -R /mnt
            exit 1
            ;;
        *)
            return
            ;;
    esac
}

# 1) Instalando el Sistema Base...
function ins_base {
    echo -e "\e[1;33m\n1) Instalando el Sistema Base..."
    echo -e "================================\e[0;97m"
    pausa
    if [ $BASE_DEVEL == "True" ]; then
        pacstrap /mnt base base-devel
    else
        pacstrap /mnt base
    fi
}

# 2) Instalando paquetes de Red...
function ins_red {
    echo -e "\e[1;33m\n2) Instalando paquetes de Red..."
    echo -e "================================\e[0;97m"
    pausa
    if [ $INALAMBRICA == "True" ]; then
        pacstrap /mnt net-tools wireless_tools
    else
        pacstrap /mnt net-tools
    fi
}

# 3) Generación del archivo fstab...
function gen_fstab {
    echo -e "\e[1;33m\n3) Generación del archivo fstab..."
    echo -e "==================================\e[0;97m"
    pausa
    genfstab -L /mnt >> /mnt/etc/fstab
}

# 4) Configurando el nombre del Equipo...
function nombre_equipo {
    echo -e "\e[1;33m\n4) Configurando el nombre del Equipo..."
    echo -e "=======================================\e[0;97m"
    pausa
    if [ -z $EQUIPO ]; then
        echo -n "Escriba el Nombre del Equipo:"
        read EQUIPO
    fi
    echo "$EQUIPO" > /mnt/etc/hostname
    sed -i '/127.0.0.1/s/$/\t'${EQUIPO}'/' /mnt/etc/hosts
    sed -i '/::1/s/$/\t'${EQUIPO}'/' /mnt/etc/hosts
}

# 5) Configurando el Zona Horaria...
function zona_horaria {
    echo -e "\e[1;33m\n5) Configurando el Zona Horaria (Bogotá)..."
    echo -e "===========================================\e[0;97m"
    pausa
    if [ -z $ZONA_HORARIA ]; then
        echo "Visualización de Zonas Horarias < presione Q para Salir >"
        echo "Press return to continue"
        dummy_var=""
        read dummy_var
        timedatectl list-timezones
        echo -n "Escriba la Zona Horaria:"
        read ZONA_HORARIA
    fi
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$ZONA_HORARIA /etc/localtime
}

# 6) Configurando el Reloj del Sistema con Windows...
function reloj_sistema {
    echo -e "\e[1;33m\n6) Configurando el Reloj del Sistema con Windows..."
    echo -e "===================================================\e[0;97m"
    pausa
    arch-chroot /mnt hwclock --systohc --localtime
}

# 7) Preferencias de Localización...
function localizacion {
    echo -e "\e[1;33m\n7) Preferencias de Localización..."
    echo -e "===================================\e[0;97m"
    pausa
    echo "LANG=${IDIOMA}" > /mnt/etc/locale.conf
    if [[ ( -z $LOCALE_UTF ) && ( -z $LOCALE_ISO ) ]]; then
        nano /mnt/etc/locale.gen
    else
        sed -i "s/#$LOCALE_UTF/$LOCALE_UTF/" /mnt/etc/locale.gen
        sed -i "s/#$LOCALE_ISO/$LOCALE_ISO/" /mnt/etc/locale.gen
    fi
    arch-chroot /mnt locale-gen
    echo "KEYMAP=$TECLADO" > /mnt/etc/vconsole.conf
}

# 8) Regenerar el ramdisk utilizando mkinitcpio...
function rgen_mkinitcpio {
    echo -e "\e[1;33m\n8) Regenerar el ramdisk utilizando mkinitcpio..."
    echo -e "================================================\e[0;97m"
    pausa
    arch-chroot /mnt mkinitcpio -p linux
}

# 9) Instalando el Gestor de Arranque...
function ins_bootloader {
    echo -e "\e[1;33m\n9) Instalando el Gestor de Arranque..."
    echo -e "======================================\e[0;97m"
    pausa
    if [ $BOOTLOADER == "REFIND" ]; then
        pacstrap /mnt refind-efi
        arch-chroot /mnt refind-install
        # Detección de la partición en la cual está montada "/"
        ROOTP=$(arch-chroot /mnt lsblk -rno NAME,MOUNTPOINT $DEVICE  | grep -w -m1 "/" | awk '{print $1}')
        echo '"Boot with standard options"   "root=/dev/'$ROOTP' rootfstype=ext4 ro"' > /mnt/boot/refind_linux.conf
    elif [ $BOOTLOADER == "GRUB" ]; then
        pacstrap /mnt grub os-prober
        if [ -n "$PART_ESP" ]; then
			pacstrap /mnt efibootmgr
            arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
        else
            arch-chroot /mnt grub-install $DEVICE
        fi
        # sed -i "s/#GRUB_BACKGROUND=\"\/path\/to\/wallpaper\"/GRUB_BACKGROUND=\"\/boot\/grub\/"${BOOTL_BACKG}"\"/" /mnt/etc/default/grub

        sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=15/" /mnt/etc/default/grub
        # echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub
        if [ $GRUB_THEME == "VIMIX" ]; then
			sed -i "s/#GRUB_THEME=\"\/path\/to\/gfxtheme\"/GRUB_THEME=\"\/boot\/grub\/themes\/Vimix\/theme.txt""\"/" /mnt/etc/default/grub
            tar -xvf themes/grub/Vimix.tar.gz -C /mnt/boot/grub/themes
        elif [ $GRUB_THEME == "VIMIX_U" ]; then
            sed -i "s/#GRUB_THEME=\"\/path\/to\/gfxtheme\"/GRUB_THEME=\"\/boot\/grub\/themes\/Vimix\/theme.txt""\"/" /mnt/etc/default/grub
            tar -xvf themes/grub/Vimix_udenar.tar.gz -C /mnt/boot/grub/themes
        elif [ $GRUB_THEME == "ETERNITY_U" ]; then
            sed -i "s/#GRUB_THEME=\"\/path\/to\/gfxtheme\"/GRUB_THEME=\"\/boot\/grub\/themes\/Eternity\/theme.txt""\"/" /mnt/etc/default/grub
            tar -xvf themes/grub/Eternity_udenar.tar.gz -C /mnt/boot/grub/themes
        fi
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        echo "menuentry 'Apagar' --class shutdown {" >> /mnt/boot/grub/grub.cfg
        echo "    halt" >> /mnt/boot/grub/grub.cfg
        echo "}" >> /mnt/boot/grub/grub.cfg
    elif [ $BOOTLOADER == "SYSLINUX" ]; then
        pacstrap /mnt syslinux
        if [ -z "$PART_ESP" ]; then
            arch-chroot /mnt syslinux-install_update -i -a -m
            cp cfg/syslinux.cfg /mnt/boot/syslinux/
            sed -i "s/fondo_syslnx.png/"${BOOTL_BACKG}"/" /mnt/boot/syslinux/syslinux.cfg
            sed -i "s/sdaROOT/"${PART_ROOT}"/" /mnt/boot/syslinux/syslinux.cfg
            cp img/${BOOTL_BACKG} /mnt/boot/syslinux/
        else
            echo "No es posible montar una ESP con el bootloader Syslinux!"
            exit 1
        fi
    fi
}

# 10) Asignación de clave al usuario <<root>>...
function passwd_root {
    echo -e "\e[1;33m\n10) Asignación de clave al usuario <<root>>..."
    echo -e "=============================================\e[0;97m"
    pausa
    if [ -z $PASS_ROOT ]; then
        arch-chroot /mnt passwd
    else
        SALT="Q9"
        HASH=$(perl -e "print crypt(${PASS_ROOT},${SALT})")
        arch-chroot /mnt usermod -p ${HASH} root
    fi
}

# 11) Creación de un usuario del Sistema...
function usu_sistema {
    echo -e "\e[1;33m\n11) Creación de un usuario del Sistema..."
    echo -e "=========================================\e[0;97m"
    pausa
    if [ -z $NOMBRE ]; then
        echo -n "Nombre Largo del Usuario:"
        read NOMBRE
    fi
    if [ -z $NOM ]; then
        echo -n "Nombre corto del Usuario (minúsculas/sin espacios):"
        read NOM
    fi

    if [ $SEC_SUDO == "0" ]; then
        arch-chroot /mnt useradd -m -g users -G power,storage,network,audio,video,optical -c "$NOMBRE" -s /bin/bash $NOM
    else
        arch-chroot /mnt useradd -m -g users -G wheel,power,storage,network,audio,video,optical -c "$NOMBRE" -s /bin/bash $NOM
        if [ $SEC_SUDO == "1" ]; then
            sed -i '/%wheel ALL=(ALL) NOPASSWD/s/^# //' /mnt/etc/sudoers
        elif [ $SEC_SUDO == "2" ]; then
            sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /mnt/etc/sudoers
        fi
    fi

    if [ -z $PASS_USU ]; then
        arch-chroot /mnt passwd $NOM
    else
        SALT="Q9"
        HASH=$(perl -e "print crypt(${PASS_USU},${SALT})")
        arch-chroot /mnt usermod -p ${HASH} $NOM
    fi
}

# 12) Instalando Xorg y/o Wayland...
function ins_xorg_wayland {
    echo -e "\e[1;33m\n12) Instalando Xorg y/o Wayland..."
    echo -e "==================================\e[0;97m"
    pausa
    pacstrap /mnt xorg-server xorg-apps

    if [ -z $TVIDEO ]; then
        lspci | grep -e VGA -e 3D
        echo -n "Tarjeta de Video (<ENTER> para una configuración de Video especializada Post-Instalación):"
        read TVIDEO
    fi
    if [ ! -z $TVIDEO ]  && [ ${TVIDEO^^} != "MANUAL" ]; then
        pacstrap /mnt xf86-video-$TVIDEO
    fi
}

# 13) Instalando Entorno de Escritorio...
function ins_desk_env {
    echo -e "\e[1;33m\n13) Instalando Entorno de Escritorio..."
    echo -e "=======================================\e[0;97m"
    pausa
    if [ $DESKTOP_ENV == "GNOME" ]; then
        pacstrap /mnt gnome gnome-extra mesa-demos
        echo "[User]" >> /mnt/var/lib/AccountsService/users/$NOM
        echo "SystemAccount=false" >> /mnt/var/lib/AccountsService/users/$NOM
        echo "XSession=gnome-xorg" >> /mnt/var/lib/AccountsService/users/$NOM
        if [ -n $IMG_USER ]; then
            cp img/${IMG_USER} /mnt/var/lib/AccountsService/icons/$NOM
            echo "Icon=/var/lib/AccountsService/icons/${NOM}" >> /mnt/var/lib/AccountsService/users/$NOM
        fi
        echo "Language=${IDIOMA}" >> /mnt/var/lib/AccountsService/users/$NOM
        cp cfg/00-keyboard.conf /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
        if [ $TECLADO == "es" ]; then
            sed -i "s/LAYOUT/es/" /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
        else
            sed -i "s/LAYOUT/latam/" /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
        fi
    elif [ $DESKTOP_ENV == "DEEPIN" ]; then
        pacstrap /mnt deepin deepin-extra noto-fonts lightdm lightdm-gtk-greeter lightdm-deepin-greeter networkmanager
        echo "[User]" >> /mnt/var/lib/AccountsService/users/$NOM
        echo "SystemAccount=false" >> /mnt/var/lib/AccountsService/users/$NOM
        sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/" /mnt/etc/lightdm/lightdm.conf
        echo "XSession=deepin" >> /mnt/var/lib/AccountsService/users/$NOM
        if [ -n $IMG_USER ]; then
            cp img/${IMG_USER} /mnt/var/lib/AccountsService/icons/
            echo "Icon=file:///var/lib/AccountsService/icons/${IMG_USER}" >> /mnt/var/lib/AccountsService/users/$NOM
        fi
        echo "Locale=${IDIOMA/CO/ES}" >> /mnt/var/lib/AccountsService/users/$NOM
        if [ $TECLADO == "es" ]; then
            echo "Layout=es;" >> /mnt/var/lib/AccountsService/users/$NOM
        else
            echo "Layout=latam;" >> /mnt/var/lib/AccountsService/users/$NOM
        fi
    fi
}

# 14) Activando NetworkManager y Display Manager...
function on_servicios {
    echo -e "\e[1;33m\n14) Activando NetworkManager y Display Manager..."
    echo -e "=================================================\e[0;97m"
    pausa
    arch-chroot /mnt systemctl enable NetworkManager
    if [ $DESKTOP_ENV == "GNOME" ]; then
        arch-chroot /mnt systemctl enable gdm
    elif [ $DESKTOP_ENV == "DEEPIN" ]; then
        arch-chroot /mnt systemctl enable lightdm
    fi
}

# 15) Cambiando Tema para rEFInd...
function rEFInd_theme {
    if [ -n "$rEFInd_THEME" ]; then
        echo -e "\e[1;33m\n15) Cambiando Tema de rEFInd..."
        echo -e "===============================\e[0;97m"
        pausa
        mkdir /mnt/boot/efi/EFI/refind/themes
        if [ $rEFInd_THEME == "MINIMAL" ]; then
            tar -xvf themes/refind/minimal-theme.tar.gz -C /mnt/boot/efi/EFI/refind/themes
            echo "include themes/rEFInd-minimal/theme.conf" >> /mnt/boot/efi/EFI/refind/refind.conf
        elif [ $rEFInd_THEME == "MINIMAL_2" ]; then
            tar -xvf themes/refind/minimal2-theme.tar.gz -C /mnt/boot/efi/EFI/refind/themes
            echo "include themes/refind-minimal/theme.conf" >> /mnt/boot/efi/EFI/refind/refind.conf
        elif [ $rEFInd_THEME == "NEXT" ]; then
            tar -xvf themes/refind/next-theme.tar.gz -C /mnt/boot/efi/EFI/refind/themes
            echo "include themes/next-theme/theme.conf" >> /mnt/boot/efi/EFI/refind/refind.conf
        elif [ $rEFInd_THEME == "NEXT_U" ]; then
            tar -xvf themes/refind/next-theme_udenar.tar.gz -C /mnt/boot/efi/EFI/refind/themes
            echo "include themes/next-theme/theme.conf" >> /mnt/boot/efi/EFI/refind/refind.conf
        fi
    fi
}

# 16) Instalación de Aplicaciones...
function ins_apps {
    if [ $INSTALL_APPS == "True" ]; then
        echo -e "\e[1;33m\n16) Instalación de Aplicaciones..."
        echo -e "===================================\e[0;97m"
        pausa
        pacstrap /mnt $(< cfg/apps) --noconfirm
    fi
}

# 17) Copiando fuentes de Windows 10...
function copy_win_fonts {
    if [ $WINDOWS_FONTS == "True" ]; then
        echo -e "\e[1;33m\n17) Copiando fuentes de Windows 10..."
        echo -e "=====================================\e[0;97m"
        pausa
        tar -zxvf fonts/fuentes_win10.tar.gz -C /mnt
        chmod 755 /mnt/usr/share/fonts/WindowsFonts/*
        arch-chroot /mnt fc-cache
    fi
}

# 18) Copiando Archivos de Configuración...
function copy_files_config {
    mkdir /mnt/home/$NOM/.local/share/applications -p
    if [ $DESKTOP_ENV == "DEEPIN" ]; then
        mkdir /mnt/home/$NOM/.config/deepin/dde-file-manager -p
        cp cfg/dde-file-manager.conf /mnt/home/$NOM/.config/deepin/dde-file-manager/
        cp cfg/mimeapps_1.list /mnt/home/$NOM/.config/mimeapps.list
        arch-chroot /mnt chown -R $NOM: /home/$NOM/.config/
        cp cfg/mimeapps_1.list /mnt/home/$NOM/.local/share/applications/mimeapps.list
    elif [ $DESKTOP_ENV == "GNOME" ]; then
        cp cfg/mimeapps_2.list /mnt/home/$NOM/.local/share/applications/mimeapps.list
    fi
    arch-chroot /mnt chown -R $NOM: /home/$NOM/.local
}

# 19) Instalación en Virtual Box Guest...
function ins_vbox_guest {
    if [ $VBOX == "True" ]; then
        echo -e "\e[1;33m\n18) Instalación en Virtual Box Guest..."
        echo -e "=======================================\e[0;97m"
        pausa
        pacstrap /mnt virtualbox-guest-utils virtualbox-guest-modules-arch
        arch-chroot /mnt systemctl enable vboxservice
        if [ -n "$VBOX_ESP" ]; then
            if [ $BOOTLOADER == "REFIND" ]; then
                echo "\EFI\refind\refind_x64.efi" > /mnt$VBOX_ESP/startup.nsh
            elif [ $BOOTLOADER == "GRUB" ]; then
                echo "\EFI\grub\grubx64.efi" > /mnt$VBOX_ESP/startup.nsh
            fi
        fi
    fi
}


# **************************** PROGRAMA PRINCIPAL ****************************
logotipo
mount_point
if [ $OFFLINE == "True" ]; then
    cp cfg/pacman_rudenar.conf /etc/pacman.conf
    echo "Server = file://`pwd`/pkg" >> /etc/pacman.conf
fi
ins_base # 1
ins_red # 2
gen_fstab # 3
nombre_equipo # 4
zona_horaria # 5
reloj_sistema # 6
localizacion # 7
rgen_mkinitcpio # 8
ins_bootloader # 9
passwd_root # 10
usu_sistema # 11
ins_xorg_wayland # 12
ins_desk_env # 13
on_servicios # 14
rEFInd_theme # 15
ins_apps # 16
copy_win_fonts # 17
copy_files_config # 18
ins_vbox_guest # 19
