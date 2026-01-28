# i915-sriov-dkms User Guide

This guide helps you install and configure Intel GPU SR-IOV support on Gentoo Linux using DKMS.

## Prerequisites

Before installing, ensure your system meets the following requirements:

### Hardware Requirements
- **Intel GPU only** - This package does NOT support AMD GPUs
- GPU must support SR-IOV functionality (check Intel documentation for your specific model)

### Kernel Requirements
- **Minimum kernel version**: 6.12.x
  ```bash
  uname -r
  ```

### Required Kernel Configuration Options
Ensure these options are enabled in your kernel (`.config` or `make menuconfig`):

```
CONFIG_DRM_I915=m          # Intel graphics driver as module
CONFIG_IOMMU_SUPPORT=y     # IOMMU support
CONFIG_INTEL_IOMMU=y       # Intel IOMMU driver
CONFIG_PCI_IOV=y           # PCI SR-IOV support
```

To check your current kernel configuration:
```bash
zcat /proc/config.gz | grep -E "DRM_I915|IOMMU_SUPPORT|PCI_IOV"
```

**Note**: If any required option is missing, rebuild your kernel before proceeding.

---

## Installation

### Installing the Package

Install the stable version (recommended):
```bash
emerge sys-kernel/i915-sriov-dkms
```

Or install the live development version (bleeding edge):
```bash
echo "sys-kernel/i915-sriov-dkms **" >> /etc/portage/package.accept_keywords/i915-sriov-dkms
emerge sys-kernel/i915-sriov-dkms
```

### What Happens During Installation

1. **DKMS module compilation**: The kernel modules are compiled against your current kernel
2. **Module installation**: Compiled modules are installed to the kernel module directory
3. **Documentation installation**: Example config files are placed in `/usr/share/doc/${PF}/`

**Common warnings you may see**:
- If you don't have DKMS installed, emerge will fail with an error
- If your kernel headers don't match your running kernel, warnings will appear
- Module signing warnings on secure boot systems (see Troubleshooting)

---

## Configuration

### Required Kernel Parameters

Add these parameters to your bootloader configuration:

```
intel_iommu=on
i915.enable_guc=3
i915.max_vfs=7
```

### Adding to Bootloader

#### GRUB2
Edit `/etc/default/grub`:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on i915.enable_guc=3 i915.max_vfs=7"
```

Then update GRUB:
```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

#### systemd-boot
Edit your bootloader entry file (e.g., `/boot/loader/entries/gentoo.conf`):
```
options intel_iommu=on i915.enable_guc=3 i915.max_vfs=7
```

#### Syslinux
Edit `/boot/syslinux.cfg`:
```
APPEND intel_iommu=on i915.enable_guc=3 i915.max_vfs=7
```

### Example Configuration Files

Example configurations are installed to:
```
/usr/share/doc/i915-sriov-dkms-<version>/
```

Review these files for reference:
- `grub.conf.example` - GRUB2 configuration
- `syslinux.cfg.example` - Syslinux configuration
- `sriov.conf.example` - SR-IOV setup script

**After updating bootloader, reboot your system.**

---

## Loading Modules

### Manual Module Loading

After reboot, load the required modules:

```bash
# Load the main SR-IOV compatibility module
modprobe intel_sriov_compat

# The i915 module should be loaded automatically
# If not, load it manually
modprobe i915
```

### Verifying Modules are Loaded

Check that modules are loaded:
```bash
# List loaded modules
lsmod | grep i915
lsmod | grep sriov

# Check kernel messages for SR-IOV initialization
dmesg | grep sriov
dmesg | grep i915
```

Expected output shows modules loaded without errors.

### Troubleshooting Module Loading

If modules fail to load:

1. **Check module dependencies**:
   ```bash
   modprobe -c | grep i915
   ```

2. **Load with verbose output**:
   ```bash
   modprobe -v intel_sriov_compat
   ```

3. **Check for errors in dmesg**:
   ```bash
   dmesg | tail -n 50
   ```

4. **Try loading in debug mode**:
   ```bash
   modprobe intel_sriov_compat debug=1
   ```

---

## Configuring SR-IOV

### Check Current VF Configuration

First, identify your GPU device:
```bash
lspci | grep -i vga
```

Look for Intel GPU device (typically 0000:00:02.0, but may vary).

Check current number of VFs:
```bash
cat /sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs
```

If this returns `0`, no VFs are currently configured.

### Set Number of Virtual Functions

Write the desired number of VFs to sysfs:
```bash
# Set 7 VFs (max recommended)
echo 7 | sudo tee /sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs

# Or use a different number (1-7)
echo 4 | sudo tee /sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs
```

**Note**: The device path (`/sys/devices/pci0000:00/0000:00:02.0/`) may differ on your system. Adjust accordingly.

### Using Example Configuration

The package includes a setup script:
```bash
# Example configuration script location
/usr/share/doc/i915-sriov-dkms-<version>/sriov_setup.sh
```

Review and adapt for your system:
```bash
cat /usr/share/doc/i915-sriov-dkms-*/sriov_setup.sh
```

### Verify VF Creation

Check that VFs are visible:
```bash
# Show all PCI devices including VFs
lspci | grep "Intel.*VGA"

# Detailed view of GPU device and VFs
lspci -vvv -d 8086 | grep -A 20 "SR-IOV"
```

Expected output should show multiple virtual functions under your GPU.

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Modules fail to load
**Symptom**: `modprobe` fails with error

**Solutions**:
1. Verify kernel version is 6.12.x or later
2. Check kernel config has required options enabled
3. Ensure DKMS modules compiled successfully:
   ```bash
   dkms status
   ```
4. Rebuild modules if needed:
   ```bash
   emerge --oneshot sys-kernel/i915-sriov-dkms
   ```

#### Issue: VFs not created (sriov_numvfs shows 0)
**Symptom**: Can't set VFs, or setting VFs fails

**Solutions**:
1. Verify IOMMU is enabled:
   ```bash
   dmesg | grep -i iommu
   ```
2. Check kernel parameters are applied (reboot if necessary)
3. Ensure GPU supports SR-IOV (check Intel documentation)
4. Try debug mode:
   ```bash
   modprobe intel_sriov_compat debug=1
   dmesg | tail
   ```

#### Issue: Secure boot blocks modules
**Symptom**: Module load fails with signature errors

**Solutions**:
1. Disable secure boot in BIOS/UEFI
2. Sign your kernel modules (advanced)
3. Add modules to MOK list (Machine Owner Key)

#### Issue: Kernel version mismatch
**Symptom**: Modules compiled against different kernel version

**Solutions**:
1. Update kernel to match headers:
   ```bash
   emerge sys-kernel/gentoo-sources
   ```
2. Or rebuild DKMS modules after kernel upgrade:
   ```bash
   emerge --oneshot sys-kernel/i915-sriov-dkms
   ```

### Debug Mode

Enable detailed logging:
```bash
# Unload module first
modprobe -r intel_sriov_compat

# Load with debug enabled
modprobe intel_sriov_compat debug=1

# Check logs
dmesg | grep -i sriov
```

### Getting Help

- Check the project's GitHub issues for known problems
- Review logs: `dmesg`, `/var/log/Xorg.0.log`
- Verify all prerequisites are met before reporting issues

---

## Important Warnings

###  Read Before Proceeding

**This is experimental software.** Use with caution on production systems.

### Critical Requirements

1. **Host AND Guest Installation Required**
   - SR-IOV requires installing this package on BOTH:
     - The host system (hypervisor)
     - The guest system (VM that will use the VF)
   - Without both installations, SR-IOV will not work properly

2. **Backup Your System**
   - Create full system backup before installing
   - Test on non-production systems first
   - Keep a live USB ready for recovery

3. **Potential Stability Issues**
   - SR-IOV can cause system instability
   - May affect graphics performance on host
   - Some applications may not work correctly with VFs

4. **Limited GPU Models**
   - Not all Intel GPUs support SR-IOV
   - Check Intel documentation for your specific GPU model
   - AMD GPUs are NOT supported

5. **Kernel Compatibility**
   - Only kernel 6.12.x and later are supported
   - Upgrading kernel may break SR-IOV
   - Rebuild DKMS modules after kernel updates

### Known Limitations

- Maximum of 7 virtual functions (hardware limitation)
- Performance overhead when using VFs
- Some graphics features may be unavailable in VFs
- Hot-plug of VFs may not work reliably

### When NOT to Use This Package

- On systems without recent Intel GPUs
- If you need stable, production-ready graphics virtualization
- On systems with older kernels (< 6.12.x)
- If you're not comfortable troubleshooting kernel modules

---

## Uninstallation

### Remove the Package

Completely remove the i915-sriov-dkms package:
```bash
emerge -C sys-kernel/i915-sriov-dkms
```

### Cleanup Procedures

1. **Unload modules before removal**:
   ```bash
   modprobe -r intel_sriov_compat
   modprobe -r i915
   ```

2. **Remove kernel parameters from bootloader**:
   - Edit your bootloader config (GRUB, systemd-boot, or Syslinux)
   - Remove: `intel_iommu=on i915.enable_guc=3 i915.max_vfs=7`
   - Update bootloader configuration
   - Reboot

3. **Remove DKMS modules**:
   ```bash
   dkms remove i915-sriov/1.0 --all
   ```

4. **Check for leftover files**:
   ```bash
   # Check for remaining module files
   find /lib/modules/$(uname -r) -name "*sriov*"

   # Check for config files
   ls /etc/modprobe.d/*sriov*
   ```

5. **Remove any custom configs**:
   ```bash
   rm -f /etc/modprobe.d/i915-sriov.conf
   ```

### Verification

Verify clean removal:
```bash
# Check no SR-IOV modules loaded
lsmod | grep sriov

# Check package is removed
emerge -p sys-kernel/i915-sriov-dkms

# Check for leftover files
find /lib/modules/$(uname -r) -name "*sriov*" 2>/dev/null
```

If any files remain, manually remove them and verify your system works normally.

---

## Additional Resources

- Example configurations: `/usr/share/doc/i915-sriov-dkms-<version>/`
- Project documentation and issues: Check GitHub repository
- Intel GPU documentation: Intel official website
- DKMS documentation: https://wiki.gentoo.org/wiki/DKMS

For the latest updates and community support, refer to the project's GitHub repository.
