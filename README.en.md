# FlightHub 2 On-Premises Environment Preparation Script

This script automates the validation and preparation of Ubuntu servers for **DJI FlightHub 2 On-Premises (FH2 OP)** deployments.

It was developed based on DJI's official requirements and practical experience acquired during multiple real-world deployments, helping reduce installation time and prevent common issues before installing FlightHub 2.

---

# Latest release and download

The latest release is **[v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5)**, published on **2026-10-06**.

Download the release attachment: **[fh2-v5.5-bundle.tar.gz](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz)**.

**Integrity:** the SHA-256 digest of `fh2-v5.5-bundle.tar.gz` is `1a762907e488985dd6d0b2f2f8b3deff6bd800a335c41f70c9ffb230c3b11981`. The `.sha256` file is also attached to the release.

**Release archive checked:** extraction creates `fh2-onprem-prep-tool-v5.5/` with the v5.5 script, `docker.tar.gz`, `SHA256SUMS`, and local bundles for Ubuntu 22.04 and 24.04. The tagged source and the script included in the package refer to the same revision.

## Changes in v5.5

- Added `--offline`, with automatic selection of `packages/ubuntu-$VERSION_ID`.
- Added `--offline-dir PATH` for bundles stored elsewhere.
- Added base dependency and Google Chrome bundles for Ubuntu 22.04 and 24.04.
- Offline APT uses isolated temporary lists and cache, excluding existing external indexes from package resolution.
- Offline mode skips `apt update`, `apt upgrade`, `apt autoremove`, `apt autoclean`, external Internet/DNS tests, and external NTP enablement.
- Docker Engine 27.2.0, Docker Compose 2.29.2, and containerd 1.7.21 are installed locally and locked with `apt-mark hold` after validation.
- Google Chrome 155.0.8059.39 is installed through the local APT repository.
- Added bundle integrity verification through `SHA256SUMS`.
- Generic automatic NVIDIA driver installation remains disabled offline; a GPU without a working driver requires a bundle compatible with the customer's GPU/kernel combination.
- Simplified the Docker bundle by removing a redundant nested copy of the same packages.

### v5.5 validation

- Bash syntax check passed.
- All `.deb` files were validated for readable metadata and architecture.
- The Ubuntu 24.04 base bundle includes `locales` and its dependency chain.
- Ubuntu 24.04 Chrome passed static dependency closure and an APT simulation using only the local repository: 196 installable packages and zero unresolved dependencies.
- Final archive structure, permissions, internal hashes, and compressed file were verified.
- A final installation of the rebuilt bundle on minimal VMs is still recommended before production deployment.

## Changes in v5.4.1

According to the [release notes](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.4.1), also confirmed in the updated `main` source:

- Added `iptables` to the packages installed before Docker.
- Validates the installation state of `iptables` and its version command. Preparation stops before Docker installation if validation fails.
- Checks `iptables`, `docker-ce`, `docker-ce-cli`, and `containerd.io` after installation. All must report `install ok installed` before version validation and locking.
- Stops execution if any of these packages are missing or incompletely configured.
- Initializes version variables to prevent unbound-variable errors when a component is not detected.

The notes report a successful Bash syntax check and simulated tests of different `iptables` states. A full Docker installation was not tested in the environment used for that validation.

## Changes in v5.4

According to the [v5.4 release notes](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.4), also confirmed in the `main` source:

- Protects installed Docker packages with `apt-mark hold` before Ubuntu updates and dependency-repair attempts.
- Unlocks packages in the dedicated installation step, after the user confirms replacement of an existing Docker installation and the required files are verified.
- Keeps the locks when the user chooses to preserve the current installation.
- Reapplies the lock after installation and validation of the expected versions.
- Checks and configures Chrome before the final report, which includes its status and version.

# Download and file preparation

Download and extract the release attachment:

```bash
curl -fL --retry 3 \
  "https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz" \
  -o fh2-v5.5-bundle.tar.gz

tar -xzvf fh2-v5.5-bundle.tar.gz
cd fh2-onprem-prep-tool-v5.5
```

The created directory contains `fh2-onprem-prep-tool-v5.5.sh`, `docker.tar.gz`, `SHA256SUMS`, and `packages/`. Verify integrity first:

```bash
sha256sum -c SHA256SUMS
```

Then run the checks:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

After reviewing the results, prepare the environment offline:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
```

To provide another bundle location:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --offline-dir /mnt/usb/fh2-offline
```

The online flow remains available with `sudo bash fh2-onprem-prep-tool-v5.5.sh`.

To install or replace Docker, keep **`docker.tar.gz` in the same directory as the main script**. It must contain `docker/install_docker.sh` and `docker/uninstall_docker.sh`; these exact paths are validated after extraction.

The repository stores `docker.tar.gz` with **Git LFS**. A small file containing `version https://git-lfs.github.com/spec/v1` is only a pointer, not the installable archive. When using a Git clone, retrieve the LFS content; use the release attachment for the published distribution.

---

# Features

- Ubuntu compatibility verification
- CPU instruction set validation
- RAM validation
- Storage validation
- NVIDIA GPU detection
- Docker package protection before Ubuntu updates
- Exact Docker Engine, Docker Compose, and containerd version validation after installing the recommended package
- Automatic Docker package version locking after successful validation
- Google Chrome installation and configuration
- Internet and DNS connectivity verification
- NTP time synchronization verification
- Firewall configuration
- Automatic directory structure creation
- Complete execution summary
- Verification-only mode (no system changes)
- Offline preparation mode using local dependencies

---

# Supported Operating Systems

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

The code checks the distribution and version in `/etc/os-release`; it does not distinguish Server from Desktop.

---

# Execution Modes

Run the commands below from the `fh2-onprem-prep-tool` directory. Using `sudo bash` does not require changing the script's execute permission.

## 1. Verification Only (Recommended)

Runs the available checks without modifying the system.

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

In this mode, the script:

- checks the items implemented in the script using the tools already available;
- generates a complete environment report.

**No changes are made**, including:

- system updates;
- package installation;
- driver installation;
- Docker installation or removal;
- Google Chrome installation;
- firewall configuration;
- locale configuration;
- timezone configuration;
- NTP configuration;
- directory creation;
- system reboot.

---

The `--check-only` mode does not validate all three exact Docker component versions or confirm existing APT locks. It detects the Docker major version and Compose availability. If `--reboot` is also supplied, reboot is ignored.

## 2. Prepare the Environment

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

In addition to validating the system, the script automatically prepares the operating system for a FlightHub 2 On-Premises installation.

---

## 3. Prepare the Environment and Reboot Automatically

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --reboot
```

Performs the complete environment preparation and automatically reboots the server when finished.

---

## 4. Prepare the Environment Without Internet Access

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
```

The script automatically selects `packages/ubuntu-22.04` or `packages/ubuntu-24.04`. Use `--offline-dir PATH` to provide another bundle.

---

# What Does the Script Verify?

## Operating System

Confirms that the server is running a supported Ubuntu version.

---

## CPU

The following CPU instruction sets are verified:

- SSE4.2
- POPCNT
- AVX
- AVX2

These instruction sets are mandatory for proper FlightHub 2 operation.

If any of them are missing, the installation may fail.

The most common symptom observed is the **tas-service** container remaining in the **Unhealthy** state.

---

## Memory (RAM)

To use the **Terra Reconstruction Module**, the server should have **more than 32 GB of allocated RAM**.

### More than 32 GB

Recommended for:

- FlightHub 2
- Terra Reconstruction

### 32 GB or Less

Suitable only for:

- FlightHub 2

If Terra is installed on a server with 32 GB or less, reconstruction tasks may remain permanently in the following state:

```
Pending
```

---

## Storage

The script performs two independent storage validations.

### Available Disk Space

At least:

```
300 GB of free space
```

is required.

This space is used during installation for:

- Docker images;
- databases;
- temporary files;
- FlightHub components.

---

### Physical Disk Capacity

The physical disk hosting Ubuntu should have a minimum capacity of:

```
1 TB
```

This recommendation ensures sufficient space for:

- databases;
- images;
- videos;
- logs;
- reconstruction results;
- future system growth.

In the inspected source, capacity is calculated by dividing bytes by `1024³` and compared with `1000`; a commercial 1 TB disk (approximately 931 GiB) may therefore be flagged as below the minimum. Free space is checked on `/` with `df -BG`, using a threshold of 300.

Version 5.3.1 also improves physical disk detection on systems where `lsblk` displays tree-drawing characters, preventing errors such as:

```text
lsblk: /dev/└─sda: not a block device
```

---

## Docker

During normal preparation, installed Docker packages are protected before `apt upgrade` and dependency repairs. Existing locks are preserved at this stage. If Docker or Compose is already present, replacement requires confirmation; the default answer keeps the current installation.

When keeping the existing Docker installation, package locks remain, but the script does not perform the exact three-component version check. After installing the recommended package, it validates the exact versions of Docker Engine, Docker Compose, and containerd.

Approved versions:

```text
Docker Engine 27.2.0
Docker Compose 2.29.2
containerd 1.7.21
```

After installing and validating these versions, the script locks the following APT packages using `apt-mark hold`:

- `docker-ce`
- `docker-ce-cli`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- `containerd.io`

The lock is applied only when all installed versions match the approved package. If any version differs, the script displays the expected and detected versions and stops the preparation process. This prevents an incorrect Docker installation from being locked.

The package lock prevents routine commands such as `apt upgrade` and `apt full-upgrade` from automatically changing the Docker versions required by FlightHub 2 On-Premises.

**Docker 29 is not supported.**

During real-world deployments, Docker 29 has been observed to cause fatal errors in the FlightHub 2 frontend.

---

## NVIDIA GPU

If an NVIDIA GPU is detected, the script verifies whether the appropriate driver is installed.

During a normal execution, the recommended NVIDIA driver is installed automatically whenever necessary.

In offline mode, generic automatic NVIDIA driver installation is deliberately disabled. If a GPU is detected without a working driver, preparation stops and requests a bundle compatible with the customer's GPU and kernel.

---

## Internet

Verifies Internet connectivity.

This external check is skipped in offline mode.

---

## DNS

Verifies DNS name resolution.

This external check is skipped in offline mode.

---

## Time Synchronization

Checks the NTP synchronization status.

During a normal execution, NTP is automatically enabled.

Offline mode does not automatically enable external NTP; use an internal NTP server when required.

---

## Firewall

Checks the UFW firewall status.

During a normal execution, UFW is automatically disabled.

---

# Directory Structure

The following directories are created during the preparation process:

```
/
├── fhop-install/
│   └── install/
│
├── data/
│   └── fhop-data/
│
├── terra-install/
│
└── 4G-install/
```

---

# Changes Performed During Preparation

When executed **without** the `--check-only` option, the script may:

- Update Ubuntu packages;
- Repair broken APT dependencies;
- Install required utilities;
- Install or replace Docker Engine, Docker Compose, and containerd with the approved versions;
- Lock the validated Docker packages to prevent automatic upgrades;
- Install and configure Google Chrome (`--no-sandbox`);
- Install the recommended NVIDIA driver;
- Configure the system locale to `en_US.UTF-8`;
- Configure the timezone to `America/Sao_Paulo`;
- Enable NTP synchronization;
- Disable the UFW firewall;
- Create the complete directory structure required by FlightHub 2.

---

# Final Report

At the end of execution, the script displays a summary containing:

- Execution mode;
- Ubuntu version;
- CPU model;
- CPU compatibility;
- RAM;
- Physical disk capacity;
- Available disk space;
- NVIDIA GPU;
- NVIDIA driver;
- Internet status;
- DNS status;
- Firewall status;
- Docker status;
- Docker version lock status;
- Google Chrome status;
- Directory creation status.

Also review each step's messages. In the current source, Internet and DNS appear as `OK` in the summary even after a failed check if execution continues; virtualization remains `Nao verificada` (not checked). The report is not a complete environment certification.

---

# Recommended Workflow

Before starting any FlightHub 2 On-Premises deployment:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

After resolving every issue reported:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

If you want the server to reboot automatically after the preparation is completed:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --reboot
```

---

# About the project

This script was developed to simplify the preparation of Ubuntu environments for **DJI FlightHub 2 On-Premises** deployments.

It is **not intended to replace DJI's official documentation**, but rather to complement the installation process by providing additional validations and automation based on real-world deployment experience.
