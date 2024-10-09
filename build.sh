#!/usr/bin/bash
# Origami Kernel Builder
# Version 1.1
# Copyright (c) 2023-2024 Rem01 Gaming <Rem01_Gaming@proton.me>
#
#			GNU GENERAL PUBLIC LICENSE
#			 Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

# Define some things

# Export Bot token and chat id
export SEND_TO_TG=1
export chat_id="-1001952289318"
export token="7034672132:AAHi8HPm41YxODjidVTjO0Wg7Nz9L18aMmk"

#!/bin/bash

# Read bot token and chat ID from variables
token="$token"
chat_id="$chat_id"

# Checking if environment variables are set
if [ -z "$token" ] || [ -z "$chat_id" ]; then
  echo "Error: Bot token or chat ID is not set."
  exit 1
fi

# Kernel common
export ARCH=arm64
export LINKER="ld.lld"

# Telegram API
export SEND_TO_TG=1

# Telegram && Output
export kver="Beta"
export CODENAME="fire"
export DEVICE="Redmi 12 (${CODENAME})"
export BUILDER="äerichāndesu"
export BUILD_HOST="noticesa"
export TIMESTAMP=$(date +"%Y%m%d")
export KBUILD_COMPILER_STRING=$(./clang/bin/clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')
export zipn="perf-${CODENAME}-${TIMESTAMP}"
# Needed by script
export PATH="${PWD}/clang/bin:${PATH}"
PROCS=$(nproc --all)

# Text coloring
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# Check permission
script_permissions=$(stat -c %a "$0")
if [ "$script_permissions" -lt 777 ]; then
    echo -e "${RED}error:${NOCOLOR} Don't have enough permission"
    echo "run 'chmod 0777 origami_kernel_builder.sh' and rerun"
    exit 126
fi

# Check dependencies
if ! hash make curl bc zip 2>/dev/null; then
  echo -e "${RED}error:${NOCOLOR} Missing dependencies"
  echo "Installing..."
  sudo apt update
  sudo apt install -y make curl bc zip
  echo "Dependencies installed!"
else
  echo "All dependencies present."
fi

# Check if clang folder exists
if [ ! -d "${PWD}/clang" ]; then
  echo "Cloning clang..."

  # Get the latest release URL
  latest_release_url=$(curl -s "https://api.github.com/repos/ZyCromerZ/Clang/releases/latest" | grep '"browser_download_url":' | cut -d '"' -f 4)

  # Download the latest release assets
  wget "$latest_release_url" -O "clang.tar.gz"

  # Extract archive and clean it
  rm -rf clang && mkdir clang && tar -xvf clang.tar.gz -C clang && rm -rf clang.tar.gz
  echo "clang cloned!"
else
  echo "The clang folder already exists."
fi


# Check anykernel
if [ ! -d "${PWD}/anykernel" ]; then
    echo -e "${RED}error:${NOCOLOR} /anykernel not found!"
    echo "Cloning AnyKernel3..."
    git clone -b fire https://github.com/Le-Mineral-0023/Anykernel3-FIRE anykernel
    if [ $? -ne 0 ]; then
        echo -e "${RED}error:${NOCOLOR} Failed to clone!"
        exit 1
    fi
    echo "Cloned AnyKernel3!"
else
    echo "anykernel directory exists."
fi

# Exit on interrupt
exit_on_signal_interrupt() {
    echo -e "\n\n${RED}Got interrupt signal.${NOCOLOR}"
    exit 130
}
trap exit_on_signal_interrupt SIGINT

help_msg() {
    echo "Usage: bash build.sh --choose=[Function]"
    echo ""
    echo "Some functions on Origami Kernel Builder:"
    echo "1. Build a whole Kernel"
    echo "2. Regenerate defconfig"
    echo "3. Open menuconfig"
    echo "4. Clean"
    echo ""
    echo "Place this script inside the Kernel Tree."
}

send_msg_telegram() {
  case "$1" in
    1)
      # Dapatkan URL repositori
      repo_url=$(git config --get remote.origin.url)
      # Dapatkan hash commit terakhir
      commit_hash=$(git log --format="%h" -n 1)
      # Buat URL commit
      commit_url="${repo_url}/commit/${commit_hash}"

      curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>——${TIMESTAMP}——</b>
<b>*Build Triggered ${BUILD_HOST}</b>
<b>*Local Ver</b>: <code>T/UDC</code>
<b>*Build status</b>: <code>${kver}</code>
<b>*Builder</b>: <code>${BUILDER}</code>
<b>*Device</b>: <code>${DEVICE}</code>
<b>*Kernel Ver</b>: <code>$(make kernelversion 2>/dev/null)</code>
<b>*Date</b>: <code>$(date)</code>
<b>*Zip</b>: <code>${zipn}</code>
<b>*Defconfig</b>: <code>${DEFCONFIG}</code>
<b>*Clang Ver</b>: <code>${KBUILD_COMPILER_STRING}</code>
<b>*Branch</b>: <code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>*Last Commit</b>: <a href=\"${commit_url}\">${commit_hash}</a>" \
        -o /dev/null
      ;;
    2)
      curl -s -F document=@./out/build.log "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build failed after ${minutes} minutes and ${seconds} seconds." \
        -o /dev/null \
        -w "" >/dev/null 2>&1
      ;;
    3)
      curl -s -F document=@./out/target/"${zipn}".zip "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Fire Build Succes: ${minutes}min & ${seconds}secs." \
        -o /dev/null \
        -w "" >/dev/null 2>&1
      curl -s -F document=@./out/build.log "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build log" \
        -o /dev/null \
        -w "" >/dev/null 2>&1
      ;;
  esac
}


show_defconfigs() {
    defconfig_path="./arch/${ARCH}/configs"

    # Check if folder exists
    if [ ! -d "$defconfig_path" ]; then
        echo -e "${RED}FATAL:${NOCOLOR} Seems not a valid Kernel linux"
        exit 2
    fi

    echo -e "Available defconfigs:\n"

    # List defconfigs and assign them to an array
    defconfigs=($(ls "$defconfig_path"))

    # Display enumerated defconfigs
    for ((i=0; i<${#defconfigs[@]}; i++)); do
        echo -e "${LIGHTCYAN}$i: ${defconfigs[i]}${NOCOLOR}"
    done

    echo ""
    read -p "Select the defconfig you want to process: " choice

    # Check if the choice is within the range of files
    if [ $choice -ge 0 ] && [ $choice -lt ${#defconfigs[@]} ]; then
        export DEFCONFIG="${defconfigs[choice]}"
        echo "Selected defconfig: $DEFCONFIG"
    else
        echo -e "${RED}error:${NOCOLOR} Invalid choice"
        exit 1
    fi
}

compile_kernel() {
    rm ./out/arch/${ARCH}/boot/Image.gz-dtb 2>/dev/null

    export KBUILD_BUILD_USER=${BUILDER}
    export KBUILD_BUILD_HOST=${BUILD_HOST}
    export LOCALVERSION=${localversion}
    export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
    export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
    export CROSS_COMPILE="aarch64-linux-gnu-"

    make O=out ARCH=${ARCH} ${DEFCONFIG}

    START=$(date +"%s")

    make -j"$PROCS" O=out \
        ARCH=${ARCH} \
        LD="${LINKER}" \
        AR=llvm-ar \
        AS=llvm-as \
        NM=llvm-nm \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        CC="clang" \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabihf- \
        CONFIG_NO_ERROR_ON_MISMATCH=y \
        CONFIG_DEBUG_SECTION_MISMATCH=y \
        V=0 2>&1 | tee out/build.log

    END=$(date +"%s")
    DIFF=$((END - START))
    export minutes=$((DIFF / 60))
    export seconds=$((DIFF % 60))
}

zip_kernel() {
    # Move kernel image to anykernel zip
if [ ! -f "./out/arch/${ARCH}/boot/Image.gz-dtb" ]; then
    cp ./out/arch/${ARCH}/boot/Image.gz ./anykernel
else
    cp ./out/arch/${ARCH}/boot/Image.gz-dtb ./anykernel
fi
    # Zip the kernel
    cd ./anykernel
    zip -r9 "${zipn}".zip * -x .git README.md *placeholder
    cd ..

    # Generate checksum of kernel zip
    export checksum=$(sha512sum ./anykernel/"${zipn}".zip | cut -f1 -d ' ')

    if [ ! -d "./out/target" ]; then
        mkdir ./out/target
    fi

if [ ! -f "./out/arch/${ARCH}/boot/Image.gz-dtb" ]; then
    rm -f ./anykernel/Image.gz
else
    rm -f ./anykernel/Image.gz-dtb
fi

    # Move the kernel zip to ./out/target
    mv ./anykernel/${zipn}.zip ./out/target
}

build_kernel() {
    show_defconfigs

    echo -e "${LIGHTBLUE}================================="
    echo "Build Started on ${BUILD_HOST}"
    echo "Build status: ${kver}"
    echo "Builder: ${BUILDER}"
    echo "Device: ${DEVICE}"
    echo "Kernel Version: $(make kernelversion 2>/dev/null)"
    echo "Date: $(date)"
    echo "Zip Name: ${zipn}"
    echo "Defconfig: ${DEFCONFIG}"
    echo "Compiler: ${KBUILD_COMPILER_STRING}"
    echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "Last Commit: $(git log --format="%s" -n 1): $(git log --format="%h" -n 1)"
    echo -e "=================================${NOCOLOR}"

    if [ "$SEND_TO_TG" -eq 1 ]; then
        send_msg_telegram 1
    fi

    compile_kernel

    if [ ! -f "./out/arch/${ARCH}/boot/Image.gz-dtb" ] && [ ! -f "./out/arch/${ARCH}/boot/Image.gz" ]; then
        if [ "$SEND_TO_TG" -eq 1 ]; then
            send_msg_telegram 2
        fi
        echo -e "${LIGHTBLUE}================================="
        echo -e "${RED}Build failed${LIGHTBLUE} after ${minutes} minutes and ${seconds} seconds"
        echo "See build log for troubleshooting."
        echo -e "=================================${NOCOLOR}"
        exit 1
    fi

    zip_kernel

    echo -e "${LIGHTBLUE}================================="
    echo "Build took ${minutes} minutes and ${seconds} seconds."
    echo -e "=================================${NOCOLOR}"

    if [ "$SEND_TO_TG" -eq 1 ]; then
        send_msg_telegram 3
    fi
}

regen_defconfig() {
show_defconfigs
make O=out ARCH=${ARCH} ${DEFCONFIG}
cp -rf ./out/.config ./arch/${ARCH}/configs/${DEFCONFIG}
}

open_menuconfig() {
    show_defconfigs
    make O=out ARCH=${ARCH} ${DEFCONFIG}
    echo -e "${LIGHTGREEN}Note: Make sure you save the config with name '.config'"    
    echo -e "      else the defconfig will not saved automatically.${NOCOLOR}"

    # Removed the countdown loop
    make O=out menuconfig
    cp -rf ./out/.config ./arch/${ARCH}/configs/${DEFCONFIG}
}

execute_operation() {

   loop_helper() {
      read -p "Press enter to continue or type 0 for Quit: " a1
      clear
      if [[ "$a1" == "0" ]]; then
          exit 0
      else
          bash "$0"
      fi
   }

   case "$1" in
        1) clear
            build_kernel
            loop_helper
            ;;
        2) clear
            regen_defconfig
            loop_helper
             ;;
        3) clear
             open_menuconfig
             loop_helper
             ;;
        4) clear
            make clean && make mrproper
            loop_helper
            ;;
        5) exit 0 && clear ;;
        6) help_msg ;;
        *) echo -e "${RED}error:${NOCOLOR} Invalid selection." && exit 1 ;;
    esac
}

if [ $# -eq 0 ]; then
    clear
    echo -e "${LIGHTCYAN}What do you want to do today?"
    echo ""
    echo "1. Build a whole Kernel"
    echo "2. Regenerate defconfig"
    echo "3. Open menuconfig"
    echo "4. Clean"
    echo "5. Quit"
    echo -e "${NOCOLOR}"
    read -p "Choice the number: " choice
else
    case "$1" in
        --choose=1)
            choice=1
            ;;
        --choose=2)
            choice=2
            ;;
        --choose=3)
            choice=3
            ;;
        --choose=4)
            choice=4
            ;;
        --help)
            choice=6
            ;;
        *)
            echo -e "${RED}error:${NOCOLOR} Not a valid argument"
            echo "Try 'bash origami_kernel_builder.sh --help' for more information."
            exit 1
            ;;
    esac
fi

# Main script logic
execute_operation "$choice"
