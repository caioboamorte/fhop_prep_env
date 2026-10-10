# FlightHub 2 On-Premises Environment Preparation

Two variants prepare Ubuntu 22.04/24.04 for DJI FlightHub 2 On-Premises. They validate and configure the environment; FlightHub 2 and Terra are installed separately.

## Which variant should I use?

| Situation | Recommended variant | Required files |
| --- | --- | --- |
| Server can reach Ubuntu, Docker and Google package sources | **v5.5 Online** | Only `fh2-onprem-prep-tool-v5.5-online.sh` |
| Server has no Internet or external downloads are blocked | **v5.5 bundle**, with `--offline` | Full release bundle: script, `docker.tar.gz`, `SHA256SUMS`, and `packages/` |
| Bundle is already available and Internet will be used for Ubuntu, Chrome and NVIDIA | **v5.5 bundle**, without `--offline` | Local Docker bundle is still required for Docker installation/replacement |

**v5.5 Online is available on the `v5.5-online` branch, under review in [PR #1](https://github.com/caioboamorte/fhop_prep_env/pull/1), and has no release yet.** The bundle variant is distributed in [release v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5). The `-online` suffix identifies the variant that also downloads Docker from the Internet.

## 1. v5.5 Online: download and run

Use this variant when all components can be downloaded on the server. No `docker.tar.gz` or local package bundle is required.

Run in the Ubuntu terminal:

```bash
curl -fL --retry 3 \
  "https://raw.githubusercontent.com/caioboamorte/fhop_prep_env/v5.5-online/fh2-onprem-prep-tool-v5.5-online.sh" \
  -o fh2-onprem-prep-tool-v5.5-online.sh

sudo bash fh2-onprem-prep-tool-v5.5-online.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5-online.sh
```

Run `--check-only` first, review the report, then run preparation. Using `sudo bash` does not require `chmod`.

To reboot automatically after preparation:

```bash
sudo bash fh2-onprem-prep-tool-v5.5-online.sh --reboot
```

This variant:
- downloads Ubuntu dependencies and Chrome;
- installs the recommended NVIDIA driver when a GPU is detected without a working driver;
- configures the official Docker repository and selects Engine/CLI **27.2.0**, Compose **2.29.2**, containerd **1.7.21**, and Buildx **0.16.2**;
- downloads the five Docker packages before removing conflicting packages; additional dependencies are resolved online during installation;
- stops installation if an exact requested version is unavailable, without falling back to latest;
- keeps an existing installation when the three main versions already match and applies `apt-mark hold`;
- asks before changing an existing Docker installation, including downgrade. Installation may restart Docker and interrupt containers.

It does not accept `--offline` or `--offline-dir`. The server needs access to package sources as well as access to download the script.

## 2. v5.5 bundle: download and prepare offline

Download the **`fh2-v5.5-bundle.tar.gz` release attachment** on a connected computer. Transfer the full archive to the server using USB, SCP or another method, then verify and extract it on the server.

The complete workflow below includes the download step, which must run on the connected computer:

```bash
curl -fL --retry 3 \
  "https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz" \
  -o fh2-v5.5-bundle.tar.gz

echo "1a762907e488985dd6d0b2f2f8b3deff6bd800a335c41f70c9ffb230c3b11981  fh2-v5.5-bundle.tar.gz" | sha256sum -c -

tar -xzvf fh2-v5.5-bundle.tar.gz
cd fh2-onprem-prep-tool-v5.5
sha256sum -c SHA256SUMS

sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --check-only
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
```

**On the offline server, start with `echo ... | sha256sum -c -` after transferring the archive.** The combined `--offline --check-only` command checks the environment without changes or external Internet/DNS tests.

Extraction creates `fh2-onprem-prep-tool-v5.5/`. Keep the script and `docker.tar.gz` together. The script selects `packages/ubuntu-22.04` or `packages/ubuntu-24.04` automatically.

For base and Chrome packages stored elsewhere, provide the directory containing `base/` and `chrome/`:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --offline-dir /mnt/usb/fh2-offline
```

`--offline-dir` also enables offline mode. It does not relocate `docker.tar.gz`, which must remain beside the script.

Offline mode:
- resolves dependencies using isolated local APT lists and cache;
- skips general Ubuntu updates and external downloads;
- skips external Internet/DNS tests and external NTP enablement;
- installs Docker components, Chrome and base dependencies from the bundle;
- does not automatically install NVIDIA drivers. Prepare a GPU/kernel-compatible driver separately when required;
- checks the internal `SHA256SUMS` manifest when present.

To reboot after preparation:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --reboot
```

**Do not substitute GitHub's “Source code (zip/tar.gz)” downloads for the release attachment.** The repository's `docker.tar.gz` uses Git LFS and may be only a small pointer file; use the published bundle.

## 3. Using the bundle with Internet

The bundle script can also run without `--offline`:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

Ubuntu dependencies, NVIDIA drivers and Chrome may be downloaded online, but Docker installation/replacement still requires local `docker.tar.gz`. Choose **v5.5 Online** to download Docker as well.

## Options and limitations

| Option | v5.5 Online | v5.5 bundle |
| --- | --- | --- |
| `--check-only` | Checks without changes | Checks without changes; combine with `--offline` on isolated servers |
| `--reboot` | Reboots after preparation | Reboots after preparation |
| `--offline` | Not available | Uses local packages and skips external tests |
| `--offline-dir PATH` | Not available | Overrides dependency directory and enables offline mode |
| `--help` | Displays help | Displays help |

With `--check-only`, `--reboot` is ignored. Check-only detects the Docker major version and Compose availability; it does not validate all three exact component versions or APT holds, and cannot guarantee later download or installation success.

Preparation may set locale `en_US.UTF-8`, timezone `America/Sao_Paulo`, disable UFW, configure Chrome with `--no-sandbox`, and create `/fhop-install/install`, `/data/fhop-data`, `/terra-install`, and `/4G-install`. Ubuntu updates, automatic NVIDIA installation and NTP enablement belong to the Internet-enabled flow.

## Validation status

Online Bash syntax, help and exact-version selection with simulated data passed. Real installation, package availability and upgrade/downgrade still require Ubuntu 22.04/24.04 testing.

The [v5.5 release notes](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5) document bundle validation, including package metadata, hashes and an offline APT simulation for Chrome on Ubuntu 24.04. Final installation on minimal VMs is also recommended before production.

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

When the three main versions already match, they are checked and package locks are applied. If the user declines an adjustment of mismatched versions, the existing installation and its locks are kept. After installing the recommended package, it validates the exact versions of Docker Engine, Docker Compose, and containerd.

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

Also review each step's messages. Virtualization remains `Nao verificada` (not checked). The report is not a complete environment certification.

---

# About the project

This script was developed to simplify the preparation of Ubuntu environments for **DJI FlightHub 2 On-Premises** deployments.

It is **not intended to replace DJI's official documentation**, but rather to complement the installation process by providing additional validations and automation based on real-world deployment experience.
