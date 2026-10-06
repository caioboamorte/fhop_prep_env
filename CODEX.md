# Codex Instructions

Antes de trabalhar neste repositorio, leia integralmente `PROJECT_CONTEXT.md`.

## Regras

1. A v5.4.1 e a versao estavel anterior. Nao modifica-la sem autorizacao explicita.
2. A versao em desenvolvimento e a v5.5.
3. Nao apagar, mover ou renomear arquivos sem autorizacao.
4. Nao remover ou substituir pacotes `.deb` sem apresentar antes a justificativa e o impacto.
5. Nao fazer commit, push, release ou alterar tags sem autorizacao explicita.
6. Antes de aplicar uma alteracao:
   - explicar o problema encontrado;
   - mostrar a solucao proposta;
   - listar os arquivos que serao modificados;
   - aguardar autorizacao.
7. Preservar compatibilidade com Ubuntu 22.04 e Ubuntu 24.04.
8. O modo offline deve funcionar sem acesso a Internet para dependencias base, Docker e Chrome.
9. Nao implementar instalacao generica de driver NVIDIA offline sem autorizacao e estrategia especifica para GPU/kernel.
10. Durante auditorias, fazer primeiro apenas leitura. Nao limpar automaticamente arquivos auxiliares ou duplicados.
11. Priorizar comportamento ja validado em testes reais. Nao refatorar apenas por preferencia de estilo.
12. Se o estado real dos arquivos divergir de `PROJECT_CONTEXT.md`, relatar a divergencia antes de altera-la.

## Auditoria recomendada

Ao analisar o bundle local:

- mostrar a arvore relevante;
- medir o tamanho dos diretorios;
- conferir os bundles Ubuntu 22.04 e 24.04;
- verificar se os caminhos correspondem ao que a v5.5 espera;
- identificar arquivos auxiliares;
- identificar duplicatas por hash, nao apenas por nome;
- verificar nomes, arquiteturas e versoes dos pacotes .deb;
- apontar dependencias potencialmente ausentes;
- nao alterar nada ate receber aprovacao.
