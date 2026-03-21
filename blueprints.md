# Blueprints - Bashiniri Niri + DMS Variant

> **Ultima atualizacao:** 2026-03-20
> **Autor:** OpenCode
> **Status:** Blueprint amadurecido para implementacao

---

## 1. Resumo da Distro/ISO Atual

### 1.1 Proposito do Repositorio

Este repositorio e um **template bootc da Universal Blue** para criacao de imagens de sistema operacional container-based e bootable. O template atual deriva da imagem **Bazzite**.

### 1.2 Stack Tecnologica

| Componente | Tecnologia | Versao/Origem |
|------------|------------|---------------|
| **Base Image** | Bazzite | `ghcr.io/ublue-os/bazzite:stable` |
| **Container Build** | Podman/Buildah | CI GitHub Actions |
| **Image Format** | OCI Container + bootc | Registro GHCR |
| **Disk Builder** | bootc-image-builder | `quay.io/centos-bootc/bootc-image-builder` |
| **Installer** | Anaconda/Kickstart | via `disk_config/*.toml` |
| **Sessao atual** | GNOME (na imagem base) | nao versionada neste repo |

### 1.3 Pipeline de Build

```text
Containerfile
  -> podman build
    -> imagem OCI no GHCR
      -> bootc-image-builder
        -> qcow2 / raw / iso
```

---

## 2. Estrutura de Modulos do Repositorio

```text
bashiniri/
  Containerfile
  Justfile
  README.md
  build_files/
    build.sh
  disk_config/
    disk.toml
    iso-gnome.toml
    iso-kde.toml
  .github/workflows/
    build.yml
    build-disk.yml
  artifacthub-repo.yml
  cosign.pub
```

### 2.1 Mapa de Responsabilidades

| Arquivo | Responsabilidade | Relevancia para Niri + DMS |
|---------|------------------|----------------------------|
| `Containerfile` | define base image e passo de customizacao | muito alta |
| `build_files/build.sh` | instala pacotes e habilita servicos | muito alta |
| `disk_config/*.toml` | configuracao de instalador/imagens | muito alta |
| `.github/workflows/build-disk.yml` | build de ISO/disk images | alta |
| `Justfile` | builds locais e execucao em VM | alta |
| `README.md` | documentacao operacional | media |

---

## 3. Hotspots e Problemas Atuais

### 3.1 Kickstart com referencia incorreta

`disk_config/iso-gnome.toml` e `disk_config/iso-kde.toml` usam:

```toml
bootc switch --mutate-in-place --transport registry ghcr.io/ublue-os/image-template:latest
```

Isso aponta para a imagem template e nao para a imagem real do projeto.

### 3.2 Referencia a `disk_config/iso.toml` sem arquivo correspondente

Hoje existe um desalinhamento entre:

- `README.md`
- `Justfile`
- `.github/workflows/build-disk.yml`

Todos apontam para `disk_config/iso.toml`, mas no repo so existem `disk_config/iso-gnome.toml` e `disk_config/iso-kde.toml`.

### 3.3 Ausencia de area de overlay declarativa

O repo ainda nao tem um diretorio para versionar arquivos como:

- `wayland-sessions/*.desktop`
- `greetd/config.toml`
- `systemd --user` wants
- `/etc/skel/.config/niri/*`

Para uma variante Niri + DMS, isso passa a ser necessario.

---

## 4. Arquitetura-alvo: Niri + DMS

### 4.1 Decisao de produto

A variante desejada nao deve ser apenas "trocar GNOME por Niri". O alvo correto e:

- **Niri** como compositor principal
- **DMS (DankMaterialShell)** como shell oficial
- **greetd + dms-greeter** como fluxo de login, depois que a sessao estiver estavel
- **Bazzite** como base operacional no curto prazo

Ou seja: a experiencia passa a ser **Niri-first** e nao mais GNOME-first.

### 4.2 Pilha alvo

```text
bootc image (Bazzite base)
  -> Niri session
    -> systemd --user
      -> DMS service
        -> shell UI, notifications, launcher, lock, control center
  -> optional: greetd + dms-greeter
```

### 4.3 Papel de cada camada

| Camada | Componente | Papel |
|--------|------------|-------|
| **Base** | `ghcr.io/ublue-os/bazzite:stable` | hardware enablement, drivers, codecs, base Atomic |
| **Compositor** | `niri` | tiling scrollable, outputs, workspaces, keybind base |
| **Shell** | `dms` + `quickshell` | painel, launcher, notificacoes, overlays, lock, UX do desktop |
| **Login** | `greetd` + `dms-greeter` | greeter Wayland coerente com a shell |
| **Integracoes** | `dgop`, `matugen`, `cliphist`, `wl-clipboard`, `danksearch` | telemetria, tema, clipboard e busca |
| **Sessao** | `systemd --user` + `niri.service` | autostart deterministico do DMS apenas no Niri |

### 4.4 Implicacao pratica

Com DMS, a stack principal **nao** deve ser `waybar` + `mako` + `wofi` + `swaylock`. O proprio DMS cobre esses papeis. Esses pacotes so sao uteis como fallback temporario durante bring-up.

---

## 5. Estrategia Recomendada

### 5.1 Base inicial

**Recomendacao:** manter Bazzite na primeira iteracao.

```Dockerfile
FROM ghcr.io/ublue-os/bazzite:stable
```

Motivos:

- preserva compatibilidade com o ecossistema Universal Blue
- reduz risco com NVIDIA, firmware, codecs e akmods
- acelera a validacao de Niri + DMS sem reconstruir a base inteira

### 5.2 Abordagem de migracao

**Recomendacao:** abordagem aditiva primeiro, subtractive depois.

Sequencia sugerida:

1. adicionar Niri + DMS
2. subir a sessao Niri corretamente
3. mover o login para greetd/dms-greeter
4. apenas depois avaliar remocao de residuos GNOME

Isso evita quebrar login, boot grafico e dependencias da base.

### 5.3 Fonte de pacotes

Ja confirmado por documentacao externa:

- DMS possui COPR para Fedora/CentOS: `avengemedia/dms`
- ha repositorio complementar com utilitarios: `avengemedia/danklinux`
- DMS documenta integracao nativa com `niri.service`
- DMS tambem possui pacote `dms-greeter` para `greetd`

Ainda precisa ser validado no contexto desta imagem:

- origem do pacote `niri` para a base exata usada aqui
- necessidade de wrappers adicionais de sessao

---

## 6. Componentes Tecnicos da Variante

### 6.1 Obrigatorios

```bash
niri
dms
quickshell
accountsservice
```

### 6.2 Recomendados

```bash
greetd
dms-greeter
dgop
matugen
cliphist
wl-clipboard
danksearch
qt6-qtmultimedia
NetworkManager
```

### 6.3 Fallback temporario apenas se necessario

```bash
waybar
mako
wofi
swaylock
swayidle
```

### 6.4 Autostart correto do DMS

O DMS recomenda, para Niri, acoplamento via `systemd --user` em `niri.service`. Para uma imagem de sistema, o ideal e entregar isso de forma declarativa, por exemplo:

```text
/usr/lib/systemd/user/niri.service.wants/dms.service -> ../dms.service
```

Isso e melhor do que depender de configuracao manual por usuario.

### 6.5 Configuracao base de Niri

O DMS ja documenta includes de Niri para:

- cores
- layout
- alt-tab
- binds

Portanto, a distro deve versionar um `config.kdl` base em `/etc/skel/.config/niri/` e nao exigir setup manual.

---

## 7. Impacto no Repositorio

### 7.1 Arquivos existentes que certamente mudam

| Prioridade | Arquivo | O que deve mudar |
|------------|---------|-------------------|
| **ALTA** | `build_files/build.sh` | habilitar repos, instalar Niri/DMS/greetd, ajustar servicos |
| **ALTA** | `Containerfile` | copiar overlays/configs alem do script de build |
| **ALTA** | `Justfile` | corrigir `iso.toml` ausente e suportar ISO Niri |
| **ALTA** | `.github/workflows/build-disk.yml` | corrigir caminho de ISO e adicionar perfil Niri |
| **ALTA** | `disk_config/iso-gnome.toml` | corrigir imagem do kickstart |
| **ALTA** | `disk_config/iso-kde.toml` | corrigir imagem do kickstart |
| **MEDIA** | `README.md` | documentar arquitetura Niri + DMS |

### 7.2 Arquivos novos recomendados

Estrutura sugerida:

```text
config_files/
  usr/share/wayland-sessions/niri.desktop
  etc/greetd/config.toml
  usr/lib/systemd/user/niri.service.wants/dms.service
  etc/skel/.config/niri/config.kdl
  etc/skel/.config/environment.d/90-dms.conf
```

Essa estrutura cobre sessao, greeter, autostart e config inicial do usuario.

---

## 8. Plano de Implementacao em Fases

### Fase 0 - Sanear o template

- corrigir referencia a `disk_config/iso.toml`
- definir estrategia canonica de ISO (`iso-niri.toml` e/ou alias `iso.toml`)
- corrigir `bootc switch` nos TOMLs atuais

**Entregavel:** template coerente e buildavel antes da migracao de desktop.

### Fase 1 - Sessao Niri funcional

- instalar `niri`
- criar `niri.desktop` em `/usr/share/wayland-sessions/`
- validar login em Niri sem depender de DMS
- confirmar comportamento de `niri.service`

**Entregavel:** sessao Niri sobe de forma confiavel.

### Fase 2 - Shell DMS

- habilitar COPRs necessarios
- instalar `dms`, `quickshell`, `accountsservice` e integracoes
- ligar `dms.service` ao `niri.service`
- versionar configuracao base de Niri em `/etc/skel/.config/niri/`

**Entregavel:** Niri inicia com DMS como shell principal.

### Fase 3 - Greeter

- instalar `greetd` e `dms-greeter`
- versionar `/etc/greetd/config.toml`
- desabilitar `gdm` so depois da sessao estar estavel
- validar login/logout/reboot em VM

**Entregavel:** fluxo completo login -> shell -> logout.

### Fase 4 - ISO e CI/CD

- criar `disk_config/iso-niri.toml`
- ajustar `Justfile` para build explicito da ISO Niri
- ajustar `build-disk.yml` para gerar a variante correta
- validar artefato em VM

**Entregavel:** ISO instalavel da variante Niri + DMS.

### Fase 5 - Polimento

- revisar branding, wallpapers e defaults
- remover redundancias com GNOME se necessario
- documentar fallback/recovery path
- atualizar README e metadados

**Entregavel:** release reproduzivel e documentada.

---

## 9. Gaps, Riscos e Decisoes em Aberto

### 9.1 Gaps confirmados

| Gap | Impacto | Acao recomendada |
|-----|---------|------------------|
| **Origem do pacote `niri` nao validada para esta base** | bloqueia implementacao limpa | validar repo oficial/COPR/build from source |
| **Nao existe area de overlay no repo** | impede versionar sessao/greeter/skel | criar `config_files/` |
| **`niri.service` nao foi testado aqui** | afeta autostart do DMS | validar em build funcional antes do greeter |
| **ISO atual esta inconsistente** | bloqueia trilha de instalador | corrigir plumbing antes da migracao |

### 9.2 Riscos principais

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|---------------|---------|-----------|
| `niri` nao estar empacotado para a base alvo | **MEDIA** | **ALTO** | tratar Niri como spike tecnico inicial |
| `dms-greeter` causar efeitos colaterais indesejados via scriptlets | **MEDIA** | **MEDIO** | preferir config declarativa versionada |
| conflitos com GDM/GNOME residual | **MEDIA** | **MEDIO** | migracao em duas etapas, sem remocao agressiva |
| DMS subir duas vezes | **ALTA** | **MEDIO** | usar apenas strategy de systemd ou apenas compositor, nao ambos |
| quebra no login grafico | **MEDIA** | **ALTO** | adiar greetd ate a sessao Niri + DMS estabilizar |

### 9.3 Decisoes recomendadas agora

1. **Base:** manter Bazzite na v1
2. **Shell oficial:** DMS
3. **Autostart:** `systemd --user` ligado a `niri.service`
4. **Greeter:** `greetd + dms-greeter` apenas depois da sessao funcional
5. **Layout do repo:** introduzir `config_files/`

---

## 10. Primeira Fatia de Execucao Recomendada

### Sprint 1

1. corrigir `iso.toml` ausente e referencias circulares
2. criar `config_files/` e ensinar o `Containerfile` a copiar overlays
3. instalar `niri` e validar sessao minima
4. validar `niri.service`

### Sprint 2

5. integrar `dms`, `quickshell`, `accountsservice`, `dgop`, `matugen`, `cliphist`, `wl-clipboard`
6. versionar `config.kdl` base do Niri e autostart declarativo do DMS
7. testar em VM e via `bootc switch`

### Sprint 3

8. integrar `greetd` + `dms-greeter`
9. criar `disk_config/iso-niri.toml`
10. ajustar workflow e documentacao

---

## 11. Referencias

- [Niri GitHub](https://github.com/YaLTeR/niri)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [DMS Installation Docs](https://danklinux.com/docs/dankmaterialshell/installation)
- [DMS Compositor Setup Docs](https://danklinux.com/docs/dankmaterialshell/compositors)
- [DankGreeter Installation Docs](https://danklinux.com/docs/dankgreeter/installation)
- [Universal Blue Docs](https://universal-blue.org/)
- [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)

---

## Resumo Executivo

| Item | Detalhe |
|------|---------|
| **Direcao correta** | Niri como compositor + DMS como shell principal |
| **Base recomendada** | manter Bazzite na primeira iteracao |
| **Mudanca mais importante** | introduzir overlays declarativos de sessao, systemd user e greetd |
| **Bloqueador atual** | repo de ISO inconsistente e pacote `niri` ainda nao validado |
| **Esforco estimado** | 3 sprints curtas para primeira ISO funcional |

---

*Atualizar este documento conforme os spikes tecnicos confirmarem a origem do pacote `niri` e o comportamento do `niri.service` na imagem final.*
