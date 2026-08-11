# Script de Preparação do Ambiente para o FlightHub 2 On-Premises

Este script automatiza a verificação e preparação de servidores Ubuntu para instalação do **DJI FlightHub 2 On-Premises (FH2 OP)**.

Ele foi desenvolvido com base nos requisitos oficiais da DJI e na experiência prática adquirida durante diversas implantações, reduzindo o tempo de preparação do ambiente e evitando problemas recorrentes durante a instalação.

---

# Funcionalidades

- Verificação de compatibilidade do Ubuntu
- Verificação das instruções obrigatórias da CPU
- Validação da memória RAM
- Validação do armazenamento
- Verificação da GPU NVIDIA
- Validação exata das versões do Docker Engine, Docker Compose e containerd
- Bloqueio automático dos pacotes do Docker após a validação
- Instalação e configuração do Google Chrome
- Verificação de Internet e DNS
- Verificação da sincronização de horário (NTP)
- Configuração do Firewall
- Criação automática da estrutura de diretórios
- Relatório completo ao final da execução
- Modo de verificação (sem alterações no sistema)

---

# Sistemas Operacionais Suportados

- Ubuntu Server 22.04 LTS
- Ubuntu Server 24.04 LTS

---

# Modos de Execução

## 1. Apenas verificar o ambiente (Recomendado)

Executa todas as verificações sem alterar o sistema.

```bash
sudo ./setup_fh2VER5.3.1.sh --check-only
```

Neste modo o script:

- verifica todos os requisitos;
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

## 2. Preparar o ambiente

```bash
sudo ./setup_fh2VER5.3.1.sh
```

Além das verificações, o script realiza automaticamente toda a preparação necessária para instalação do FlightHub 2 On-Premises.

---

## 3. Preparar o ambiente e reiniciar automaticamente

```bash
sudo ./setup_fh2VER5.3.1.sh --reboot
```

Executa toda a preparação e reinicia automaticamente o servidor ao final da execução.

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

A versão 5.3.1 também melhora a detecção do disco físico em sistemas nos quais o `lsblk` exibe caracteres de árvore, evitando erros como:

```text
lsblk: /dev/└─sda: not a block device
```

---

## Docker

O script valida as versões exatas do Docker Engine, Docker Compose e containerd.

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

---

## Internet

Verifica se o servidor possui acesso à Internet.

---

## DNS

Verifica se o servidor consegue resolver nomes de domínio.

---

## Sincronização de Horário

Verifica o funcionamento do NTP.

Durante a preparação completa, o NTP é habilitado automaticamente.

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

Esse relatório permite identificar rapidamente qualquer requisito que ainda precise ser corrigido antes da instalação do FlightHub 2.

---

# Fluxo recomendado

Antes de iniciar qualquer instalação do FlightHub 2 On-Premises:

```bash
sudo ./setup_fh2VER5.3.1.sh --check-only
```

Após corrigir todos os itens apontados pelo relatório:

```bash
sudo ./setup_fh2VER5.3.1.sh
```

Caso deseje que o servidor seja reiniciado automaticamente ao final da preparação:

```bash
sudo ./setup_fh2VER5.3.1.sh --reboot
```

---

# Licença

Este script foi desenvolvido para auxiliar na preparação de ambientes destinados à instalação do DJI FlightHub 2 On-Premises.

Ele não substitui a documentação oficial da DJI, mas complementa o processo de instalação com validações adicionais e automações baseadas em experiências reais de implantação.
