# MCP - BashNiri

Este projeto usa MCP (Model Context Protocol) para interação com o OpenCode.

## Servidores MCP Habilitados

| Servidor | Descrição | Status |
|----------|-----------|--------|
| **filesystem** | Acesso a arquivos do projeto | ✓ Ativo |
| **git | Operações git (diff, status, commit) | ✓ Ativo |
| **memory** | Memória conversacional | ✗ Desabilitado |

## Raiz do Projeto

O servidor filesystem usa `.` como raiz - isso significa que todo o projeto (exceto `.git`) está acessível.

## Por que memory está desabilitado?

Memória conversacional pode consumir recursos desnecessários em operações rápidas de build/debug. Habilite manualmente se necessário:

```json
"memory": {
  "enabled": true
}
```

## Comandos Úteis no OpenCode

- Ler arquivos: `read Containerfile`
- Ver status: `git status`
- Ver diff: `git diff`
- Listar arquivos: `glob **/*.sh`
