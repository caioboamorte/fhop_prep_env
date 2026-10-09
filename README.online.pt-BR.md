# FH2 OP Prep Tool v5.5 Online

Variante para Ubuntu 22.04 e 24.04 amd64 com Internet. Basta o arquivo .sh: não requer docker.tar.gz nem bundles locais.

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

## Validação

Sintaxe bash, --help e seleção exata de versões com dados simulados foram validados. Instalação real, disponibilidade dos pacotes e cenários de upgrade/downgrade ainda precisam de teste em Ubuntu 22.04/24.04. Esta variante está em branch de revisão, sem substituir a versão offline.
