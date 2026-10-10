# Preparação do ambiente para FlightHub 2 On-Premises

Há duas versões para preparar Ubuntu 22.04/24.04 para o DJI FlightHub 2 On-Premises. Ambas verificam o ambiente e configuram o sistema; a instalação do FlightHub 2 e do Terra é feita separadamente.

## Qual versão usar?

| Situação | Versão indicada | Arquivos necessários |
| --- | --- | --- |
| Servidor com Internet e acesso aos repositórios Ubuntu, Docker e Google | **v5.5 Online** | Apenas `fh2-onprem-prep-tool-v5.5-online.sh` |
| Servidor sem Internet ou com downloads externos bloqueados | **v5.5 com bundle**, usando `--offline` | Pacote completo da release: script, `docker.tar.gz`, `SHA256SUMS` e `packages/` |
| Já possui o bundle e quer usar Internet para Ubuntu, Chrome e driver NVIDIA | **v5.5 com bundle**, sem `--offline` | O bundle continua necessário para instalar/substituir o Docker |

**A v5.5 Online está na branch `v5.5-online`, em revisão no [PR #1](https://github.com/caioboamorte/fhop_prep_env/pull/1). Ela ainda não está em uma release.** A versão com bundle está na [release v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5). O número 5.5 identifica as duas variantes; o sufixo `-online` diferencia o script que baixa também o Docker pela Internet.

## 1. v5.5 Online: baixar e executar

Use esta versão quando o servidor puder baixar todos os componentes pela Internet. Não precisa baixar nem extrair `docker.tar.gz`.

Execute no terminal Ubuntu:

```bash
curl -fL --retry 3 \
  "https://raw.githubusercontent.com/caioboamorte/fhop_prep_env/v5.5-online/fh2-onprem-prep-tool-v5.5-online.sh" \
  -o fh2-onprem-prep-tool-v5.5-online.sh

sudo bash fh2-onprem-prep-tool-v5.5-online.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5-online.sh
```

Execute primeiro o comando com `--check-only`, confira o relatório e depois execute a preparação. Não é necessário dar permissão com `chmod` ao usar `sudo bash`.

Para reiniciar automaticamente ao final, execute a preparação com `--reboot`:

```bash
sudo bash fh2-onprem-prep-tool-v5.5-online.sh --reboot
```

Esta variante:
- baixa dependências pelos repositórios Ubuntu e o Chrome pelo site do Google;
- instala o driver NVIDIA recomendado quando a GPU é detectada sem driver funcional;
- configura o repositório oficial Docker e seleciona Engine/CLI **27.2.0**, Compose **2.29.2**, containerd **1.7.21** e Buildx **0.16.2**;
- baixa os cinco pacotes Docker antes de remover pacotes conflitantes; dependências adicionais são resolvidas online durante a instalação;
- interrompe a instalação se não encontrar uma versão exata, sem substituir por `latest`;
- mantém o conjunto já instalado se as três versões principais estiverem corretas e aplica `apt-mark hold`;
- solicita confirmação antes de ajustar um Docker existente, inclusive downgrade. A instalação pode reiniciar o Docker e interromper containers.

Não aceita `--offline` nem `--offline-dir`. Internet para baixar apenas o script não é suficiente: o servidor precisa acessar também as fontes dos pacotes.

## 2. v5.5 com bundle: baixar e executar offline

Em um computador com Internet, baixe o **anexo `fh2-v5.5-bundle.tar.gz` da release**, transfira-o inteiro para o servidor por pendrive, SCP ou outro meio e execute a extração e os comandos de verificação no servidor.

O fluxo completo abaixo inclui o download, que deve ocorrer no computador conectado:

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

**No servidor sem Internet, comece em `echo ... | sha256sum -c -` depois de transferir o arquivo.** O `--offline --check-only` verifica o ambiente sem alterar o sistema e sem testes externos de Internet/DNS.

A extração cria `fh2-onprem-prep-tool-v5.5/`. Mantenha o script e `docker.tar.gz` nessa pasta. O diretório `packages/` contém os bundles por versão do Ubuntu; o script escolhe automaticamente `packages/ubuntu-22.04` ou `packages/ubuntu-24.04`.

Para usar dependências base e Chrome em outro local, forneça o diretório que contém `base/` e `chrome/`:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --offline-dir /mnt/usb/fh2-offline
```

`--offline-dir` não altera a localização de `docker.tar.gz`: ele continua ao lado do script. Esse parâmetro também ativa o modo offline.

No modo offline:
- o APT resolve dependências com listas e cache locais isolados;
- não há atualização geral do Ubuntu nem downloads externos;
- testes externos de Internet/DNS e habilitação de NTP externo são ignorados;
- Docker, Compose, containerd, Chrome e dependências base vêm do bundle;
- o driver NVIDIA não é instalado automaticamente. Prepare um driver compatível com a GPU e o kernel antes de executar, se necessário;
- a integridade do bundle é verificada pelo manifesto `SHA256SUMS`, quando presente.

Para reiniciar ao final:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --offline --reboot
```

**Não use “Source code (zip/tar.gz)” como substituto do anexo da release.** O `docker.tar.gz` do repositório usa Git LFS e pode aparecer apenas como um pequeno arquivo ponteiro; prefira o bundle publicado.

## 3. Usar o bundle com Internet

A versão com bundle também pode ser executada sem `--offline`:

```bash
sudo bash fh2-onprem-prep-tool-v5.5.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5.sh
```

Nesse caso, Ubuntu, dependências, driver NVIDIA e Chrome podem ser baixados online, mas a instalação/substituição do Docker ainda usa o `docker.tar.gz` local. Para baixar também o Docker da Internet, escolha **v5.5 Online**.

## Opções e limites

| Opção | v5.5 Online | v5.5 com bundle |
| --- | --- | --- |
| `--check-only` | Verificação sem alterações | Verificação sem alterações; combine com `--offline` em servidor isolado |
| `--reboot` | Reinicia após preparação | Reinicia após preparação |
| `--offline` | Não disponível | Usa pacotes locais e ignora testes externos |
| `--offline-dir CAMINHO` | Não disponível | Usa outro diretório de dependências e ativa offline |
| `--help` | Exibe ajuda | Exibe ajuda |

Com `--check-only`, `--reboot` é ignorado. O check-only identifica o Docker principal e a presença do Compose; não valida as três versões exatas nem os bloqueios APT, e não garante que downloads ou instalações posteriores terão sucesso.

A preparação pode configurar locale `en_US.UTF-8`, timezone `America/Sao_Paulo`, desabilitar UFW, configurar Chrome com `--no-sandbox` e criar `/fhop-install/install`, `/data/fhop-data`, `/terra-install` e `/4G-install`. Atualização Ubuntu, instalação automática NVIDIA e habilitação NTP são etapas do fluxo com Internet.

## Estado de validação

A variante online passou nas verificações de sintaxe Bash, ajuda e seleção exata de versões com dados simulados. Instalação real, disponibilidade dos pacotes e upgrade/downgrade ainda precisam de teste em Ubuntu 22.04/24.04.

As [notas da release v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5) registram as validações do bundle, incluindo metadados, hashes e simulação APT do Chrome 24.04. Também recomendam instalação final em VMs mínimas antes de produção.

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

Se as três versões principais já forem as esperadas, elas são verificadas e o bloqueio é aplicado. Se o usuário recusar o ajuste de versões divergentes, a instalação atual e seus bloqueios são mantidos. Após instalar o pacote recomendado, são validadas as versões exatas do Docker Engine, Docker Compose e containerd.

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

Consulte também as mensagens de cada etapa. O campo de virtualização permanece `Nao verificada`. O relatório não representa uma certificação completa do ambiente.

---

# Sobre o projeto

Este script foi desenvolvido para auxiliar na preparação de ambientes destinados à instalação do DJI FlightHub 2 On-Premises.

Ele não substitui a documentação oficial da DJI, mas complementa o processo de instalação com validações adicionais e automações baseadas em experiências reais de implantação.
