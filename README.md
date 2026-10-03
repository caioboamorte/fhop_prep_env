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

**Pacote da release conferido:** o arquivo `fh2-onprem-prep-tool-v5.4.1.tar.gz` contém o script com as correções da 5.4.1, idêntico ao disponível na `main`. A extração cria a pasta `fh2-onprem-prep-tool`, com o script e o `docker.tar.gz` juntos. Essa conferência abrangeu o conteúdo do script e sua sintaxe Bash, sem executar a instalação.

**Sobre a tag:** o código-fonte associado à tag `v5.4.1` ainda contém o script anterior. Para instalar a versão corrigida, utilize o pacote anexado à release indicado acima; os arquivos automáticos `Source code (zip)` e `Source code (tar.gz)` refletem o código da tag.

### English

The **v5.4.1** release notes describe `iptables` installation and validation, Docker package-state checks, and version-variable initialization. **v5.4** introduced Docker package protection before Ubuntu updates and moved the Chrome check before the final report.

**Release archive checked:** `fh2-onprem-prep-tool-v5.4.1.tar.gz` contains the script with the v5.4.1 fixes, identical to the one on `main`. Extraction creates the `fh2-onprem-prep-tool` directory with the script and `docker.tar.gz` together. This review checked the script contents and Bash syntax without running the installation.

**About the tag:** the source associated with tag `v5.4.1` still contains the earlier script. To install the corrected version, use the release attachment linked above; the automatic `Source code (zip)` and `Source code (tar.gz)` archives reflect the tagged source.

[All releases / Todas as releases](https://github.com/caioboamorte/fhop_prep_env/releases)
