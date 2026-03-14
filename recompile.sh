#!/bin/bash

set -euo pipefail

# Variáveis
VCPKG_PATH=${1:-"$HOME"}
VCPKG_PATH=$VCPKG_PATH/vcpkg/scripts/buildsystems/vcpkg.cmake
ARCHITECTURE=$(uname -m)
OS=$(uname -s)
if [[ $OS == "Darwin" ]]; then
	BUILD_TYPE=${2:-"macos-release"}
elif [[ $ARCHITECTURE == "aarch64"* ]]; then
	BUILD_TYPE=${2:-"arm64-linux-release"}
else
	BUILD_TYPE=${2:-"linux-release"}
fi
ARCHITECTUREVALUE=0

# Function to print information messages
info() {
	echo -e "\033[1;34m[INFO]\033[0m $1"
}

# Function to check if a command is available
check_command() {
	if ! command -v "$1" >/dev/null; then
		echo "The command '$1' is not available. Please install it and try again."
		exit 1
	fi
}

check_architecture() {
	if [[ $OS == "Darwin" ]]; then
		info "its architecture is $ARCHITECTURE (macOS)"
	elif [[ $ARCHITECTURE == "aarch64"* ]]; then
		info "its architecture is $ARCHITECTURE (ARM)"
		ARCHITECTUREVALUE=1
	else
		info "its architecture is $ARCHITECTURE"
	fi
}

# Function to configure Canary
setup_canary() {
	if [ -d "build" ]; then
		cd build
		info "Build directory already exists, reusing it..."
	else
		mkdir -p build && cd build
	fi
}

# Function to build Canary
build_canary() {
	info "Configuring Canary..."
	if [[ $ARCHITECTUREVALUE == 1 ]]; then
		export VCPKG_FORCE_SYSTEM_BINARIES=1
	fi
	cmake -DCMAKE_TOOLCHAIN_FILE="$VCPKG_PATH" .. --preset "$BUILD_TYPE" >cmake_log.txt 2>&1 || {
		cat cmake_log.txt
		return 1
	}

	info "Starting the build process..."

	local total_steps=0
	local progress=0
	local build_status=0

	global_beats=0
	local temp_file="temp_global_beats.txt"
	echo "0" >$temp_file

	cmake --build "$BUILD_TYPE" -j 2 || build_status=1

	if [[ $build_status -eq 0 ]]; then
		return 0
	else
		echo
		cat build_log.txt
		return 1
	fi
}

# Function to move the generated executable
move_executable() {
	local executable_name="canary"
	cd ..
	info "Finding the executable locations..."
	find ./build/"$BUILD_TYPE" -name "$executable_name" || true
	
	if [ -e "$executable_name" ]; then
		info "Saving old build"
		mv ./"$executable_name" ./"$executable_name".old
	fi
	info "Moving the generated executable to the canary folder directory..."
	cp ./build/"$BUILD_TYPE"/bin/"$executable_name" ./"$executable_name"
	info "Build completed successfully!"
}

# Main function
main() {
	check_command "cmake"
	check_architecture
	setup_canary

	if build_canary; then
		move_executable
	else
		echo -e "\033[31m[ERROR]\033[0m Build failed..."
		exit 1
	fi
}

main
