#!/usr/bin/env bash
set -euo pipefail

REBOOT_AFTER_INSTALL=0
CHECK_ONLY=0
CPU_ERROR=0

for arg in "$@"; do
  case "$arg" in
    --reboot)
      REBOOT_AFTER_INSTALL=1
      ;;
    --check-only)
      CHECK_ONLY=1
      ;;
    --help|-h)
      cat <<'EOF'
Uso:
  sudo ./setup_fh2VER5.3.sh [--check-only] [--reboot]

Opcoes:
  --check-only  Executa apenas as verificacoes, sem instalar, atualizar ou alterar o sistema.
  --reboot      Reinicia o sistema ao final da instalacao normal.
  --help, -h    Exibe esta ajuda.
EOF
      exit 0
      ;;
    *)
      echo "Opcao desconhecida: $arg"
      echo "Use --help para ver as opcoes disponiveis."
      exit 1
      ;;
  esac
done

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  REBOOT_AFTER_INSTALL=0
  echo
  echo "============================================================"
  echo " MODO DE VERIFICACAO (--check-only)"
  echo "============================================================"
  echo "Apenas verificacoes serao executadas."
  echo "Nenhum pacote sera instalado ou atualizado."
  echo "Nenhum driver ou software sera instalado."
  echo "Docker, firewall, locale, timezone e NTP nao serao alterados."
  echo "Nenhum diretorio sera criado e o sistema nao sera reiniciado."
fi

log() {
  printf '\n============================================================\n'
  printf 'ETAPA: %s\n' "$1"
  printf '============================================================\n'
}

info() {
  echo "INFO: $1"
}

warn() {
  echo "AVISO: $1"
}

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
      [Ss]|[Ss][Ii][Mm])
        warn "Continuando por solicitacao do usuario."
        return 0
        ;;
      ""|[Nn]|[Nn][Aa][Oo]|[Nn][ãa][Oo]|[Nn][ÃA][Oo])
        echo "Execucao cancelada."
        exit 1
        ;;
      *)
        echo "Responda com s ou n."
        ;;
    esac
  done
}

fail() {
  confirm_continue "ERRO: $1"
}

run_sudo() {
  sudo "$@"
}

repair_apt() {
  warn "Tentando corrigir dependencias e pacotes pendentes."
  run_sudo dpkg --configure -a || true
  run_sudo apt-get install -f -y || true
  run_sudo apt --fix-broken install -y || true
}

update_system_packages() {
  log "Atualizando sistema operacional"
  info "A lista de pacotes sera atualizada e as atualizacoes disponiveis serao instaladas."
  info "Se forem encontradas dependencias quebradas, o script tentara corrigi-las automaticamente."

  if ! run_sudo apt update; then
    repair_apt
    run_sudo apt update || fail "Falha ao atualizar a lista de pacotes mesmo apos as correcoes."
  fi

  if ! run_sudo env DEBIAN_FRONTEND=noninteractive apt upgrade -y; then
    repair_apt
    run_sudo env DEBIAN_FRONTEND=noninteractive apt upgrade -y || \
      fail "Falha ao atualizar os pacotes mesmo apos as correcoes."
  fi

  if run_sudo apt-get check >/dev/null 2>&1; then
    echo "Atualizacao do sistema concluida sem dependencias quebradas."
  else
    repair_apt
    run_sudo apt-get check >/dev/null 2>&1 || \
      fail "O sistema ainda possui dependencias quebradas apos as tentativas de reparo."
  fi

  run_sudo apt autoremove -y || warn "Nao foi possivel remover pacotes obsoletos."
  run_sudo apt autoclean -y || warn "Nao foi possivel limpar o cache de pacotes."
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

install_recommended_docker() {
  local script_dir docker_archive install_script uninstall_script docker_scripts_dir
  local docker_detected=0 compose_detected=0 response

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  docker_archive="$script_dir/docker.tar.gz"
  install_script=""
  uninstall_script=""
  docker_scripts_dir=""

  log "Verificando Docker e Docker Compose"
  info "O FlightHub 2 On-Premises deve utilizar Docker 27."
  info "Docker 29 nao e suportado e pode causar erros fatais no frontend do FlightHub 2."
  info "Caso outra versao seja detectada, sera oferecida a substituicao pelo pacote recomendado."

  if check_command docker; then
    docker_detected=1
    echo "Docker detectado:"
    docker --version || true
    DOCKER_MAJOR_VERSION="$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d. -f1 || true)"
    if [[ -z "$DOCKER_MAJOR_VERSION" ]]; then
      DOCKER_MAJOR_VERSION="$(docker --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9]*\).*/\1/p')"
    fi

    if [[ "$DOCKER_MAJOR_VERSION" == "27" ]]; then
      echo "[OK] Docker 27 detectado. Versao compativel com o FH2 OP."
      DOCKER_STATUS="Docker 27 compativel"
    elif [[ "$DOCKER_MAJOR_VERSION" == "29" ]]; then
      warn "Docker 29 detectado. Esta versao pode causar erros fatais no frontend do FH2 OP."
      DOCKER_STATUS="Docker 29 nao suportado"
    elif [[ -n "$DOCKER_MAJOR_VERSION" ]]; then
      warn "Docker $DOCKER_MAJOR_VERSION detectado. A versao homologada para o FH2 OP e a 27."
      DOCKER_STATUS="Docker $DOCKER_MAJOR_VERSION nao homologado"
    else
      warn "Nao foi possivel identificar a versao principal do Docker."
      DOCKER_STATUS="Versao nao identificada"
    fi

    if docker compose version >/dev/null 2>&1; then
      compose_detected=1
      echo "Docker Compose detectado:"
      docker compose version || true
    elif check_command docker-compose; then
      compose_detected=1
      echo "Docker Compose legado detectado:"
      docker-compose --version || true
    else
      echo "Docker Compose nao foi detectado."
    fi
  else
    echo "Docker nao foi detectado."

    if check_command docker-compose; then
      compose_detected=1
      echo "Docker Compose legado detectado:"
      docker-compose --version || true
    else
      echo "Docker Compose nao foi detectado."
    fi
  fi

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if [[ "$docker_detected" -eq 0 ]]; then
      DOCKER_STATUS="Nao instalado"
      warn "Docker nao esta instalado. A instalacao normal utilizara o pacote Docker 27 fornecido com o script."
    fi
    info "Modo de verificacao: nenhuma versao do Docker sera removida ou instalada."
    return 0
  fi

  if [[ "$docker_detected" -eq 1 || "$compose_detected" -eq 1 ]]; then
    while true; do
      read -rp "Deseja desinstalar a versao atual e instalar a versao recomendada? [s/N]: " response
      case "$response" in
        [Ss]|[Ss][Ii][Mm])
          break
          ;;
        ""|[Nn]|[Nn][Aa][Oo]|[Nn][ãa][Oo]|[Nn][ÃA][Oo])
          warn "Docker atual mantido. A instalacao recomendada foi ignorada."
          if [[ "${DOCKER_MAJOR_VERSION:-}" == "29" ]]; then
            warn "Ao prosseguir com Docker 29, o frontend do FH2 OP pode apresentar erros fatais e ficar inutilizavel."
          elif [[ "${DOCKER_MAJOR_VERSION:-}" != "27" ]]; then
            warn "Ao prosseguir com uma versao diferente da 27, a instalacao ficara fora da configuracao homologada."
          fi
          DOCKER_STATUS="Mantido: ${DOCKER_MAJOR_VERSION:-versao desconhecida}"
          return 0
          ;;
        *)
          echo "Responda com s ou n."
          ;;
      esac
    done
  fi

  if [[ ! -f "$docker_archive" ]]; then
    fail "Arquivo docker.tar.gz nao encontrado em: $script_dir"
    DOCKER_STATUS="Arquivo nao encontrado"
    return 1
  fi

  log "Descompactando pacote Docker recomendado"
  tar -xzvf "$docker_archive" -C "$script_dir"

  # Localiza os scripts mesmo que o tar.gz tenha criado uma pasta adicional.
  install_script="$(find "$script_dir" -maxdepth 5 -type f -name 'install_docker.sh' -print -quit)"
  uninstall_script="$(find "$script_dir" -maxdepth 5 -type f -name 'uninstall_docker.sh' -print -quit)"

  if [[ -z "$install_script" || ! -f "$install_script" ]]; then
    echo "Conteudo encontrado apos a extracao:"
    find "$script_dir" -maxdepth 5 -type f -printf '  %p\n' || true
    fail "Script install_docker.sh nao encontrado apos descompactar $docker_archive."
    DOCKER_STATUS="Instalador nao encontrado"
    return 1
  fi

  docker_scripts_dir="$(dirname "$install_script")"
  echo "Instalador localizado em: $install_script"

  run_sudo chmod +x "$install_script"

  if [[ "$docker_detected" -eq 1 || "$compose_detected" -eq 1 ]]; then
    if [[ -z "$uninstall_script" || ! -f "$uninstall_script" ]]; then
      echo "Conteudo encontrado apos a extracao:"
      find "$script_dir" -maxdepth 5 -type f -printf '  %p\n' || true
      fail "Script uninstall_docker.sh nao encontrado apos descompactar $docker_archive."
      DOCKER_STATUS="Desinstalador nao encontrado"
      return 1
    fi

    echo "Desinstalador localizado em: $uninstall_script"
    run_sudo chmod +x "$uninstall_script"

    log "Desinstalando Docker existente"
    (
      cd "$(dirname "$uninstall_script")"
      run_sudo ./uninstall_docker.sh
    )
  fi

  log "Instalando Docker recomendado"
  (
    cd "$docker_scripts_dir"
    run_sudo ./install_docker.sh
  )

  echo "Versoes instaladas:"
  if check_command docker; then
    docker --version || true
    INSTALLED_DOCKER_MAJOR="$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d. -f1 || true)"
    if [[ "$INSTALLED_DOCKER_MAJOR" != "27" ]]; then
      fail "A instalacao terminou com Docker ${INSTALLED_DOCKER_MAJOR:-desconhecido}, mas o FH2 OP requer Docker 27.
Nao prossiga com a instalacao do FH2 OP ate que o Docker 27 esteja corretamente instalado. Versoes incompatíveis, especialmente a 29, podem causar erros fatais no frontend."
    fi
  fi

  if check_command docker && docker compose version >/dev/null 2>&1; then
    docker compose version || true
  elif check_command docker-compose; then
    docker-compose --version || true
  fi

  DOCKER_STATUS="Docker 27 recomendado instalado"
}


install_google_chrome() {
  local chrome_package="/tmp/google-chrome-stable_current_amd64.deb"
  local chrome_real_bin=""

  log "Verificando Google Chrome"

  if check_command google-chrome-stable; then
    chrome_real_bin="$(command -v google-chrome-stable)"
    echo "Google Chrome ja instalado:"
    "$chrome_real_bin" --version || true
  elif [[ -x /usr/bin/google-chrome ]]; then
    chrome_real_bin="/usr/bin/google-chrome"
    echo "Google Chrome ja instalado:"
    "$chrome_real_bin" --version || true
  else
    log "Baixando Google Chrome"
    rm -f "$chrome_package"

    if ! curl -fL --retry 3 --connect-timeout 20 \
      "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
      -o "$chrome_package"; then
      fail "Nao foi possivel baixar o instalador do Google Chrome."
      CHROME_STATUS="Falha no download"
      return 1
    fi

    log "Instalando Google Chrome"
    if ! run_sudo apt install -y "$chrome_package"; then
      repair_apt
      run_sudo apt install -y "$chrome_package" || {
        fail "Nao foi possivel instalar o Google Chrome."
        CHROME_STATUS="Falha na instalacao"
        return 1
      }
    fi

    rm -f "$chrome_package"

    if check_command google-chrome-stable; then
      chrome_real_bin="$(command -v google-chrome-stable)"
    elif [[ -x /usr/bin/google-chrome ]]; then
      chrome_real_bin="/usr/bin/google-chrome"
    else
      fail "Google Chrome foi instalado, mas o executavel nao foi encontrado."
      CHROME_STATUS="Executavel nao encontrado"
      return 1
    fi
  fi

  log "Configurando Google Chrome para usar --no-sandbox"

  run_sudo tee /usr/local/bin/google-chrome >/dev/null <<EOF
#!/usr/bin/env bash
exec "$chrome_real_bin" --no-sandbox "\$@"
EOF

  run_sudo chmod +x /usr/local/bin/google-chrome
  run_sudo ln -sfn /usr/local/bin/google-chrome /usr/local/bin/google-chrome-no-sandbox

  CHROME_VERSION="$("$chrome_real_bin" --version 2>/dev/null || echo 'Versao nao identificada')"
  CHROME_STATUS="Instalado e configurado com --no-sandbox"

  echo "$CHROME_VERSION"
  echo "Comando configurado: google-chrome"
}

check_cpu_required() {
  local flag="$1"
  local name="$2"

  if [[ " $CPU_FLAGS " == *" $flag "* ]]; then
    printf "  [OK]    %s\n" "$name"
  else
    printf "  [ERRO]  %s nao suportado\n" "$name"
    CPU_ERROR=1
  fi
}

log "Verificando Ubuntu"

if [[ ! -f /etc/os-release ]]; then
  fail "Nao foi possivel identificar o sistema operacional."
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
  fail "Sistema nao suportado. Este script foi feito para Ubuntu."
fi

if [[ "${VERSION_ID:-}" != "22.04" && "${VERSION_ID:-}" != "24.04" ]]; then
  fail "Ubuntu ${VERSION_ID:-desconhecido} nao suportado. Use Ubuntu 22.04 ou 24.04."
fi

echo "Ubuntu $VERSION_ID OK"

log "Verificando CPU e instrucoes obrigatorias"
info "O instalador verificara SSE4.2, POPCNT, AVX e AVX2."
info "Sem essas instrucoes, a instalacao pode falhar e o container tas-service pode permanecer nao saudavel."

CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo | cut -d ':' -f2- | xargs)"
CPU_FLAGS="$(grep -m1 '^flags' /proc/cpuinfo || true)"

echo "CPU: $CPU_MODEL"
echo

echo "Instrucoes obrigatorias:"
check_cpu_required sse4_2 "SSE4.2"
check_cpu_required popcnt "POPCNT"
check_cpu_required avx "AVX"
check_cpu_required avx2 "AVX2"

VIRTUALIZATION_STATUS="Nao verificada"

if [[ "$CPU_ERROR" -ne 0 ]]; then
  CPU_STATUS="Incompativel"
  fail "A CPU nao suporta todas as instrucoes obrigatorias: SSE4.2, POPCNT, AVX e AVX2.
Sem essas instrucoes, a instalacao do FH2 OP pode apresentar erros. Em especial, o container tas-service pode nao ficar saudavel, impedindo o funcionamento correto da plataforma."
else
  CPU_STATUS="OK"
  echo "[OK] Todas as instrucoes obrigatorias estao disponiveis."
fi

log "Verificando memoria RAM alocada ao sistema"
info "Para utilizar o modulo de reconstrucao Terra, o sistema deve ter mais de 32 GB de RAM alocada."
info "Com 32 GB ou menos, a maquina e indicada apenas para o FH2 OP sem o modulo de reconstrucao."
info "Quando nao ha memoria suficiente para o Terra, os mapeamentos podem nao ser processados e as tarefas permanecem como 'Pendente'."

RAM_GB="$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)"
echo "RAM alocada detectada: ${RAM_GB} GB"

if (( RAM_GB <= 32 )); then
  RAM_STATUS="Limitada para FH2 sem Terra"
  fail "Foram detectados ${RAM_GB} GB de RAM alocada.
Uma maquina com 32 GB ou menos e viavel apenas para uma instalacao do FH2 OP sem o modulo de reconstrucao Terra.
Se o Terra for instalado nessas condicoes, os mapeamentos podem nao ser processados e as tarefas podem permanecer como 'Pendente'."
else
  RAM_STATUS="Adequada para FH2 e Terra"
  echo "[OK] Memoria superior a 32 GB, adequada para FH2 OP com modulo de reconstrucao Terra."
fi

log "Verificando armazenamento do sistema"
info "O instalador precisa de pelo menos 300 GB livres durante a instalacao."
info "O disco fisico que hospeda o sistema deve possuir no minimo 1 TB de capacidade total."

ROOT_SOURCE="$(findmnt -n -o SOURCE /)"
ROOT_DISK_NAME="$(lsblk -s -n -o NAME,TYPE "$ROOT_SOURCE" 2>/dev/null | awk '$2=="disk" {print $1; exit}')"

if [[ -n "$ROOT_DISK_NAME" ]]; then
  SYSTEM_DISK="/dev/$ROOT_DISK_NAME"
  DISK_TOTAL_GB="$(lsblk -b -dn -o SIZE "$SYSTEM_DISK" | awk '{printf "%.0f", $1/1024/1024/1024}')"
else
  SYSTEM_DISK="Nao identificado"
  DISK_TOTAL_GB=0
fi

DISK_FREE_GB="$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')"

echo "Dispositivo fisico do sistema: $SYSTEM_DISK"
echo "Capacidade total detectada: ${DISK_TOTAL_GB} GB"
echo "Espaco livre disponivel em /: ${DISK_FREE_GB} GB"

if [[ "$SYSTEM_DISK" == "Nao identificado" ]]; then
  DISK_TOTAL_STATUS="Nao identificado"
  fail "Nao foi possivel identificar automaticamente o disco fisico que hospeda o sistema.
Confirme manualmente que o disco possui pelo menos 1 TB antes de instalar o FH2 OP. Prosseguir sem essa verificacao pode resultar em falta de capacidade durante a operacao."
elif (( DISK_TOTAL_GB < 1000 )); then
  DISK_TOTAL_STATUS="Abaixo de 1 TB"
  fail "O disco fisico do sistema possui aproximadamente ${DISK_TOTAL_GB} GB.
O requisito minimo e um disco fisico de 1 TB.
Ao prosseguir abaixo desse requisito, pode faltar capacidade para dados, imagens, bancos de dados, logs e resultados de reconstrucao, comprometendo a operacao e o crescimento do ambiente."
else
  DISK_TOTAL_STATUS="OK"
  echo "[OK] O disco fisico atende ao minimo de 1 TB."
fi

if (( DISK_FREE_GB < 300 )); then
  DISK_FREE_STATUS="Insuficiente para instalar"
  fail "Existem apenas ${DISK_FREE_GB} GB livres em /.
O instalador precisa de pelo menos 300 GB livres no momento da instalacao para extrair imagens, criar containers e preparar os componentes.
Se prosseguir, a instalacao pode falhar por falta de espaco e deixar o ambiente parcialmente instalado."
else
  DISK_FREE_STATUS="OK"
  echo "[OK] Ha pelo menos 300 GB livres para executar a instalacao."
fi

if [[ "$CHECK_ONLY" -eq 0 ]]; then
  update_system_packages

  log "Instalando utilitarios necessarios"
  run_sudo apt install -y pciutils ubuntu-drivers-common curl ca-certificates iputils-ping
else
  log "Ignorando atualizacao e instalacao de pacotes"
  info "Modo de verificacao ativo: apt update, apt upgrade e instalacao de utilitarios nao serao executados."
fi

log "Verificando GPU NVIDIA"

if check_command lspci; then
  GPU_NVIDIA="$(lspci | grep -i nvidia || true)"
else
  GPU_NVIDIA=""
  warn "O comando lspci nao esta instalado. Nao foi possivel verificar a GPU sem instalar pacotes."
fi

if [[ -z "$GPU_NVIDIA" ]]; then
  warn "Nenhuma GPU NVIDIA detectada."
  NVIDIA_STATUS="Nao detectada"
  NVIDIA_DRIVER_STATUS="Nao instalado"
else
  echo "$GPU_NVIDIA"
  NVIDIA_STATUS="Detectada"

  if check_command nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    echo "Driver NVIDIA ja esta instalado e funcionando."
    NVIDIA_DRIVER_STATUS="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)"
  else
    if [[ "$CHECK_ONLY" -eq 1 ]]; then
      warn "Driver NVIDIA nao instalado ou nao funcional."
      info "Modo de verificacao: o driver recomendado nao sera instalado."
      NVIDIA_DRIVER_STATUS="Nao instalado ou nao funcional"
    elif echo "$GPU_NVIDIA" | grep -qiE 'RTX 5000|RTX PRO 5000|RTX 5080'; then
      log "GPU RTX 5000/5080 detectada. Instalando driver NVIDIA open recomendado."

      OPEN_DRIVER="$(ubuntu-drivers devices | awk '/nvidia-driver-[0-9]+-open/ && /recommended/ {print $3; exit}')"

      if [[ -z "$OPEN_DRIVER" ]]; then
        OPEN_DRIVER="$(ubuntu-drivers devices | awk '/nvidia-driver-[0-9]+-open/ {print $3; exit}')"
      fi

      if [[ -z "$OPEN_DRIVER" ]]; then
        fail "Nao foi encontrado driver NVIDIA open recomendado."
      else
        run_sudo apt install -y "$OPEN_DRIVER"
        NVIDIA_DRIVER_STATUS="$OPEN_DRIVER"
      fi
    else
      RECOMMENDED_DRIVER="$(ubuntu-drivers devices | awk '/recommended/ {print $3; exit}')"

      if [[ -z "$RECOMMENDED_DRIVER" ]]; then
        fail "Nao foi encontrado driver NVIDIA recomendado."
        NVIDIA_DRIVER_STATUS="Nao identificado"
      else
        run_sudo apt install -y "$RECOMMENDED_DRIVER"
        NVIDIA_DRIVER_STATUS="$RECOMMENDED_DRIVER"
      fi
    fi
  fi
fi

if [[ "$CHECK_ONLY" -eq 0 ]]; then
  log "Configurando locale en_US.UTF-8"
  run_sudo locale-gen en_US.UTF-8
  run_sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

  log "Configurando timezone America/Sao_Paulo"
  run_sudo timedatectl set-timezone America/Sao_Paulo
else
  log "Verificando locale e timezone sem alterar o sistema"
  echo "Locale atual: ${LANG:-Nao identificado}"
  echo "Timezone atual: $(timedatectl show -p Timezone --value 2>/dev/null || echo 'Nao identificado')"
fi

log "Verificando conectividade com Internet"

if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
  echo "Internet OK"
else
  fail "Sem conectividade com Internet."
fi

log "Verificando DNS"

if getent hosts google.com >/dev/null 2>&1; then
  echo "DNS OK"
else
  fail "Resolucao DNS falhou."
fi

CHROME_STATUS="Nao verificado"
CHROME_VERSION="Nao identificado"

log "Verificando sincronizacao de horario"

if [[ "$CHECK_ONLY" -eq 0 ]]; then
  run_sudo timedatectl set-ntp true
else
  info "Modo de verificacao: a sincronizacao NTP nao sera habilitada ou alterada."
fi

if timedatectl | grep -q "System clock synchronized: yes"; then
  echo "NTP OK"
else
  warn "NTP habilitado, mas a sincronizacao ainda nao foi confirmada."
fi

log "Desabilitando firewall UFW"

if check_command ufw; then
  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    FIREWALL_STATUS="$(ufw status 2>/dev/null | head -n1 | sed 's/^Status: //')"
    info "Modo de verificacao: o firewall UFW nao sera desabilitado."
  else
    run_sudo ufw disable || true
    FIREWALL_STATUS="Desabilitado"
  fi
else
  FIREWALL_STATUS="UFW nao instalado"
fi

echo "Firewall: $FIREWALL_STATUS"

DOCKER_STATUS="Nao verificado"
install_recommended_docker

log "Criando estrutura de diretorios na raiz do sistema"
info "Serao criados os diretorios /fhop-install/install, /data/fhop-data, /terra-install e /4G-install."
info "As antigas pastas arquiv_install e flighthub nao serao criadas."

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  info "Modo de verificacao: os diretorios nao serao criados."
  DIRECTORIES_STATUS="Nao criadas (check-only)"
else
  # Instalacao do FlightHub OP
  run_sudo mkdir -p /fhop-install/install

  # Dados do FlightHub OP
  run_sudo mkdir -p /data/fhop-data

  # Instalacao do Terra
  run_sudo mkdir -p /terra-install

  # Instalacao do modulo 4G
  run_sudo mkdir -p /4G-install

  echo "Estrutura de diretorios criada com sucesso."
  DIRECTORIES_STATUS="Criadas"
fi

echo
echo "=============================="
echo " FlightHub 2 OP Pre-Check"
echo "=============================="
echo "Modo............... $( [[ "$CHECK_ONLY" -eq 1 ]] && echo "Somente verificacao" || echo "Preparacao/instalacao" )"
echo "Ubuntu............. $VERSION_ID OK"
echo "CPU................ $CPU_MODEL"
echo "CPU Recursos....... $CPU_STATUS"
echo "Virtualizacao...... $VIRTUALIZATION_STATUS"
echo "RAM................ ${RAM_GB} GB - $RAM_STATUS"
echo "Disco fisico....... ${DISK_TOTAL_GB} GB - $DISK_TOTAL_STATUS"
echo "Disco livre em /... ${DISK_FREE_GB} GB - $DISK_FREE_STATUS"
echo "GPU NVIDIA......... $NVIDIA_STATUS"
echo "Driver NVIDIA...... $NVIDIA_DRIVER_STATUS"
echo "Internet........... OK"
echo "DNS................ OK"
echo "Firewall........... $FIREWALL_STATUS"
echo "Docker............. $DOCKER_STATUS"
echo "Chrome............. $CHROME_STATUS"
echo "Chrome versao...... $CHROME_VERSION"
echo "Pastas............. $DIRECTORIES_STATUS"
echo "=============================="
echo

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  log "Verificando Google Chrome sem instalar"
  if check_command google-chrome-stable; then
    CHROME_VERSION="$(google-chrome-stable --version 2>/dev/null || echo 'Versao nao identificada')"
    CHROME_STATUS="Instalado"
  elif [[ -x /usr/bin/google-chrome ]]; then
    CHROME_VERSION="$(/usr/bin/google-chrome --version 2>/dev/null || echo 'Versao nao identificada')"
    CHROME_STATUS="Instalado"
  else
    CHROME_STATUS="Nao instalado"
    CHROME_VERSION="Nao identificado"
  fi
  info "Modo de verificacao: o Chrome nao sera baixado, instalado ou configurado."
else
  install_google_chrome
fi

echo "Chrome............. $CHROME_STATUS"
echo "Chrome versao...... $CHROME_VERSION"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo
  echo "Verificacao concluida. Nenhuma alteracao foi realizada no sistema."
elif [[ "$REBOOT_AFTER_INSTALL" -eq 1 ]]; then
  log "Reiniciando o sistema"
  run_sudo reboot
else
  echo "Concluido. Reinicie depois para ativar o driver NVIDIA, caso ele tenha sido instalado agora:"
  echo "  sudo reboot"
fi
