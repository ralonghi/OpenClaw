# OpenClaw (Docker no Windows)

Template de Compose para subir o [OpenClaw](https://docs.openclaw.ai/install/docker) num container Linux e acessá-lo pela máquina host.

Não é uma imagem própria. Usamos a imagem oficial `ghcr.io/openclaw/openclaw:latest`. O valor deste repositório é o jeito de instanciar no Windows: volumes Linux, init da config, porta publicada e script de start.

## O que sobe

| Serviço | Função |
| --- | --- |
| `openclaw-init` | Cria diretórios, grava `openclaw.json` na primeira execução e ajusta dono para UID 1000 |
| `openclaw-gateway` | Gateway + Control UI, publicado em `127.0.0.1:18789` |
| `openclaw-cli` | CLI no mesmo namespace de rede do gateway (profile `cli`) |

Estado persistente:

- `openclaw-data` → `/home/node/.openclaw` (config, workspace, credenciais)
- `openclaw-auth` → `/home/node/.config/openclaw`

Bind mount de pasta do Windows (`C:\...`) quebra o OpenClaw com `EPERM` em `chmod`. Por isso o estado fica em volumes Docker.

## Pré-requisitos

- Docker Desktop com Compose v2
- Porta `18789` livre no host (e `18790` se for usar o bridge)

## Subir

```powershell
cd C:\Apps\OpenClaw
Copy-Item .env.example .env
# Preencha OPENCLAW_GATEWAY_TOKEN (ou rode start.ps1, que gera um)
# Opcional: descomente OPENAI_API_KEY / ANTHROPIC_API_KEY / etc.
.\start.ps1
```

Ou:

```powershell
docker compose up -d openclaw-gateway
```

O init roda uma vez, o gateway sobe com `restart: unless-stopped`.

## Acessar da máquina real

1. Abra http://127.0.0.1:18789/
2. Cole o `OPENCLAW_GATEWAY_TOKEN` do `.env` em **Gateway secret**
3. Clique em **Connect**

Health check: http://127.0.0.1:18789/healthz

O gateway escuta em `lan` (`0.0.0.0` **dentro** do container). Só as portas mapeadas no Compose ficam visíveis no Windows. Não publique `18789` na internet.

## CLI

```powershell
docker compose --profile cli run --rm openclaw-cli --help
docker compose --profile cli run --rm openclaw-cli doctor --json
```

## Nova instância

Este repo é o molde. Cada instância precisa de projeto Compose, `.env` (porta + token + chaves) e volumes próprios:

```powershell
docker compose -p openclaw-cliente-a up -d openclaw-gateway
```

Troque `OPENCLAW_GATEWAY_PORT` se várias instâncias rodarem no mesmo host.

Depois de mudar o `.env`, recrie o container (`docker compose up -d`). `docker compose restart` não aplica variáveis novas.

## Variáveis úteis

Definidas em `.env` (nunca commitar esse arquivo):

| Variável | Padrão | Uso |
| --- | --- | --- |
| `OPENCLAW_IMAGE` | `ghcr.io/openclaw/openclaw:latest` | Tag da imagem oficial |
| `OPENCLAW_GATEWAY_TOKEN` | — | Segredo da Control UI |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Porta no host |
| `OPENCLAW_BRIDGE_PORT` | `18790` | Porta extra do bridge |
| `OPENCLAW_TZ` | `America/Sao_Paulo` | Timezone do container |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `OPENROUTER_API_KEY` | — | Pelo menos uma para o agente responder |

## Comandos do dia a dia

```powershell
docker compose ps
docker compose logs -f openclaw-gateway
docker compose down          # para os containers; volumes permanecem
docker compose down -v       # apaga também config e workspace
```

Atualizar a imagem oficial:

```powershell
docker compose pull
docker compose up -d openclaw-gateway
```

## O que não entra no git

- `.env` (token e API keys)
- Conteúdo dos volumes Docker
