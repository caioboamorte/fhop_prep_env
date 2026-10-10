# FH2 OP Prep Tool v5.5 Online

Variante para Ubuntu 22.04 e 24.04 amd64 com Internet. Basta o arquivo .sh: não requer docker.tar.gz nem bundles locais.

## Quando usar e como baixar

Use em servidores com acesso aos repositórios Ubuntu, Docker e Google. Para servidores sem Internet, use a versão com bundle e `--offline`.

Consulte o [guia completo em português](README.pt-BR.md) ou o [guia em inglês](README.en.md) para comparar as duas versões, baixar o bundle e usar as opções disponíveis.

```bash
curl -fL --retry 3 \
  "https://github.com/caioboamorte/fhop_prep_env/releases/download/v5.5-online/fh2-onprem-prep-tool-v5.5-online.sh" \
  -o fh2-onprem-prep-tool-v5.5-online.sh

sudo bash fh2-onprem-prep-tool-v5.5-online.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5-online.sh
```

## Execução

```bash
sudo bash fh2-onprem-prep-tool-v5.5-online.sh --check-only
sudo bash fh2-onprem-prep-tool-v5.5-online.sh
```

Opcional: `--reboot` reinicia ao final.

## Instalação

Baixa dependências Ubuntu, driver NVIDIA recomendado quando necessário e Chrome. Configura o repositório oficial Docker com chave de assinatura APT e seleciona Docker Engine/CLI 27.2.0, Compose 2.29.2, containerd 1.7.21 e Buildx 0.16.2. Não usa latest se uma versão estiver indisponível. Os cinco pacotes Docker são baixados antes de remover pacotes conflitantes. Dependências adicionais são resolvidas pela Internet durante a instalação.

Docker existente é protegido durante apt upgrade. Se as três versões principais já estiverem corretas, são mantidas e seus pacotes recebem apt-mark hold. Caso contrário, solicita confirmação antes de instalar as versões fixadas, inclusive downgrade. Isso pode interromper containers. Não remove /var/lib/docker. Falhas de remoção ou instalação tentam restaurar os holds anteriores dos pacotes ainda instalados.

Mantém a preparação da versão base: verificações de hardware, atualização Ubuntu, locale, timezone, NTP, desativação UFW, criação das pastas e configuração Chrome com --no-sandbox. Não instala o FlightHub 2 nem o Terra.

## Sequência da etapa Docker

1. Antes de atualizar o Ubuntu, detecta os pacotes instalados e aplica bloqueios preventivos.
2. Na etapa Docker, lê as três versões principais e compara com o conjunto esperado.
3. Se já estiverem corretas, mantém os componentes e aplica/confirma os bloqueios. Caso contrário, pede confirmação quando há uma instalação detectada.
4. Após decidir instalar, procura as versões exatas e baixa os cinco pacotes, ainda com os bloqueios existentes.
5. Libera os bloqueios, remove conflitos, instala os pacotes e inicia o Docker.
6. Valida os pacotes e as versões de Engine, Compose e containerd, aplica o bloqueio final e confirma os holds.

O bloqueio preventivo protege o Docker existente; não comprova que suas versões estão corretas. Com `--check-only`, nenhuma dessas alterações ocorre.

Veja a [tabela detalhada das duas versões](README.pt-BR.md#em-que-momento-o-docker-é-detectado-baixado-instalado-e-bloqueado).

## Validação

**Pronta para uso.** Caio confirmou a revisão e os testes do script em 09/10/2026. Também foram aprovadas anteriormente as verificações de sintaxe Bash, `--help` e seleção exata de versões com dados simulados.

Integrada à `main` e disponível na [release v5.5 Online](https://github.com/caioboamorte/fhop_prep_env/releases/tag/v5.5-online), com anexos `.sh` e `.sha256`. A versão com bundle continua disponível para uso offline.
