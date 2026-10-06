#!/usr/bin/env bash
set -euo pipefail

# FlightHub 2 On-Premises Environment Preparation Tool v5.5
# Baseado na v5.4.1, com suporte a preparacao de maquinas sem Internet.

REBOOT_AFTER_INSTALL=0
CHECK_ONLY=0
OFFLINE_MODE=0
OFFLINE_DIR=""
CPU_ERROR=0
DOCKER_HOLD_STATUS="Nao aplicado"
TEMP_DOCKER_HOLDS=()

EXPECTED_DOCKER_VERSION="27.2.0"
EXPECTED_COMPOSE_VERSION="2.29.2"
EXPECTED_CONTAINERD_VERSION="1.7.21"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Uso:
  sudo bash fh2-onprem-prep-tool-v5.5.sh [opcoes]

Opcoes:
  --check-only             Executa apenas verificacoes, sem alterar o sistema.
  --offline                Executa a preparacao sem utilizar Internet.
  --offline-dir CAMINHO    Sobrescreve o diretorio de pacotes offline.
                           Padrao: ./packages/ubuntu-<versao>
  --reboot                 Reinicia o sistema ao final da preparacao.
  --help, -h               Exibe esta ajuda.

Exemplos:
  sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
  sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
  sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --offline-dir /mnt/usb/fh2-offline
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reboot)
      REBOOT_AFTER_INSTALL=1
      shift
      ;;
    --check-only)
      CHECK_ONLY=1
      shift
      ;;
    --offline)
      OFFLINE_MODE=1
      shift
      ;;
    --offline-dir)
      [[ $# -ge 2 ]] || { echo "ERRO: --offline-dir exige um caminho."; exit 1; }
      OFFLINE_MODE=1
      OFFLINE_DIR="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Opcao desconhecida: $1"
      usage
      exit 1
      ;;
  esac
done

log() {
  printf '\n============================================================\n'
  printf 'ETAPA: %s\n' "$1"
  printf '============================================================\n'
}

info() { echo "INFO: $1"; }
warn() { echo "AVISO: $1"; }
check_command() { command -v "$1" >/dev/null 2>&1; }
run_sudo() { sudo "$@"; }

confirm_continue() {
  echo
  echo "========================================"
  echo "ATENCAO"
  echo "$1"
  echo "========================================"

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    warn "Modo de verificacao: o problema foi registrado e a analise continuara sem alterar o sistema."
    return 0
  fi

  while true; do
    read -rp "Deseja continuar mesmo assim? [s/N]: " resp
    case "$resp" in
      [Ss]|[Ss][Ii][Mm]) warn "Continuando por solicitacao do usuario."; return 0 ;;
      ""|[Nn]|[Nn][Aa][Oo]|[Nn][ãa][Oo]|[Nn][ÃA][Oo]) echo "Execucao cancelada."; exit 1 ;;
      *) echo "Responda com s ou n." ;;
    esac
  done
}

fail() { confirm_continue "ERRO: $1"; }

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  REBOOT_AFTER_INSTALL=0
  log "MODO DE VERIFICACAO (--check-only)"
  info "Nenhum pacote, driver ou software sera instalado."
  info "Docker, firewall, locale, timezone e NTP nao serao alterados."
fi

log "Verificando Ubuntu"
[[ -f /etc/os-release ]] || fail "Nao foi possivel identificar o sistema operacional."
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || fail "Sistema nao suportado. Este script foi feito para Ubuntu."
if [[ "${VERSION_ID:-}" != "22.04" && "${VERSION_ID:-}" != "24.04" ]]; then
  fail "Ubuntu ${VERSION_ID:-desconhecido} nao suportado. Use Ubuntu 22.04 ou 24.04."
fi
echo "Ubuntu $VERSION_ID OK"

if [[ "$OFFLINE_MODE" -eq 1 && -z "$OFFLINE_DIR" ]]; then
  OFFLINE_DIR="$SCRIPT_DIR/packages/ubuntu-$VERSION_ID"
fi

if [[ "$OFFLINE_MODE" -eq 1 ]]; then
  log "MODO OFFLINE"
  echo "O script nao executara apt update, apt upgrade ou downloads pela Internet."
  echo "Pacotes offline: $OFFLINE_DIR"
  echo "Estrutura esperada: base/, chrome/ e nvidia/"
  if [[ ! -d "$OFFLINE_DIR" ]]; then
    warn "Diretorio de pacotes offline nao encontrado: $OFFLINE_DIR"
    warn "Pacotes ja instalados poderao ser utilizados, mas dependencias ausentes nao poderao ser baixadas."
  fi
fi

CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo | cut -d ':' -f2- | xargs)"
CPU_FLAGS="$(grep -m1 '^flags' /proc/cpuinfo || true)"
check_cpu_required() {
  local flag="$1" name="$2"
  if [[ " $CPU_FLAGS " == *" $flag "* ]]; then
    printf "  [OK]    %s\n" "$name"
  else
    printf "  [ERRO]  %s nao suportado\n" "$name"
    CPU_ERROR=1
  fi
}

log "Verificando CPU e instrucoes obrigatorias"
echo "CPU: $CPU_MODEL"
check_cpu_required sse4_2 "SSE4.2"
check_cpu_required popcnt "POPCNT"
check_cpu_required avx "AVX"
check_cpu_required avx2 "AVX2"
if [[ "$CPU_ERROR" -ne 0 ]]; then CPU_STATUS="Incompativel"; fail "A CPU nao suporta todas as instrucoes obrigatorias."; else CPU_STATUS="OK"; fi
VIRTUALIZATION_STATUS="Nao verificada"

log "Verificando memoria RAM"
RAM_GB="$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)"
if (( RAM_GB <= 32 )); then
  RAM_STATUS="Limitada para FH2 sem Terra"
  fail "Foram detectados ${RAM_GB} GB de RAM. Com 32 GB ou menos, o Terra pode manter tarefas de reconstrucao como Pendente."
else
  RAM_STATUS="Adequada para FH2 e Terra"
fi
echo "RAM alocada detectada: ${RAM_GB} GB"

log "Verificando armazenamento"
ROOT_SOURCE="$(findmnt -n -o SOURCE /)"
ROOT_DISK_NAME="$(lsblk -s -r -n -o NAME,TYPE "$ROOT_SOURCE" 2>/dev/null | awk '$2=="disk" {print $1; exit}')"
if [[ -n "$ROOT_DISK_NAME" ]]; then
  SYSTEM_DISK="/dev/$ROOT_DISK_NAME"
  DISK_TOTAL_GB="$(lsblk -b -dn -o SIZE "$SYSTEM_DISK" | awk '{printf "%.0f", $1/1024/1024/1024}')"
else
  SYSTEM_DISK="Nao identificado"
  DISK_TOTAL_GB=0
fi
DISK_FREE_GB="$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')"
if [[ "$SYSTEM_DISK" == "Nao identificado" ]]; then DISK_TOTAL_STATUS="Nao identificado"; fail "Nao foi possivel identificar o disco fisico."; elif (( DISK_TOTAL_GB < 1000 )); then DISK_TOTAL_STATUS="Abaixo de 1 TB"; fail "Disco fisico abaixo do requisito de 1 TB."; else DISK_TOTAL_STATUS="OK"; fi
if (( DISK_FREE_GB < 300 )); then DISK_FREE_STATUS="Insuficiente para instalar"; fail "Menos de 300 GB livres em /."; else DISK_FREE_STATUS="OK"; fi

protect_existing_docker_packages() {
  local pkg status
  local -a pkgs=(containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin docker.io containerd runc docker-compose docker-compose-v2)
  TEMP_DOCKER_HOLDS=()
  for pkg in "${pkgs[@]}"; do
    status="$(dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null || true)"
    [[ "$status" == "ii " ]] || continue
    if apt-mark showhold | grep -Fxq "$pkg"; then continue; fi
    run_sudo apt-mark hold "$pkg"
    TEMP_DOCKER_HOLDS+=("$pkg")
  done
}

release_docker_holds_for_install() {
  local pkg
  local -a pkgs=(containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin docker.io containerd runc docker-compose docker-compose-v2)
  for pkg in "${pkgs[@]}"; do
    if apt-mark showhold | grep -Fxq "$pkg"; then run_sudo apt-mark unhold "$pkg"; fi
  done
  TEMP_DOCKER_HOLDS=()
}

hold_docker_packages() {
  local pkg status
  local -a pkgs=(containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin)
  local -a installed=()
  for pkg in "${pkgs[@]}"; do
    status="$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)"
    [[ "$status" == "install ok installed" ]] && installed+=("$pkg")
  done
  if [[ "${#installed[@]}" -eq 0 ]]; then DOCKER_HOLD_STATUS="Nenhum pacote encontrado"; return 1; fi
  run_sudo apt-mark hold "${installed[@]}"
  DOCKER_HOLD_STATUS="Ativo (${#installed[@]} pacotes)"
}

repair_apt_online() {
  run_sudo dpkg --configure -a || true
  run_sudo apt-get install -f -y || true
  run_sudo apt --fix-broken install -y || true
}

deb_package_name() {
  dpkg-deb -f "$1" Package 2>/dev/null || true
}

deb_package_version() {
  dpkg-deb -f "$1" Version 2>/dev/null || true
}

package_installed_version() {
  dpkg-query -W -f='${Version}' "$1" 2>/dev/null || true
}

create_local_apt_repo() {
  local dir="$1"
  local repo_dir list_file deb rel filename size sha256 control
  local -a debs=()

  [[ -d "$dir" ]] || { warn "Diretorio offline ausente: $dir"; return 1; }
  mapfile -d '' debs < <(find "$dir" -maxdepth 1 -type f -name '*.deb' -print0 | sort -z)
  [[ "${#debs[@]}" -gt 0 ]] || { warn "Nenhum .deb encontrado em $dir"; return 1; }

  repo_dir="$(run_sudo mktemp -d /tmp/fh2-offline-apt.XXXXXX)"
  run_sudo chmod 755 "$repo_dir"

  for deb in "${debs[@]}"; do
    filename="$(basename "$deb")"
    run_sudo cp -f "$deb" "$repo_dir/$filename"
  done

  {
    for deb in "$repo_dir"/*.deb; do
      filename="$(basename "$deb")"
      size="$(stat -c '%s' "$deb")"
      sha256="$(sha256sum "$deb" | awk '{print $1}')"
      control="$(dpkg-deb -f "$deb" 2>/dev/null)" || continue
      printf '%s\n' "$control"
      printf 'Filename: ./%s\n' "$filename"
      printf 'Size: %s\n' "$size"
      printf 'SHA256: %s\n\n' "$sha256"
    done
  } | run_sudo tee "$repo_dir/Packages" >/dev/null

  [[ -s "$repo_dir/Packages" ]] || { run_sudo rm -rf "$repo_dir"; warn "Falha ao gerar indice Packages."; return 1; }
  run_sudo gzip -9 -c "$repo_dir/Packages" | run_sudo tee "$repo_dir/Packages.gz" >/dev/null
  [[ -s "$repo_dir/Packages.gz" ]] || { run_sudo rm -rf "$repo_dir"; warn "Falha ao gerar indice Packages.gz."; return 1; }

  list_file="$(run_sudo mktemp /tmp/fh2-offline-sources.XXXXXX.list)"
  printf 'deb [trusted=yes] file:%s ./\n' "$repo_dir" | run_sudo tee "$list_file" >/dev/null

  LOCAL_APT_REPO_DIR="$repo_dir"
  LOCAL_APT_SOURCE_LIST="$list_file"
  info "Repositorio APT local criado com ${#debs[@]} pacotes."
}

cleanup_local_apt_repo() {
  [[ -n "${LOCAL_APT_SOURCE_LIST:-}" ]] && run_sudo rm -f "$LOCAL_APT_SOURCE_LIST" || true
  [[ -n "${LOCAL_APT_REPO_DIR:-}" ]] && run_sudo rm -rf "$LOCAL_APT_REPO_DIR" || true
  LOCAL_APT_SOURCE_LIST=""
  LOCAL_APT_REPO_DIR=""
}

install_offline_deb_bundle() {
  local dir="$1"
  local description="$2"
  local primary_pattern="$3"
  local primary_deb pkg

  [[ -d "$dir" ]] || { warn "Diretorio offline ausente para $description: $dir"; return 1; }
  primary_deb="$(find "$dir" -maxdepth 1 -type f -name "$primary_pattern" -print -quit)"
  [[ -n "$primary_deb" ]] || { warn "Pacote principal de $description nao encontrado em $dir ($primary_pattern)."; return 1; }

  pkg="$(deb_package_name "$primary_deb")"
  [[ -n "$pkg" ]] || { warn "Nao foi possivel identificar o pacote em $primary_deb."; return 1; }

  info "Pacote principal de $description: $pkg ($(basename "$primary_deb"))"
  install_offline_packages "$dir" "$description" "$pkg"
}

install_offline_packages() {
  local dir="$1"
  local description="$2"
  shift 2
  local -a packages=("$@")

  [[ "${#packages[@]}" -gt 0 ]] || return 0
  create_local_apt_repo "$dir" || return 1

  log "Instalando $description pelo repositorio APT local"
  echo "Pacotes solicitados: ${packages[*]}"
  echo "O bundle sera usado apenas para resolver estes pacotes e suas dependencias."

  run_sudo dpkg --configure -a || true

  if ! run_sudo apt-get \
      -o Dir::Etc::sourcelist="$LOCAL_APT_SOURCE_LIST" \
      -o Dir::Etc::sourceparts="-" \
      -o APT::Get::List-Cleanup="0" \
      -o Acquire::Languages="none" \
      -o Acquire::AllowInsecureRepositories="true" \
      update; then
    cleanup_local_apt_repo
    warn "Falha ao carregar o indice APT local."
    return 1
  fi

  echo "Candidatos disponiveis no repositorio local:"
  for pkg in "${packages[@]}"; do
    candidate="$(run_sudo apt-cache \
      -o Dir::Etc::sourcelist="$LOCAL_APT_SOURCE_LIST" \
      -o Dir::Etc::sourceparts="-" \
      policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
    echo "  - $pkg: ${candidate:-nenhum}"
  done

  if ! run_sudo env DEBIAN_FRONTEND=noninteractive apt-get \
      -o Dir::Etc::sourcelist="$LOCAL_APT_SOURCE_LIST" \
      -o Dir::Etc::sourceparts="-" \
      -o APT::Get::List-Cleanup="0" \
      -o Acquire::Languages="none" \
      --no-remove \
      install -y "${packages[@]}"; then
    cleanup_local_apt_repo
    echo
    echo "ERRO: Nao foi possivel instalar os pacotes solicitados usando somente o bundle local."
    echo "Pacotes: ${packages[*]}"
    echo "Diretorio: $dir"
    echo "Nenhum repositorio externo foi habilitado."
    return 1
  fi

  cleanup_local_apt_repo
}
install_base_dependencies() {
  local -a required=(pciutils ubuntu-drivers-common curl ca-certificates iputils-ping iptables locales)
  local -a missing=()
  local pkg

  for pkg in "${required[@]}"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" || missing+=("$pkg")
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    info "Todos os utilitarios necessarios ja estao instalados."
    return 0
  fi

  echo "Pacotes ausentes: ${missing[*]}"
  if [[ "$OFFLINE_MODE" -eq 1 ]]; then
    install_offline_packages "$OFFLINE_DIR/base" "dependencias base" "${missing[@]}" || fail "Dependencias base offline incompletas."
    for pkg in "${missing[@]}"; do
      if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        fail "O pacote obrigatorio $pkg continua ausente apos processar o bundle offline."
      fi
    done
  else
    run_sudo apt install -y "${missing[@]}"
  fi
}

update_system_packages() {
  log "Atualizando sistema operacional"
  if ! run_sudo apt update; then repair_apt_online; run_sudo apt update || fail "Falha no apt update."; fi
  if ! run_sudo env DEBIAN_FRONTEND=noninteractive apt upgrade -y; then repair_apt_online; run_sudo env DEBIAN_FRONTEND=noninteractive apt upgrade -y || fail "Falha no apt upgrade."; fi
  run_sudo apt autoremove -y || true
  run_sudo apt autoclean -y || true
}

if [[ "$CHECK_ONLY" -eq 0 ]]; then
  protect_existing_docker_packages
  if [[ "$OFFLINE_MODE" -eq 0 ]]; then
    update_system_packages
  else
    log "Atualizacao do Ubuntu ignorada"
    info "Modo offline: apt update/upgrade nao sera executado."
  fi
  install_base_dependencies

  IPTABLES_PACKAGE_STATUS="$(dpkg-query -W -f='${Status}' iptables 2>/dev/null || true)"
  if [[ "$IPTABLES_PACKAGE_STATUS" != "install ok installed" ]] || ! run_sudo iptables --version >/dev/null 2>&1; then
    echo "ERRO: iptables nao foi instalado/configurado corretamente."
    exit 1
  fi
else
  info "Check-only: atualizacao e instalacao de pacotes ignoradas."
fi

log "Verificando GPU NVIDIA"
GPU_NVIDIA=""
check_command lspci && GPU_NVIDIA="$(lspci | grep -i nvidia || true)"
if [[ -z "$GPU_NVIDIA" ]]; then
  NVIDIA_STATUS="Nao detectada"
  NVIDIA_DRIVER_STATUS="Nao instalado"
  warn "Nenhuma GPU NVIDIA detectada."
else
  NVIDIA_STATUS="Detectada"
  echo "$GPU_NVIDIA"
  if check_command nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    NVIDIA_DRIVER_STATUS="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)"
    info "Driver NVIDIA funcional. Nenhuma alteracao sera realizada."
  elif [[ "$CHECK_ONLY" -eq 1 ]]; then
    NVIDIA_DRIVER_STATUS="Nao instalado ou nao funcional"
  elif [[ "$OFFLINE_MODE" -eq 1 ]]; then
    warn "Instalacao automatica de driver NVIDIA offline desabilitada nesta revisao por seguranca."
    warn "O bundle NVIDIA exige selecao especifica por GPU/kernel e nao sera instalado genericamente."
    if false; then
      NVIDIA_DRIVER_STATUS="Instalado por pacote offline; reinicializacao necessaria"
    else
      NVIDIA_DRIVER_STATUS="Nao instalado"
      fail "GPU NVIDIA detectada sem driver funcional. Instale um bundle NVIDIA compativel com esta GPU/kernel antes de prosseguir."
    fi
  else
    if echo "$GPU_NVIDIA" | grep -qiE 'RTX 5000|RTX PRO 5000|RTX 5080'; then
      DRIVER="$(ubuntu-drivers devices | awk '/nvidia-driver-[0-9]+-open/ && /recommended/ {print $3; exit}')"
      [[ -n "$DRIVER" ]] || DRIVER="$(ubuntu-drivers devices | awk '/nvidia-driver-[0-9]+-open/ {print $3; exit}')"
    else
      DRIVER="$(ubuntu-drivers devices | awk '/recommended/ {print $3; exit}')"
    fi
    [[ -n "$DRIVER" ]] && run_sudo apt install -y "$DRIVER" || fail "Nao foi encontrado driver NVIDIA recomendado."
    NVIDIA_DRIVER_STATUS="${DRIVER:-Nao identificado}"
  fi
fi

if [[ "$CHECK_ONLY" -eq 0 ]]; then
  log "Configurando locale e timezone"
  run_sudo locale-gen en_US.UTF-8
  run_sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  run_sudo timedatectl set-timezone America/Sao_Paulo
fi

if [[ "$OFFLINE_MODE" -eq 1 ]]; then
  INTERNET_STATUS="Ignorado (modo offline)"
  DNS_STATUS="Ignorado (modo offline)"
  log "Internet e DNS"
  info "Modo offline: testes externos nao serao executados."
else
  log "Verificando conectividade com Internet"
  if ping -c 2 8.8.8.8 >/dev/null 2>&1; then INTERNET_STATUS="OK"; else INTERNET_STATUS="Falhou"; fail "Sem conectividade com Internet."; fi
  log "Verificando DNS"
  if getent hosts google.com >/dev/null 2>&1; then DNS_STATUS="OK"; else DNS_STATUS="Falhou"; fail "Resolucao DNS falhou."; fi
fi

log "Verificando sincronizacao de horario"
if [[ "$CHECK_ONLY" -eq 0 && "$OFFLINE_MODE" -eq 0 ]]; then
  run_sudo timedatectl set-ntp true
elif [[ "$OFFLINE_MODE" -eq 1 ]]; then
  info "Modo offline: NTP externo nao sera habilitado. Use NTP interno quando necessario."
fi
if timedatectl | grep -q "System clock synchronized: yes"; then NTP_STATUS="Sincronizado"; else NTP_STATUS="Nao confirmado"; fi

log "Verificando firewall UFW"
if check_command ufw; then
  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    FIREWALL_STATUS="$(ufw status 2>/dev/null | head -n1 | sed 's/^Status: //')"
  else
    run_sudo ufw disable || true
    FIREWALL_STATUS="Desabilitado"
  fi
else
  FIREWALL_STATUS="UFW nao instalado"
fi

install_recommended_docker() {
  local archive="$SCRIPT_DIR/docker.tar.gz"
  local install_script="" uninstall_script="" response=""
  local docker_detected=0 compose_detected=0
  local installed_docker_version="" installed_compose_version="" installed_containerd_version=""

  log "Verificando Docker e Docker Compose"
  if check_command docker; then
    docker_detected=1
    docker --version || true
    DOCKER_MAJOR_VERSION="$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d. -f1 || true)"
    [[ -n "$DOCKER_MAJOR_VERSION" ]] || DOCKER_MAJOR_VERSION="$(docker --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9]*\).*/\1/p')"
    if [[ "$DOCKER_MAJOR_VERSION" == "27" ]]; then DOCKER_STATUS="Docker 27 compativel"; elif [[ "$DOCKER_MAJOR_VERSION" == "29" ]]; then DOCKER_STATUS="Docker 29 nao suportado"; else DOCKER_STATUS="Docker ${DOCKER_MAJOR_VERSION:-desconhecido} nao homologado"; fi
    if docker compose version >/dev/null 2>&1; then compose_detected=1; elif check_command docker-compose; then compose_detected=1; fi
  else
    DOCKER_STATUS="Nao instalado"
    check_command docker-compose && compose_detected=1
  fi

  [[ "$CHECK_ONLY" -eq 0 ]] || return 0

  if [[ "$docker_detected" -eq 1 ]]; then
    installed_docker_version="$(docker --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9.]*\).*/\1/p')"
    if docker compose version >/dev/null 2>&1; then
      installed_compose_version="$(docker compose version --short 2>/dev/null | sed 's/^v//')"
    elif check_command docker-compose; then
      installed_compose_version="$(docker-compose version --short 2>/dev/null | sed 's/^v//')"
    fi
    installed_containerd_version="$(containerd --version 2>/dev/null | awk '{print $3}' || true)"

    echo "Docker detectado.... ${installed_docker_version:-desconhecido}"
    echo "Compose detectado... ${installed_compose_version:-desconhecido}"
    echo "containerd detectado ${installed_containerd_version:-desconhecido}"

    if [[ "$installed_docker_version" == "$EXPECTED_DOCKER_VERSION" &&
          "$installed_compose_version" == "$EXPECTED_COMPOSE_VERSION" &&
          "$installed_containerd_version" == "$EXPECTED_CONTAINERD_VERSION" ]]; then
      info "Docker, Compose e containerd ja estao exatamente nas versoes homologadas."
      hold_docker_packages || fail "Nao foi possivel bloquear os pacotes Docker."
      DOCKER_STATUS="Docker $EXPECTED_DOCKER_VERSION homologado"
      return 0
    fi
  fi

  if [[ "$docker_detected" -eq 1 || "$compose_detected" -eq 1 ]]; then
    warn "As versoes instaladas nao correspondem integralmente ao conjunto homologado."
    echo "Esperado: Docker $EXPECTED_DOCKER_VERSION, Compose $EXPECTED_COMPOSE_VERSION, containerd $EXPECTED_CONTAINERD_VERSION"
    read -rp "Deseja desinstalar a versao atual e instalar a versao recomendada? [s/N]: " response
    case "$response" in [Ss]|[Ss][Ii][Mm]) ;; *) warn "Docker atual mantido."; return 0 ;; esac
  fi

  [[ -f "$archive" ]] || { fail "Arquivo docker.tar.gz nao encontrado em $SCRIPT_DIR"; return 1; }
  tar -xzf "$archive" -C "$SCRIPT_DIR"
  install_script="$(find "$SCRIPT_DIR" -maxdepth 5 -type f -name install_docker.sh -print -quit)"
  uninstall_script="$(find "$SCRIPT_DIR" -maxdepth 5 -type f -name uninstall_docker.sh -print -quit)"
  [[ -n "$install_script" ]] || { fail "install_docker.sh nao encontrado."; return 1; }
  run_sudo chmod +x "$install_script"

  release_docker_holds_for_install
  if [[ "$docker_detected" -eq 1 || "$compose_detected" -eq 1 ]]; then
    [[ -n "$uninstall_script" ]] || { fail "uninstall_docker.sh nao encontrado."; return 1; }
    run_sudo chmod +x "$uninstall_script"
    (cd "$(dirname "$uninstall_script")" && run_sudo ./uninstall_docker.sh)
  fi
  (cd "$(dirname "$install_script")" && run_sudo ./install_docker.sh)

  local pkg status
  for pkg in iptables docker-ce docker-ce-cli containerd.io; do
    status="$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)"
    [[ "$status" == "install ok installed" ]] || { fail "Instalacao incompleta do pacote $pkg."; return 1; }
  done

  installed_docker_version="$(docker --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9.]*\).*/\1/p')"
  if docker compose version >/dev/null 2>&1; then installed_compose_version="$(docker compose version --short 2>/dev/null | sed 's/^v//')"; fi
  installed_containerd_version="$(containerd --version 2>/dev/null | awk '{print $3}' || true)"
  if [[ "$installed_docker_version" != "$EXPECTED_DOCKER_VERSION" || "$installed_compose_version" != "$EXPECTED_COMPOSE_VERSION" || "$installed_containerd_version" != "$EXPECTED_CONTAINERD_VERSION" ]]; then
    fail "Versoes Docker divergentes. Esperado: Docker $EXPECTED_DOCKER_VERSION, Compose $EXPECTED_COMPOSE_VERSION, containerd $EXPECTED_CONTAINERD_VERSION."
    return 1
  fi
  hold_docker_packages || fail "Nao foi possivel bloquear os pacotes Docker."
  DOCKER_STATUS="Docker $EXPECTED_DOCKER_VERSION recomendado instalado"
}

DOCKER_STATUS="Nao verificado"
install_recommended_docker

log "Criando estrutura de diretorios"
if [[ "$CHECK_ONLY" -eq 1 ]]; then
  DIRECTORIES_STATUS="Nao criadas (check-only)"
else
  run_sudo mkdir -p /fhop-install/install /data/fhop-data /terra-install /4G-install
  DIRECTORIES_STATUS="Criadas"
fi

install_google_chrome() {
  local chrome_real_bin=""
  if check_command google-chrome-stable; then
    chrome_real_bin="$(command -v google-chrome-stable)"
    info "Google Chrome ja instalado. Instalacao ignorada."
  elif [[ -x /usr/bin/google-chrome ]]; then
    chrome_real_bin="/usr/bin/google-chrome"
    info "Google Chrome ja instalado. Instalacao ignorada."
  elif [[ "$OFFLINE_MODE" -eq 1 ]]; then
    install_offline_deb_bundle "$OFFLINE_DIR/chrome" "Google Chrome" 'google-chrome-stable*.deb' || { CHROME_STATUS="Pacote offline ausente/incompleto"; fail "Nao foi possivel instalar o Chrome offline."; return 1; }
    chrome_real_bin="$(command -v google-chrome-stable 2>/dev/null || true)"
    [[ -n "$chrome_real_bin" ]] || chrome_real_bin="/usr/bin/google-chrome"
  else
    local pkg="/tmp/google-chrome-stable_current_amd64.deb"
    curl -fL --retry 3 --connect-timeout 20 "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -o "$pkg" || { fail "Falha no download do Chrome."; return 1; }
    run_sudo apt install -y "$pkg" || { repair_apt_online; run_sudo apt install -y "$pkg"; }
    rm -f "$pkg"
    chrome_real_bin="$(command -v google-chrome-stable 2>/dev/null || true)"
  fi

  [[ -x "$chrome_real_bin" ]] || { CHROME_STATUS="Executavel nao encontrado"; fail "Executavel do Chrome nao encontrado."; return 1; }
  run_sudo tee /usr/local/bin/google-chrome >/dev/null <<EOF
#!/usr/bin/env bash
exec "$chrome_real_bin" --no-sandbox "\$@"
EOF
  run_sudo chmod +x /usr/local/bin/google-chrome
  run_sudo ln -sfn /usr/local/bin/google-chrome /usr/local/bin/google-chrome-no-sandbox
  CHROME_VERSION="$("$chrome_real_bin" --version 2>/dev/null || echo 'Versao nao identificada')"
  CHROME_STATUS="Instalado e configurado com --no-sandbox"
}

CHROME_STATUS="Nao verificado"
CHROME_VERSION="Nao identificado"
if [[ "$CHECK_ONLY" -eq 1 ]]; then
  if check_command google-chrome-stable; then CHROME_VERSION="$(google-chrome-stable --version 2>/dev/null || true)"; CHROME_STATUS="Instalado"; elif [[ -x /usr/bin/google-chrome ]]; then CHROME_VERSION="$(/usr/bin/google-chrome --version 2>/dev/null || true)"; CHROME_STATUS="Instalado"; else CHROME_STATUS="Nao instalado"; fi
else
  install_google_chrome
fi

echo
echo "=============================="
echo " FlightHub 2 OP Pre-Check v5.5 (Smart Offline Bundle)"
echo "=============================="
if [[ "$CHECK_ONLY" -eq 1 ]]; then MODE_STATUS="Somente verificacao"; elif [[ "$OFFLINE_MODE" -eq 1 ]]; then MODE_STATUS="Preparacao offline"; else MODE_STATUS="Preparacao online"; fi
echo "Modo............... $MODE_STATUS"
echo "Ubuntu............. $VERSION_ID OK"
echo "CPU................ $CPU_MODEL"
echo "CPU Recursos....... $CPU_STATUS"
echo "Virtualizacao...... $VIRTUALIZATION_STATUS"
echo "RAM................ ${RAM_GB} GB - $RAM_STATUS"
echo "Disco fisico....... ${DISK_TOTAL_GB} GB - $DISK_TOTAL_STATUS"
echo "Disco livre em /... ${DISK_FREE_GB} GB - $DISK_FREE_STATUS"
echo "GPU NVIDIA......... $NVIDIA_STATUS"
echo "Driver NVIDIA...... $NVIDIA_DRIVER_STATUS"
echo "Internet........... $INTERNET_STATUS"
echo "DNS................ $DNS_STATUS"
echo "NTP................ $NTP_STATUS"
echo "Firewall........... $FIREWALL_STATUS"
echo "Docker............. $DOCKER_STATUS"
echo "Bloqueio Docker.... $DOCKER_HOLD_STATUS"
echo "Chrome............. $CHROME_STATUS"
echo "Chrome versao...... $CHROME_VERSION"
echo "Pastas............. $DIRECTORIES_STATUS"
[[ "$OFFLINE_MODE" -eq 1 ]] && echo "Pacotes offline.... $OFFLINE_DIR"
echo "=============================="

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "Verificacao concluida. Nenhuma alteracao foi realizada."
elif [[ "$REBOOT_AFTER_INSTALL" -eq 1 ]]; then
  run_sudo reboot
else
  echo "Concluido. Reinicie o sistema caso um driver NVIDIA tenha sido instalado."
fi
