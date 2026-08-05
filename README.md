📦 FH2 OP - Script de Preparação do Servidor (v5.3)

Este script automatiza a verificação e preparação de servidores Ubuntu para instalação do DJI FlightHub 2 On-Premises (FH2 OP).

Além de verificar se o servidor atende aos requisitos mínimos, ele também pode preparar automaticamente o ambiente para a instalação.

✅ Sistemas suportados
Ubuntu Server 22.04 LTS
Ubuntu Server 24.04 LTS

Outras versões não são suportadas pelo script.

🚀 Modos de utilização

1️⃣ Somente verificar o servidor (Recomendado)
Nenhuma alteração será feita.
Ideal para validar o ambiente antes da instalação.

sudo ./setup_fh2VER5.3.sh --check-only

Neste modo o script:

✔️ verifica todos os requisitos
✔️ gera um relatório completo
❌ não instala nada
❌ não atualiza o sistema
❌ não cria pastas
❌ não altera configurações
❌ não reinicia o servidor

2️⃣ Preparar o servidor

sudo ./setup_fh2VER5.3.sh

Além das verificações, o script prepara automaticamente o servidor.

3️⃣ Preparar e reiniciar automaticamente

sudo ./setup_fh2VER5.3.sh --reboot

Executa toda a preparação e reinicia o servidor ao finalizar.


🔎 O que o script verifica?

✔️ Sistema Operacional
Confirma se o Ubuntu é compatível.

✔️ CPU
Verifica se o processador suporta as instruções obrigatórias:

SSE4.2
POPCNT
AVX
AVX2

Sem essas instruções o FlightHub pode não funcionar corretamente.
O principal sintoma é o container tas-service permanecer Unhealthy.

✔️ Memória RAM
O script verifica a memória disponível.

Mais de 32 GB
✅ Recomendado para:
FlightHub 2
Terra (Reconstrução)


32 GB ou menos
Recomendado apenas para:
FlightHub 2

Caso o módulo Terra seja utilizado, é comum ocorrer:
- tarefas permanecendo em Pending/Pendente
- reconstruções que nunca iniciam.

✔️ Armazenamento

São realizadas duas verificações.

Espaço livre
É necessário possuir:
300 GB livres
Caso contrário a instalação pode falhar.

Capacidade do disco
O disco físico onde o Ubuntu está instalado deve possuir:
1 TB ou mais
Isso garante espaço suficiente para operação e crescimento do ambiente.

✔️ Docker

O FlightHub deve utilizar:
Docker 27

O Docker 29 não é suportado.
Durante instalações práticas foi observado que o Docker 29 pode causar erros fatais no frontend do FlightHub.

✔️ GPU NVIDIA

Caso exista uma GPU NVIDIA instalada, o script verifica se o driver está corretamente instalado.
Na preparação completa, instala automaticamente o driver recomendado quando necessário. 

No modo --check-only, apenas informa o status.

✔️ Internet

Confirma acesso à Internet.

✔️ DNS

Confirma resolução de nomes.

✔️ Sincronização de horário

Verifica o status do NTP.
Na preparação completa o NTP é habilitado automaticamente.

✔️ Firewall

Verifica o UFW.
Na preparação completa o firewall é desabilitado automaticamente.

📁 Estrutura de diretórios criada

Durante a preparação serão criados:

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

🛠️ O que o script altera (modo normal)

Quando executado sem --check-only, o script pode:

atualizar o Ubuntu;
corrigir dependências quebradas do APT;
instalar utilitários necessários;
instalar ou substituir o Docker pela versão recomendada (27);
instalar o Google Chrome configurado para uso como root (--no-sandbox);
instalar o driver NVIDIA recomendado;
configurar locale para en_US.UTF-8;
configurar o fuso horário para America/Sao_Paulo;
habilitar a sincronização NTP;
desabilitar o firewall UFW;
criar a estrutura de diretórios utilizada pelo FlightHub 2.

📊 Relatório Final

Ao término da execução é exibido um resumo contendo:

modo de execução;
Ubuntu;
CPU;
compatibilidade da CPU;
memória RAM;
armazenamento;
GPU NVIDIA;
driver NVIDIA;
Internet;
DNS;
Firewall;
Docker;
Google Chrome;
status da criação dos diretórios.

💡 Recomendação

Antes de qualquer instalação do FlightHub 2 On-Premises, execute primeiro:

sudo ./setup_fh2VER5.3.sh --check-only

Após corrigir todos os itens apontados pelo relatório, execute:

sudo ./setup_fh2VER5.3.sh

Dessa forma, o ambiente será preparado seguindo os requisitos esperados para o FlightHub 2 On-Premises.
