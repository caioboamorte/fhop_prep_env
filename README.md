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

**Atenção à origem do script:** o arquivo `fh2-onprem-prep-tool.sh` disponível na `main` e na tag `v5.4.1` ainda não contém as correções de `iptables` descritas nessa release. Para obter a distribuição publicada, utilize o arquivo anexado à release acima. O conteúdo desse pacote não foi validado nesta revisão da documentação.

### English

The **v5.4.1** release notes describe `iptables` installation and validation, Docker package-state checks, and version-variable initialization. **v5.4** introduced Docker package protection before Ubuntu updates and moved the Chrome check before the final report.

**Script source matters:** `fh2-onprem-prep-tool.sh` on `main` and at tag `v5.4.1` does not yet contain the `iptables` fixes described in that release. Use the release attachment above to obtain the published distribution. The archive contents were not validated during this documentation review.

[All releases / Todas as releases](https://github.com/caioboamorte/fhop_prep_env/releases)
