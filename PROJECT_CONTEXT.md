# FlightHub 2 On-Premises Pre-Check - Project Context

## Objetivo

Este repositorio contem a ferramenta de preparacao e pre-check do ambiente para FlightHub 2 On-Premises.

A versao estavel anterior e a v5.4.1. A versao em desenvolvimento e a v5.5, que adiciona suporte a preparacao offline por bundles locais para Ubuntu 22.04 e Ubuntu 24.04.

## Regra de compatibilidade

- Nao modificar a v5.4.1 durante o desenvolvimento da v5.5.
- Preservar suporte aos fluxos existentes da ferramenta.
- O modo offline nao pode depender de acesso a Internet para instalar dependencias base, Docker ou Google Chrome.

## v5.5 - Smart Offline Bundle

Script em desenvolvimento:

`fh2-onprem-prep-tool-v5.5.sh`

Flags:

- `--offline`
- `--offline-dir <caminho>`

Quando `--offline-dir` nao e informado, o script seleciona automaticamente:

`packages/ubuntu-$VERSION_ID`

Estrutura esperada:

```text
fh2-onprem-prep-tool-v5.5/
├── fh2-onprem-prep-tool-v5.5.sh
├── docker.tar.gz
└── packages/
    ├── ubuntu-22.04/
    │   ├── base/
    │   ├── chrome/
    │   └── nvidia/
    └── ubuntu-24.04/
        ├── base/
        ├── chrome/
        └── nvidia/
```

## Comportamento offline

No modo offline:

- nao executar o fluxo normal de `apt update`, `apt upgrade`, `apt autoremove` ou `apt autoclean`;
- nao executar testes externos de Internet e DNS;
- nao habilitar NTP externo automaticamente;
- instalar dependencias por repositorio APT local temporario;
- manter os repositorios externos fora da resolucao APT usada pelo bundle;
- instalar apenas os pacotes explicitamente ausentes e suas dependencias;
- instalar Docker pelo `docker.tar.gz`;
- instalar Chrome pelo bundle local de Chrome.

O repositorio APT local gera `Packages` e `Packages.gz`. Em alguns testes o APT exibiu `Method gave a blank filename` antes de conseguir ler o indice. Essa mensagem foi ruidosa, mas nao impediu a instalacao offline.

## Dependencias base

Pacotes requeridos:

```text
pciutils
ubuntu-drivers-common
curl
ca-certificates
iputils-ping
iptables
locales
```

A logica deve calcular quais desses pacotes estao ausentes e solicitar ao repositorio local somente os alvos necessarios.

## Docker homologado

Versoes esperadas:

- Docker Engine: 27.2.0
- Docker Compose plugin: 2.29.2
- containerd: 1.7.21

Pacotes bloqueados com `apt-mark hold`:

```text
containerd.io
docker-ce
docker-ce-cli
docker-buildx-plugin
docker-compose-plugin
```

A verificacao de hold deve aceitar pacotes em estado `hold ok installed`, ser idempotente e validar novamente `apt-mark showhold` depois da operacao.

Se Docker, Compose e containerd ja estiverem exatamente nas versoes homologadas, o script nao deve reinstala-los.

## Google Chrome

O Chrome deve ser instalado pelo repositorio APT local do diretorio `chrome/`, permitindo que suas dependencias sejam resolvidas exclusivamente pelo bundle.

Versao validada nos testes atuais:

`Google Chrome 155.0.8059.39`

## NVIDIA

A instalacao generica de driver NVIDIA em modo offline esta deliberadamente desabilitada nesta revisao.

Motivo: um bundle generico de driver pode ser incompativel com a combinacao GPU/kernel do cliente.

Se uma GPU NVIDIA for detectada e o driver nao estiver funcional, a ferramenta deve falhar de forma segura e orientar o uso de um bundle/driver compativel. Nao implementar instalacao generica de NVIDIA sem uma estrategia explicitamente aprovada.

## Validacao Ubuntu 22.04

Bundle base validado:

- 134 pacotes esperados;
- 134 pacotes .deb presentes;
- zero pacotes ausentes;
- aproximadamente 45 MB.

Bundle Chrome validado:

- 196 dependencias esperadas;
- 197 pacotes .deb unicos no total, incluindo o Chrome;
- zero dependencias ausentes;
- Chrome 155.0.8059.39-1 amd64;
- aproximadamente 229 MB.

Teste em instalacao limpa:

- Ubuntu 22.04 detectado corretamente;
- `ubuntu-drivers-common` e dependencia instalados pelo APT local;
- APT informou `Need to get 0 B`;
- Docker 27.2.0, Compose 2.29.2 e containerd 1.7.21 instalados;
- cinco pacotes Docker colocados em hold;
- Chrome e dependencias instalados pelo APT local;
- APT informou `Need to get 0 B/146 MB`;
- segunda execucao validou idempotencia;
- Docker nao foi reinstalado;
- hold permaneceu ativo em cinco pacotes;
- Chrome instalado foi detectado e ignorado.

## Validacao Ubuntu 24.04

A v5.5 foi testada em Ubuntu 24.04 com:

- selecao automatica de `packages/ubuntu-24.04`;
- dependencias base via APT local;
- Docker 27.2.0;
- Compose 2.29.2;
- containerd 1.7.21;
- hold dos cinco pacotes Docker;
- Chrome 155.0.8059.39;
- segunda execucao idempotente.

Antes do release final, revisar especificamente se o bundle base de Ubuntu 24.04 contem `locales` e toda a sua cadeia necessaria. Os primeiros bundles 24.04 foram gerados antes de `locales` entrar explicitamente na lista base, e o ambiente de teste ja possuia esse pacote.

## Estado atual

Base + Docker + Chrome estao funcionalmente validados em Ubuntu 22.04 e Ubuntu 24.04.

Pendencias antes de considerar o pacote final:

1. auditar a estrutura completa do bundle;
2. validar `locales` no bundle base do Ubuntu 24.04;
3. identificar arquivos auxiliares de geracao/validacao que nao precisam entrar no release;
4. identificar .deb duplicados ou desnecessarios sem remove-los automaticamente;
5. manter NVIDIA offline como limitacao conhecida ate existir estrategia especifica;
6. gerar o pacote final somente depois da auditoria e aprovacao.

## Auditoria do bundle

Arquivos como os abaixo podem existir por terem sido usados na geracao/validacao:

```text
packages.txt
downloaded.txt
chrome-direct-deps.txt
chrome-all-deps.txt
chrome-downloaded.txt
```

Eles devem ser classificados como auxiliares. Nao remover automaticamente. Primeiro apresentar o impacto e aguardar aprovacao.

## Principio para alteracoes

O objetivo e previsibilidade em ambientes de clientes. Nao trocar uma implementacao validada por uma alternativa apenas por ser mais elegante. Toda mudanca deve ter motivo tecnico claro e preservar os testes ja aprovados.
