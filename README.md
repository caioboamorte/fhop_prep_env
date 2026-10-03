# FlightHub 2 On-Premises Environment Preparation Tool

Validation and preparation of Ubuntu environments for **DJI FlightHub 2 On-Premises (FH2 OP)**.

## Documentation / Documentação

- [Português](README.pt-BR.md)
- [English](README.en.md)

## Latest release / Versão mais recente

**[v5.4.1](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.4.1)**, published on / publicada em **2026-09-25**.

[Download / Baixar: fh2-onprem-prep-tool-v5.4.1.tar.gz](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.4.1/fh2-onprem-prep-tool-v5.4.1.tar.gz)

### Português

As notas da **v5.4.1** descrevem a instalação e validação do `iptables`, a verificação do estado dos pacotes do Docker e a inicialização das variáveis de versão. A **v5.4** introduziu a proteção dos pacotes Docker antes da atualização do Ubuntu e moveu a verificação do Chrome para antes do resumo final.

**Código atualizado na `main`:** o arquivo `fh2-onprem-prep-tool.sh` já contém as correções de `iptables`, a validação do estado dos pacotes e a inicialização das variáveis de versão descritas na v5.4.1. O arquivo disponível na tag `v5.4.1` permanece na versão anterior e não inclui essas correções. A tag e o pacote anexado à release não foram alterados; o conteúdo desse pacote não foi validado nesta revisão.

### English

The **v5.4.1** release notes describe `iptables` installation and validation, Docker package-state checks, and version-variable initialization. **v5.4** introduced Docker package protection before Ubuntu updates and moved the Chrome check before the final report.

**Updated source on `main`:** `fh2-onprem-prep-tool.sh` now includes the `iptables` fixes, package-state validation, and version-variable initialization described in v5.4.1. The file at tag `v5.4.1` remains at the earlier version and does not include these fixes. The tag and release attachment were not modified; the archive contents were not validated during this review.

[All releases / Todas as releases](https://github.com/caioboamorte/fhop_prep_env/releases)
