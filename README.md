# FlightHub 2 On-Premises Environment Preparation Tool

Validation and preparation of Ubuntu environments for **DJI FlightHub 2 On-Premises (FH2 OP)**.

## Documentation / Documentação

- [Português](README.pt-BR.md)
- [English](README.en.md)

## Latest release / Versão mais recente

**[v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5)**, published on / publicada em **2026-10-06**.

[Download / Baixar: fh2-v5.5-bundle.tar.gz](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz)

[SHA-256](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz.sha256): `1a762907e488985dd6d0b2f2f8b3deff6bd800a335c41f70c9ffb230c3b11981`

### Português

A **v5.5** adiciona preparação offline por bundles locais para Ubuntu 22.04 e 24.04. Dependências base, Docker 27.2.0, Docker Compose 2.29.2, containerd 1.7.21 e Google Chrome 155.0.8059.39 são fornecidos no pacote da release.

O modo offline isola listas e cache do APT, valida o manifesto `SHA256SUMS`, não executa testes externos de Internet/DNS e não habilita NTP externo. A instalação automática genérica de driver NVIDIA permanece desabilitada no modo offline por depender da combinação GPU/kernel do cliente.

O bundle foi auditado por hash, passou na verificação de sintaxe Bash e teve o Chrome 24.04 validado por resolução estática e simulação APT exclusivamente local. Recomenda-se ainda uma instalação final em VMs mínimas antes da implantação em produção.

### English

**v5.5** adds offline preparation from local bundles for Ubuntu 22.04 and 24.04. Base dependencies, Docker 27.2.0, Docker Compose 2.29.2, containerd 1.7.21, and Google Chrome 155.0.8059.39 are included in the release package.

Offline mode isolates APT lists and cache, verifies the `SHA256SUMS` manifest, skips external Internet/DNS tests, and does not enable external NTP. Generic automatic NVIDIA driver installation remains disabled in offline mode because it depends on the customer's GPU/kernel combination.

The bundle was audited by hash, passed Bash syntax validation, and the Ubuntu 24.04 Chrome bundle passed static dependency resolution and an APT simulation using only the local repository. A final installation on minimal VMs is still recommended before production deployment.

[All releases / Todas as releases](https://github.com/caioboamorte/fhop_prep_env/releases)
