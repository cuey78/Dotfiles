#!/bin/bash
configure_hugepages() {
    local memory_gb="$1"    # Memory size in GB (passed as an argument)
    local page_size_kb=2048 # Default HugePage size (2 MB)
    local fstab_entry="hugetlbfs /dev/hugepages hugetlbfs mode=01770,gid=kvm 0 0"

    # Validate input
    if [[ -z "$memory_gb" || ! "$memory_gb" =~ ^[0-9]+$ ]]; then
        echo "Error: Please provide the desired memory size in GB as an argument."
        return 1
    fi

    # Calculate the required number of HugePages
    local memory_kb=$((memory_gb * 1024 * 1024))
    local required_pages=$((memory_kb / page_size_kb))
    echo "Configuring HugePages for ${memory_gb} GB memory..."
    echo "HugePages required: $required_pages"

    # Update sysctl configuration for HugePages
    echo "vm.nr_hugepages=$required_pages" >> /etc/sysctl.conf
    sysctl -p > /dev/null

    # Check if fstab entry already exists
    if ! grep -q "hugetlbfs" /etc/fstab; then
        echo "Adding hugetlbfs entry to /etc/fstab..."
        echo "$fstab_entry" >> /etc/fstab
    else
        echo "hugetlbfs entry already exists in /etc/fstab."
    fi

    # Create the mount point if it doesn't exist
    if [[ ! -d "/dev/hugepages" ]]; then
        echo "Creating mount point /dev/hugepages..."
        mkdir -p /dev/hugepages
        chmod 1770 /dev/hugepages
        chgrp kvm /dev/hugepages
    fi

    # Mount hugetlbfs
    echo "Mounting hugetlbfs..."
    mount -a

    # Verify configuration
    echo "HugePages configuration:"
    grep Huge /proc/meminfo
}

