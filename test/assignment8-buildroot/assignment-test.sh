#!/bin/bash
# 1st argument: absolute or relative path to the base directory

cd `dirname $0`

source script-helpers

script_dir="$(pwd -P )"
testdir=$1
rootfs_path=/usr/bin/

# Invoke docker script with --env SKIP_BUILD=1 --env DO_VALIDATE=1 to perform a validation only
# test
echo "starting test with SKIP_BUILD ${SKIP_BUILD} and DO_VALIDATE ${DO_VALIDATE}"
if [[ -z ${SKIP_BUILD} || ${SKIP_BUILD} -eq 0 ]]; then
	pushd ${testdir}
    . ${script_dir}/buildroot-common-build.sh
    rc=$?
    echo "build step complete with status $?"
    echo "Validation errors ${validate_error}"
	popd
fi

add_to_rootfs "${script_dir}/drivertest.sh" "${rootfs_path}"

if [[ -z ${DO_VALIDATE} || ${DO_VALIDATE} -eq 1 ]]; then
    echo "Starting validation step"
	pushd ${testdir}

	# Running qemu instance in background
	validate_qemu

	# Validating test cases inside qemu
	validate_assignment7_qemu "${script_dir}"

	validate_driver

	validate_application "${script_dir}"

	echo "Killing qemu"
	killall qemu-system-aarch64
	popd
fi

if [ ! -z "${validate_error}" ]; then
    echo "Validation failed with error list ${validate_error}"
    exit 1
fi
exit 0
