# FlightHub 2 On-Premises Environment Preparation Tool

Prepare Ubuntu 22.04/24.04 for DJI FlightHub 2 On-Premises.

## Documentação / Documentation

- [Português: comparação, download e execução](README.pt-BR.md)
- [English: comparison, download and execution](README.en.md)

## Duas versões / Two variants

| Versão / Variant | Quando usar / When to use | Distribuição / Distribution |
| --- | --- | --- |
| **v5.5 Online** | Servidor com Internet; baixa todos os componentes, inclusive Docker / Connected server; downloads all components, including Docker | [Script na branch / Branch script](fh2-onprem-prep-tool-v5.5-online.sh), em revisão / under review |
| **v5.5 com bundle / bundle** | Servidor sem Internet; execute com `--offline` / Offline server; run with `--offline` | [Release v5.5](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5) |

**Online:** basta o arquivo `.sh`; não precisa de `docker.tar.gz`. / Only the `.sh` is needed; no `docker.tar.gz`.

**Bundle:** transfira o [anexo completo da release](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz), extraia e mantenha script, `docker.tar.gz`, `SHA256SUMS` e `packages/` juntos. / Transfer and extract the [full release attachment](https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5/fh2-v5.5-bundle.tar.gz), keeping its contents together.

A versão com bundle também permite usar Internet sem `--offline`, mas continua exigindo o Docker local. / The bundle script also supports Internet-enabled preparation without `--offline`, but still requires local Docker files.

As duas mantêm Docker **27.2.0**, Compose **2.29.2** e containerd **1.7.21**. / Both target those same component versions.

## v5.5 Online: download e execução / download and run

```bash
curl -fL --retry 3 \
  "https://raw.githubusercontent.com/caioboamorte/fhop_prep_env/v5.5-online/fh2-onprem-prep-tool-v5.5-online.sh" \
  -o fh2-onprem-prep-tool-v5.5-online.sh

sudo bash fh2-onprem-prep-tool-v5.5-online.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5-online.sh
```

Execute primeiro `--check-only` e confira o relatório. / Run `--check-only` first and review the report.

A variante online ainda não está em release; instalação real está pendente de validação. Acompanhe o [PR #1](https://github.com/caioboamorte/fhop_prep_env/pull/1). / Online has no release yet; real installation testing is pending. Track [PR #1](https://github.com/caioboamorte/fhop_prep_env/pull/1).

Para o passo a passo offline, opções, integridade e requisitos, consulte a documentação acima. / See the guides above for offline steps, options, integrity checks and requirements.
