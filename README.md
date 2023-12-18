# ubuntu_vmware_scripts

If VMware Workstation or VMware Player was installed on Ubuntu 22.04, and it initially functioned flawlessly. However once updated the Linux kernel version, an error may occur when attempting to start VMware Workstation or VMware Player. The error message is 'the module vmmon is not found or not loaded.' This issue arises because VMware Workstation and VMware Player require the recompilation of several modules to accommodate kernel updates.

The script automates the process to address this problem.

Usage:
vmware_compile.sh [VMware Workstation|Player version] [Path to download VMware host modules]

Example:
sudo bash vmware.sh workstation-17.0.2 /tmp

what is in the scripts:
1. Update and upgrade installed libs/modules to the latest:
This step ensures that all installed libraries and kernel modules are up to date. It typically involves running commands like sudo apt update and sudo apt upgrade to fetch and install the latest updates for your Ubuntu system.

2. Download and compile the modules: vmmon and vmnet if needed:
If needed, the script would download the source code for these modules and compile them to match the new kernel version. This ensures that VMware workstation or VMware Player can function correctly with the updated kernel.

3. Update the path for missing libs if any lib missed:
In some cases, after a kernel update, library paths might change, and this can cause issues when running VMware workstation or VMware Player. This step checks for missing or outdated library paths and updates them as necessary to ensure that VMware can locate and use the required libraries.

4. Sign compiled VMware modules if secure boot is enabled:
If Secure Boot is enabled on your system, it requires kernel modules to be signed to ensure system security. This step would involve signing the compiled 'vmmon' and 'vmnet' modules so that they are accepted by the Secure Boot process. This is crucial for VMware to function on systems with Secure Boot enabled.

These steps together aim to automate the process of resolving issues that commonly occur when a Linux kernel is updated, which can lead to incompatibility problems with VMware Workstation or VMware Player. The script ensures that necessary modules are compiled, libraries are correctly configured, and, if needed, security measures like signing modules are applied to maintain system functionality.
