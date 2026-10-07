# Script de Preparação do Ambiente para o FlightHub 2 On-Premises

Este script automatiza a verificação e preparação de servidores Ubuntu para instalação do **DJI FlightHub 2 On-Premises (FH2 OP)**.

Ele foi desenvolvido com base nos requisitos oficiais da DJI e na experiência prática adquirida durante diversas implantações, reduzindo o tempo de preparação do ambiente e evitando problemas recorrentes durante a instalação.

---

# Versão mais recente e download

A release mais recente é a **[v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5)**, publicada em **06/10/2026**.

Baixe o pacote anexado à release: **[fh2-v5.5-bundle.tar.gz](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz)**.

**Integridade:** o SHA-256 de `fh2-v5.5-bundle.tar.gz` é `1a762907e488985dd6d0b2f2f8b3deff6bd800a335c41f70c9ffb230c3b11981`. O arquivo `.sha256` também está anexado à release.

**Pacote da release conferido:** a extração cria `fh2-onprem-prep-tool-v5.5/`, contendo o script v5.5, `docker.tar.gz`, `SHA256SUMS` e os bundles locais para Ubuntu 22.04 e 24.04. O código da tag e o script incluído no pacote correspondem à mesma revisão.

## O que mudou na v5.5

- Adicionado o modo `--offline`, com seleção automática de `packages/ubuntu-$VERSION_ID`.
- Adicionada a opção `--offline-dir CAMINHO` para bundles armazenados em outro local.
- Incluídos bundles de dependências base e do Google Chrome para Ubuntu 22.04 e 24.04.
- O APT offline usa listas e cache temporários isolados, sem participar da resolução com índices externos existentes.
- O modo offline não executa `apt update`, `apt upgrade`, `apt autoremove`, `apt autoclean`, testes externos de Internet/DNS ou habilitação de NTP externo.
- Docker Engine 27.2.0, Docker Compose 2.29.2 e containerd 1.7.21 são instalados pelo pacote local e bloqueados com `apt-mark hold` após validação.
- Google Chrome 155.0.8059.39 é instalado pelo repositório APT local.
- Adicionada validação de integridade pelo manifesto `SHA256SUMS`.
- A instalação automática genérica de driver NVIDIA permanece desabilitada no modo offline; uma GPU sem driver funcional exige um bundle compatível com a combinação GPU/kernel.
- O bundle Docker foi simplificado, removendo uma cópia aninhada redundante dos mesmos pacotes.

### Validações da v5.5

- Sintaxe Bash aprovada.
- Todos os pacotes `.deb` foram validados por metadados e arquitetura.
- Bundle base 24.04 confirmado com `locales` e sua cadeia de dependências.
- Chrome 24.04 validado por fechamento estático e simulação APT usando exclusivamente o repositório local: 196 pacotes instaláveis e zero dependências não resolvidas.
- Estrutura, permissões, hashes internos e arquivo compactado final conferidos.
- Uma instalação final do bundle reconstruído em VMs mínimas ainda é recomendada antes da implantação em produção.

## O que mudou na v5.4.1

Conforme as [notas da release](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.4.1), também confirmado no código atualizado da `main`:

- Inclusão do `iptables` entre os pacotes instalados antes do Docker.
- Validação do estado de instalação do `iptables` e do funcionamento de seu comando de versão. Se essa validação falhar, a preparação é interrompida antes da instalação do Docker.
- Verificação de `iptables`, `docker-ce`, `docker-ce-cli` e `containerd.io` após a instalação. Todos devem apresentar o estado `install ok installed` antes da validação e do bloqueio das versões.
- Interrupção da execução se algum desses pacotes estiver ausente ou com configuração incompleta.
- Inicialização das variáveis de versão para evitar erros de variável não definida quando um componente não for detectado.

As notas registram aprovação da sintaxe Bash e testes simulados de diferentes estados do `iptables`. A instalação completa do Docker não foi testada no ambiente usado para aquela validação.

## O que mudou na v5.4

Conforme as [notas da release v5.4](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.4), também confirmado no código da `main`:

- Proteção dos pacotes Docker já instalados com `apt-mark hold` antes da atualização do Ubuntu e das tentativas de reparo de dependências.
- Liberação desses pacotes na etapa específica de instalação, após confirmação da substituição do Docker existente e validação dos arquivos necessários.
- Manutenção dos bloqueios quando o usuário escolhe preservar a instalação atual.
- Reaplicação do bloqueio após a instalação e validação das versões esperadas.
- Verificação e configuração do Chrome antes do relatório final, que passa a apresentar seu status e sua versão.

# Download e preparação dos arquivos

Baixe e extraia o pacote da release:

```bash
curl -fL --retry 3 \
  "https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz" \
  -o fh2-v5.5-bundle.tar.gz

tar -xzvf fh2-v5.5-bundle.tar.gz
cd fh2-onprem-prep-tool-v5.5
```

A pasta criada já contém `fh2-onprem-prep-tool-v5.5.sh`, `docker.tar.gz`, `SHA256SUMS` e `packages/`. Valide a integridade:

```bash
sha256sum -c SHA256SUMS
```

Depois execute a verificação:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

Após conferir os resultados, prepare o ambiente no modo offline:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
```

Para informar outro local de pacotes:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --offline-dir /mnt/usb/fh2-offline
```

O fluxo online permanece disponível com `sudo bash fh2-onprem-prep-tool-v5.5.sh`.

Para instalar ou substituir o Docker, mantenha **`docker.tar.gz` na mesma pasta do script principal**. O arquivo deve conter `docker/install_docker.sh` e `docker/uninstall_docker.sh`, caminhos validados explicitamente após a extração.

No repositório, `docker.tar.gz` é armazenado com **Git LFS**. Um arquivo pequeno contendo `version https://git-lfs.github.com/spec/v1` é apenas um ponteiro, não o pacote instalável. Ao usar um clone Git, obtenha o conteúdo LFS; para a distribuição publicada, prefira o anexo da release.

---

# Funcionalidades

- Verificação de compatibilidade do Ubuntu
- Verificação das instruções obrigatórias da CPU
- Validação da memória RAM
- Validação do armazenamento
- Verificação da GPU NVIDIA
- Proteção dos pacotes Docker antes da atualização do Ubuntu
- Validação exata das versões do Docker Engine, Docker Compose e containerd após instalar o pacote recomendado
- Bloqueio automático dos pacotes do Docker após a validação
- Instalação e configuração do Google Chrome
- Verificação de Internet e DNS
- Verificação da sincronização de horário (NTP)
- Configuração do Firewall
- Criação automática da estrutura de diretórios
- Relatório completo ao final da execução
- Modo de verificação (sem alterações no sistema)
- Modo de preparação offline com dependências locais

---

# Sistemas Operacionais Suportados

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

O código verifica a distribuição e a versão em `/etc/os-release`, sem diferenciar Server de Desktop.

---

# Modos de Execução

Execute os comandos abaixo dentro da pasta `fh2-onprem-prep-tool`. Com `sudo bash`, não é necessário alterar a permissão de execução do script.

## 1. Apenas verificar o ambiente (Recomendado)

Executa as verificações disponíveis sem alterar o sistema.

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

Neste modo o script:

- verifica os itens implementados no script, conforme as ferramentas já disponíveis;
- gera um relatório completo.

**Nenhuma alteração é realizada**, incluindo:

- atualização do sistema;
- instalação de pacotes;
- instalação de drivers;
- instalação ou remoção do Docker;
- instalação do Google Chrome;
- alteração de firewall;
- alteração de locale;
- alteração de timezone;
- habilitação do NTP;
- criação de diretórios;
- reinicialização do servidor.

---

O modo `--check-only` não valida as três versões exatas do Docker nem confirma os bloqueios APT existentes. Ele identifica a versão principal do Docker e a presença do Compose. Se `--reboot` também for informado, a reinicialização é ignorada.

## 2. Preparar o ambiente

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

Além das verificações, o script realiza automaticamente toda a preparação necessária para instalação do FlightHub 2 On-Premises.

---

## 3. Preparar o ambiente e reiniciar automaticamente

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --reboot
```

Executa toda a preparação e reinicia automaticamente o servidor ao final da execução.

---

## 4. Preparar o ambiente sem acesso à Internet

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline
```

O script seleciona automaticamente `packages/ubuntu-22.04` ou `packages/ubuntu-24.04`. Use `--offline-dir CAMINHO` para fornecer outro bundle.

---

# O que o script verifica?

## Sistema Operacional

Confirma se o servidor está executando uma versão compatível do Ubuntu.

---

## CPU

São verificadas as instruções obrigatórias:

- SSE4.2
- POPCNT
- AVX
- AVX2

Estas instruções são indispensáveis para o funcionamento correto do FlightHub 2.

Caso alguma delas esteja ausente, a instalação poderá falhar.

O principal sintoma observado é o container **tas-service** permanecer com status **Unhealthy**.

---

## Memória RAM

Para utilização do módulo de reconstrução (**Terra**) recomenda-se que o servidor possua **mais de 32 GB de memória RAM alocada**.

### Acima de 32 GB

Recomendado para:

- FlightHub 2
- Terra (Reconstrução)

### 32 GB ou menos

Adequado apenas para:

- FlightHub 2

Caso o módulo Terra seja instalado nessas condições, é comum que as tarefas de reconstrução permaneçam permanentemente no estado:

```
Pendente
```

---

## Armazenamento

São realizadas duas verificações independentes.

### Espaço livre

É necessário possuir pelo menos:

```
300 GB livres
```

Este espaço é utilizado durante a instalação para:

- imagens Docker;
- bancos de dados;
- arquivos temporários;
- componentes do FlightHub.

---

### Capacidade do disco

O disco físico onde o Ubuntu está instalado deve possuir capacidade mínima de:

```
1 TB
```

Essa recomendação garante espaço suficiente para:

- banco de dados;
- imagens;
- vídeos;
- logs;
- resultados de reconstrução;
- crescimento futuro da instalação.

No código consultado, a capacidade é calculada dividindo os bytes por `1024³` e comparada com `1000`; portanto, um disco comercial de 1 TB (aproximadamente 931 GiB) pode ser sinalizado como abaixo do mínimo. O espaço livre é verificado em `/` com `df -BG`, usando o limite de 300.

A versão 5.3.1 também melhora a detecção do disco físico em sistemas nos quais o `lsblk` exibe caracteres de árvore, evitando erros como:

```text
lsblk: /dev/└─sda: not a block device
```

---

## Docker

Na preparação normal, os pacotes Docker instalados são protegidos antes de `apt upgrade` e dos reparos de dependências. Bloqueios existentes são preservados nessa etapa. Se Docker ou Compose já estiverem presentes, a substituição exige confirmação; a resposta padrão é manter a instalação atual.

Ao manter o Docker atual, os bloqueios permanecem, mas o script não executa a validação exata das três versões. Após instalar o pacote recomendado, são validadas as versões exatas do Docker Engine, Docker Compose e containerd.

Versões homologadas:

```text
Docker Engine 27.2.0
Docker Compose 2.29.2
containerd 1.7.21
```

Após instalar e validar essas versões, o script bloqueia os seguintes pacotes APT com `apt-mark hold`:

- `docker-ce`
- `docker-ce-cli`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- `containerd.io`

O bloqueio somente é aplicado quando todas as versões instaladas correspondem ao pacote homologado. Caso alguma versão seja diferente, o script apresenta as versões esperadas e detectadas e interrompe a preparação. Isso evita o bloqueio de uma instalação incorreta do Docker.

O bloqueio impede que comandos rotineiros, como `apt upgrade` e `apt full-upgrade`, alterem automaticamente as versões do Docker exigidas pelo FlightHub 2 On-Premises.

O **Docker 29 não é suportado**.

Durante implantações práticas foram observados erros fatais no frontend do FlightHub 2 utilizando essa versão.

---

## GPU NVIDIA

Caso exista uma GPU NVIDIA instalada, o script verifica se o driver está corretamente instalado.

Durante a preparação completa, o driver recomendado é instalado automaticamente quando necessário.

No modo offline, a instalação automática genérica de drivers NVIDIA é deliberadamente desabilitada. Se uma GPU for detectada sem driver funcional, o script interrompe a preparação e solicita um bundle compatível com a GPU e o kernel do cliente.

---

## Internet

Verifica se o servidor possui acesso à Internet.

No modo offline, essa verificação externa é ignorada.

---

## DNS

Verifica se o servidor consegue resolver nomes de domínio.

No modo offline, essa verificação externa é ignorada.

---

## Sincronização de Horário

Verifica o funcionamento do NTP.

Durante a preparação completa, o NTP é habilitado automaticamente.

No modo offline, NTP externo não é habilitado automaticamente; quando necessário, deve ser usado um servidor NTP interno.

---

## Firewall

Verifica a presença do UFW.

Durante a preparação completa, o firewall é desabilitado automaticamente.

---

# Estrutura de Diretórios

Durante a preparação serão criados os seguintes diretórios:

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

# Alterações realizadas durante a preparação

Quando executado sem a opção `--check-only`, o script pode:

- Atualizar o Ubuntu;
- Corrigir dependências quebradas do APT;
- Instalar utilitários necessários;
- Instalar ou substituir o Docker Engine, Docker Compose e containerd pelas versões homologadas;
- Bloquear os pacotes validados do Docker para impedir atualizações automáticas;
- Instalar e configurar o Google Chrome (`--no-sandbox`);
- Instalar o driver NVIDIA recomendado;
- Configurar o locale para `en_US.UTF-8`;
- Configurar o fuso horário `America/Sao_Paulo`;
- Habilitar a sincronização NTP;
- Desabilitar o firewall UFW;
- Criar toda a estrutura de diretórios necessária para o FlightHub 2.

---

# Relatório Final

Ao término da execução é apresentado um resumo contendo:

- Modo de execução;
- Versão do Ubuntu;
- Modelo da CPU;
- Compatibilidade da CPU;
- Memória RAM;
- Capacidade do disco;
- Espaço livre disponível;
- GPU NVIDIA;
- Driver NVIDIA;
- Internet;
- DNS;
- Firewall;
- Docker;
- Status do bloqueio das versões do Docker;
- Google Chrome;
- Status da criação dos diretórios.

Consulte também as mensagens de cada etapa. No código atual, Internet e DNS aparecem como `OK` no resumo mesmo após uma falha se a execução continuar; o campo de virtualização permanece `Nao verificada`. O relatório não representa uma certificação completa do ambiente.

---

# Fluxo recomendado

Antes de iniciar qualquer instalação do FlightHub 2 On-Premises:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
```

Após corrigir todos os itens apontados pelo relatório:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

Caso deseje que o servidor seja reiniciado automaticamente ao final da preparação:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --reboot
```

---

# Sobre o projeto

Este script foi desenvolvido para auxiliar na preparação de ambientes destinados à instalação do DJI FlightHub 2 On-Premises.

Ele não substitui a documentação oficial da DJI, mas complementa o processo de instalação com validações adicionais e automações baseadas em experiências reais de implantação.
