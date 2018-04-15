# [ ******************* ZONA DE CONFIGURACIÓN ***************************** ] #
# =========================================================================== #
# Nombre del Perfil:
# Descripción:
#
#-----------------------------------------------------------------------------#

#-------------- [[ 1. Selección de Particiones/Puntos de Montaje ]] ----------#
# Dispositivo o Disco Duro donde se realizará la Instalación
DEVICE="/dev/sda" # ATENCIÓN: Se asume que el Dispositivo en donde se va a realizar la instalación es /dev/sda
# Partición para ser montada como "/"
PART_ROOT="sda_" # "partición". Si no existe, el script de instalación NO se ejecutará.
# Partición para ser montada como "/boot"
PART_BOOT="sda_" # "partición" o "". Si no existe, "/boot" se creará en la partición "/". ATENCIÓN: Revisar la nota cuando el bootloader es SYSLINUX.
# Partición para ser montada como "/boot/efi". Esta partición es conocida como EFI System Partition, que puede haber sido creada por Windows.
PART_ESP="sda_" # "partición" o "". Si no existe, se asume que no existe la ESP en el sistema y se recomieda seleccionar a GRUB como gestor de arranque.
# Partición para ser montada como "/home"
PART_HOME="sda_" # "partición" o "". Si no existe, "/home" se creará en la partición "/".
#-----------------------------------------------------------------------------#

#-------------- [[ 2. Tipo de Instalación ]] ---------------------------------#
# Utilizando Internet (online) o un repositorio local (offline)
OFFLINE="True" # "True" o "False"
# Realiza una instalación desatendida (Auto), siempre y cuando las variables de instalación tengan valores válidos.
AUTO="True" # "True" o "False"
#-----------------------------------------------------------------------------#

#-------------- [[ 3. Paquetes Extra Desarrollo/Inalámbrica ]] ---------------#
BASE_DEVEL="True" # "True" o "False"
# Inalámbrica es recomendable para la mayoría de portátiles con conexión Wi-Fi
INALAMBRICA="True" # "True" o "False"
#-----------------------------------------------------------------------------#

#-------------- [[ 4. Configuración Equipo/Localización/Bootloader, etc ]] ---#
EQUIPO="??????" # "" o "nombre_equipo"
ZONA_HORARIA="America/Bogota" # "", "America/Bogota". Ver más Zonas: timedatectl list-timezones
IDIOMA="es_CO.UTF-8" # "es_CO.UTF-8" o "en_US.UTF-8"
LOCALE_UTF="es_CO.UTF-8 UTF-8" # "" o "<idioma>_<territorio>.<codeset>[@<modificadores>] Ver https://wiki.archlinux.org/index.php/Locale"
LOCALE_ISO="es_CO ISO-8859-1" # "" o "<idioma>_<territorio>.<codeset>[@<modificadores>] Ver https://wiki.archlinux.org/index.php/Locale"
TECLADO="es" # "es" o "la-latin1"
# Bootloader    MBR     EFI
# ==========    ===     ===
# REFIND        [ ]     [X]
# SYSLINUX      [X]     [ ]
# GRUB          [X]     [X]
BOOTLOADER="REFIND" # "REFIND", "GRUB" o "SYSLINUX".
rEFInd_THEME="" # "", "MINIMAL", "MINIMAL_2", "NEXT", "NEXT_U"
GRUB_THEME="" # "", "VIMIX", "VIMIX_U", "ETERNITY_U"
BOOTL_BACKG="" # "" o "imagen_background_grub_syslinux.{jpg, png}"
PASS_ROOT="???????" # "Clave_del_usuario_root" o ""
NOMBRE="???????" # "Nombre largo del Usuario" o ""
NOM="???????" # "nombre_corto" o ""
PASS_USU="???????" # "Clave_del_Usuario" o ""
IMG_USER="" # "", o "imagen_usuario.{jpg, png}. Ejemplo: 14.png para entornos Deepin"
SEC_SUDO="0" # "0":El usuario no es sudo; "1":El usuario es sudo, y no necesita clave; "2":El usuario es sudo, y necesita clave.
TVIDEO="intel" # "marca_tarjeta_video", "MANUAL" o "". Se recomienda "vesa" si la instalación es sobre una máquina virtual de Virtual Box y "MANUAL" para configurar una tarjeta especial Post-Instalación.
DESKTOP_ENV="DEEPIN" # "GNOME" o "DEEPIN"
#-----------------------------------------------------------------------------#

#-------------- [[ 5. Aplicaciones Oficiales ]] -------------------------------#
# Instalación de aplicaciones oficiales adicionales listadas en el archivo: apps
INSTALL_APPS="True" # "True" o "False"
#-----------------------------------------------------------------------------#

#-------------- [[ 6. Fuentes de Windows 10 ]] -------------------------------#
# Copia las fuentes de Windows 10 a /usr/share/fonts
WINDOWS_FONTS="True" # "True" o "False"
#-----------------------------------------------------------------------------#

#-------------- [[ 7. VirtualBox ]] ------------------------------------------#
# Poner a True cuando la instalación se realice en una Máquina Virtual con Virtual Box.
VBOX="False" # "True" o "False"
# Poner una ruta válida cuando la instalación haga uso del Bootloader rEFInd.
VBOX_ESP="" # "", "/boot/efi" o "/boot"
# =========================================================================== #
