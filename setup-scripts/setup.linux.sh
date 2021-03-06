#!/bin/bash

# This script helps download the required packages required to compile 
# the source file in the supported programming languages and build 
# the operating system. The following programming languages are currently 
# supported by QOMB 
# - C
# - C++
# - Rust
# - Go
# 
# Optionally you can install supplementary packages to convert the bin
# file into .iso and visualbox package to install the OS.
# 
# License: MIT
# Author: Adewale Azeez <azeezadewale98@gmail.com>

# with execution scripts check for qemu name e.g. qemu, qemu-system-i386 e.t.c.
# should send the build.linx.sh as qomb-build and run.linux.sh as qomb-run to the 
# system path 

ARG=
YEAR=2021
ARG_MATCH=
LOUD=false
LICENSE=MIT
VERSION=v1.0
EXTRACTED_ARG_VALUE=
AUTHOR="Adewale Azeez"
INSTALL_SUPPLEMENTARY=false
SELECTED_PROGRAMMING_LANGUAGES=()
SUPPORTED_PROGRAMMING_LANGUAGES=(
    c
    c++
    rust
    go
)

echo "QOMB Setup Script $VERSION"
echo "The $LICENSE License Copyright (c) $YEAR $AUTHOR"

main()
{
    for ARG in "$@"
    do
        match_and_extract_argument $ARG
        if [[ "-h" == "$ARG_MATCH" || "--help" == "$ARG_MATCH" ]]; then
            print_help

        elif [[ "-l" == "$ARG_MATCH" || "--loud" == "$ARG_MATCH" ]]; then
            LOUD=true

        elif [[ "--install-supplement" == "$ARG_MATCH" ]]; then
            INSTALL_SUPPLEMENTARY=true

        elif [[ "--lang" == "$ARG_MATCH" ]]; then
            if [[ ! " ${SUPPORTED_PROGRAMMING_LANGUAGES[@]} " =~ " ${EXTRACTED_ARG_VALUE} " ]]; then
                fail_with_message "Unsupported programming language: '$EXTRACTED_ARG_VALUE'"
            fi
            SELECTED_PROGRAMMING_LANGUAGES+=($EXTRACTED_ARG_VALUE)

        else
            fail_with_message "Unknow option '$ARG_MATCH'"

        fi
    done
    update_apt
    install_essential_packages
    for PROGRAMMING_LANGUAGE in ${SELECTED_PROGRAMMING_LANGUAGES[@]}; do
        if [[ "$PROGRAMMING_LANGUAGE" == "c" || "$PROGRAMMING_LANGUAGE" == "c++" ]]; then
            install_c_cpp_packages
        elif [[ "$PROGRAMMING_LANGUAGE" == "rust" ]]; then
            install_rust_packages
        elif [[ "$PROGRAMMING_LANGUAGE" == "go" ]]; then
            install_go_packages
        fi
    done
    if [[ "$INSTALL_SUPPLEMENTARY" == "true" ]]; then
        install_supplement_packages
    fi
}

match_and_extract_argument() {
    ARG=$1
    ARG_MATCH=${ARG%=*}
    EXTRACTED_ARG_VALUE=${ARG#*=}
}

# Update the apt-get repositories url
update_apt()
{
    echo -n "Updating apt-get repositories..."
    if [[ "$LOUD" == "false" ]]; then
        apt-get -y update > /dev/null
        apt-get -y --fix-broken install > /dev/null
        echo "done"
    else
        apt-get update
        apt-get -y --fix-broken install
    fi
}

# This function installs the essential packages needed to build the 
# compile the assembly sources and link the object file to create the 
# operating system, also install qemu which is usefull for booting into 
# the created operating system.
install_essential_packages()
{
    echo "installing the essential packages"
    if [[ "$LOUD" == "false" ]]; then
        apt-get install -y nasm > /dev/null
        apt-get install -y build-essential > /dev/null
        apt-get install -y qemu qemu-system > /dev/null
        echo "nasm, build-essential, qemu, qemu-system...done"
    else
        apt-get install -y nasm
        apt-get install -y build-essential
        apt-get install -y qemu qemu-system
    fi
}

# Install the C and C++ packages neccasary to compile the C and C++ 
# source code into object file to be linked with the kernel.asm 
# object file. Add the option --lang=c or --lang=cpp to install 
# these packages
install_c_cpp_packages()
{
    echo "installing the c and c++ packages"
    if [[ "$LOUD" == "false" ]]; then
        apt-get install -y gcc > /dev/null
        echo "gcc...done"
    else
        apt-get install -y gcc
    fi
}

# Install the Rust packages neccasary to compile the Rust
# source code into object file to be linked with the kernel.asm 
# object file. Add the option --lang=rust to install 
# these packages
install_rust_packages()
{
    echo "installing the rust packages"
    if [[ "$LOUD" == "false" ]]; then
        curl https://sh.rustup.rs -sSf | sh > /dev/null
        echo "rustc...done"
    else
        curl https://sh.rustup.rs -sSf | sh
    fi
    source $HOME/.cargo/env
    rustup target install i686-unknown-linux-gnu
}

# Install the Go packages neccasary to compile the Go
# source code into object file to be linked with the kernel.asm 
# object file. Add the option --lang=go to install 
# these packages
install_go_packages()
{
    echo "installing the go packages"
    if [[ "$LOUD" == "false" ]]; then
        apt-get install -y golang-go > /dev/null
        echo "golang-go...done"
    else
        apt-get install -y golang-go
    fi
}

# Install supplement packages that are not crucial to the environment but 
# are useful for executing extra step. E.g. the grub package to convert 
# the .bin file into .iso and virtualbox package for you know the fine  
# click click.. virtualization.
#
# It important to install the supplement if you intend to convert your 
# binary file into ISO. add the option `--install-supplement` to the script
# to install the suplementary packages.
install_supplement_packages()
{
    echo "installing the supplementary packages"
    if [[ "$LOUD" == "false" ]]; then
        apt-get install -y virtualbox > /dev/null
        apt-get install -y grub > /dev/null
        echo "virtualbox, grub...done"
    else
        apt-get install -y virtualbox
        apt-get install -y grub
    fi
}

# print the help message that shows the options accepted by this script
print_help()
{
    echo "Usage: sudo bash ./setup.linux.sh [OPTIONS]"
    echo ""
    echo "[OPTIONS]    : The script options"
    echo ""
    echo "The OPTIONS include:"
    echo "--install-supplement  Install supplement packages like virtualbox, grub e.t.c"
    echo "--lang=[LANGUAGE]     The language to setup the environment for. See the LANGUAGE list below"
    echo "-h --help             Display this help message and exit"
    echo "-l --loud             Echo garbage + meaningful info into the terminal"
    echo ""
    echo "The LANGUAGE includes:"
    echo "c"
    echo "c++"
    echo "rust"
    echo "go"
    echo ""
    echo "Examples"
    echo "sudo bash ./setup.linux.sh --lang=c"
    echo "sudo bash ./setup.linux.sh --lang=c --lang=rust --lang=go"
    echo "sudo bash ./setup.linux.sh --lang=c --install-supplement"
    exit 0
}

# Print the first argument and exit with code 1
fail_with_message() {
    echo -e "Error: $1"
    exit 1
}

main $@
exit 0