# FlightHub 2 On-Premises Environment Preparation Script

This script automates the validation and preparation of Ubuntu servers for **DJI FlightHub 2 On-Premises (FH2 OP)** deployments.

It was developed based on DJI's official requirements and practical experience acquired during multiple real-world deployments, helping reduce installation time and prevent common issues before installing FlightHub 2.

---

# Features

- Ubuntu compatibility verification
- CPU instruction set validation
- RAM validation
- Storage validation
- NVIDIA GPU detection
- Exact Docker Engine, Docker Compose, and containerd version validation
- Automatic Docker package version locking after successful validation
- Google Chrome installation and configuration
- Internet and DNS connectivity verification
- NTP time synchronization verification
- Firewall configuration
- Automatic directory structure creation
- Complete execution summary
- Verification-only mode (no system changes)

---

# Supported Operating Systems

- Ubuntu Server 22.04 LTS
- Ubuntu Server 24.04 LTS

---

# Execution Modes

## 1. Verification Only (Recommended)

Runs all environment checks without modifying the system.

```bash
sudo ./setup_fh2VER5.3.1.sh --check-only
```

In this mode, the script:

- validates all installation requirements;
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

## 2. Prepare the Environment

```bash
sudo ./setup_fh2VER5.3.1.sh
```

In addition to validating the system, the script automatically prepares the operating system for a FlightHub 2 On-Premises installation.

---

## 3. Prepare the Environment and Reboot Automatically

```bash
sudo ./setup_fh2VER5.3.1.sh --reboot
```

Performs the complete environment preparation and automatically reboots the server when finished.

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

Version 5.3.1 also improves physical disk detection on systems where `lsblk` displays tree-drawing characters, preventing errors such as:

```text
lsblk: /dev/└─sda: not a block device
```

---

## Docker

The script validates the exact versions of Docker Engine, Docker Compose, and containerd.

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

---

## Internet

Verifies Internet connectivity.

---

## DNS

Verifies DNS name resolution.

---

## Time Synchronization

Checks the NTP synchronization status.

During a normal execution, NTP is automatically enabled.

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

This report allows administrators to quickly identify any requirement that must be addressed before proceeding with the FlightHub 2 installation.

---

# Recommended Workflow

Before starting any FlightHub 2 On-Premises deployment:

```bash
sudo ./setup_fh2VER5.3.1.sh --check-only
```

After resolving every issue reported:

```bash
sudo ./setup_fh2VER5.3.1.sh
```

If you want the server to reboot automatically after the preparation is completed:

```bash
sudo ./setup_fh2VER5.3.1.sh --reboot
```

---

# License

This script was developed to simplify the preparation of Ubuntu environments for **DJI FlightHub 2 On-Premises** deployments.

It is **not intended to replace DJI's official documentation**, but rather to complement the installation process by providing additional validations and automation based on real-world deployment experience.
