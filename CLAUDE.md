# Vivero AI — Plataforma Multi-Agente (FONTE DE MEMÓRIA DO PROJETO)

> Este arquivo é a **fonte única de verdade / memória** do projeto inteiro (Paperclip + OpenClaw + Hermes + Claw3D). Atualizar aqui a cada sessão. **NUNCA colocar segredos** (tokens/keys) — este repo vai pro GitHub. Segredos vivem nas **Railway Variables**; aqui só referenciamos os NOMES.

## 1. Arquitetura

**3 camadas:** 🎩 **Paperclip** = orquestra/governança (org chart, empresas, papéis, orçamento). 🤖 **OpenClaw** + **Hermes** = runtimes que EXECUTAM (canais, skills, raciocínio). 🎥 **Claw3D** = visualizador 3D + chat + console de gestão.

**Multi-empresa:** **1 Paperclip central** (multi-company nativo) + **por empresa**: OpenClaw + Hermes (+ Hermes-Adapter) + Claw3D.

**Protocolo do gateway = 4** em TODOS (a "saga" foi resolver isso). Não reverter os patches 3→4.

**4 repos** (forks em `github.com/escoladesolucoes/`), MESMOS repos → N conjuntos de serviços Railway (diferença = env + volumes):
- `openclaw-railway` → serviço OpenClaw (wrapper + ponte Instagram custom)
- `hermes-agent-template` → serviço Hermes (NousResearch/hermes-agent, canais nativos)
- `Claw3D` → serve DOIS papéis via `START_MODE`: Claw3D Studio (visualizador) **e** Hermes-Adapter (`START_MODE=hermes-adapter`, traduz HTTP do Hermes ↔ protocolo gateway)
- `paperclip-railway-template` → Paperclip (1 só, builda paperclipai/paperclip no `PAPERCLIP_REF` + patches no Dockerfile)

Locais: `/Users/thiagoberto/{openclaw-railway,hermes-agent-template,Claw3D,paperclip-railway-template}`. Railway: projeto **Vivero AI** (CLI logado como Escola de Soluções).

## 2. Conceitos-chave (não esquecer)

- **Agente ≠ infraestrutura.** O agente só sabe o que está na **identidade/SOUL.md/skills/contexto**. Ele NÃO sabe das pontes/canais externos automaticamente. Pra ele "saber" o papel, escrever na persona.
- **Claw3D 3D (salas, andares) = VISUALIZAÇÃO.** O agente não "mora" nas salas, não "vai" pra sala de reuniões, não tem noção de espaço. "Floor" = só onde o Claw3D posiciona o boneco. O agente está conectado ao GATEWAY, não a um andar.
- **Canais nativos (WhatsApp/Telegram no Hermes):** o agente recebe canal + remetente + memória por contato automaticamente. **Instagram = ponte custom** (texto cru; mas cria sessão `instagram-<id>` + tem activity log → dá pra agregar).
- **"Quem me mandou mensagem hoje?"** NÃO sai de fábrica (conversas são sessões isoladas), MAS os blocos existem (`sessions.list` + `chat.history` + activity log do IG). Precisa de uma **skill de inbox** + papel de operador. Vale pros 3 canais.
- **Paperclip openclaw_gateway:** criar agente gateway remoto = via INVITE ou API direto (`POST /api/companies/:id/agents`, server aceita; auth = sessão). Tile destravado pelo nosso patch (ver §4).

## 3. Estado atual (✅ feito em 2026-06-15)

- **Update geral dos 4:** Hermes `v2026.6.5`, OpenClaw `2026.6.6`, Paperclip `v2026.609.0`, Claw3D `upstream/main`. Protocolo 4 mantido (tarballs conferidos). Patches 3→4 preservados (Paperclip Dockerfile sed; Claw3D hermes-adapter hello-ok=4 — upstream ainda manda 3).
- **DeepSeek do agente `main` (OpenClaw) funcionando.** Causa da quebra = 2026.6.6 mudou auth p/ sqlite por-agente que reseta no boot e NÃO carrega api_key inline por-agente. Fix aplicado: env `DEEPSEEK_API_KEY` + `openclaw models auth paste-api-key --provider deepseek` (global) + key no `openclaw.json` `auth.profiles.deepseek:default` no formato `{provider, mode:"api_key", key}` (⚠️ schema usa **`mode`**, NÃO `type` — usar `type` QUEBRA o gateway em crash-loop). **Backup `/data/openclaw-bak.tgz` no volume.** ⚠️ NUNCA editar `openclaw.json` ao vivo sem validar schema.
- **Claw3D:** Floors renomeados (`openclaw-ground`→"Setor OpenClaw", `hermes-first`→"Setor Hermes"), Lobby `enabled:false`, default floor→openclaw-ground. Skill **Kanban/task-manager** instalada no `main` (`openclaw skills install /data/.openclaw/workspace/skills/task-manager --agent main` — só dropar arquivo não basta, tem que registrar).
- **Tile `openclaw_gateway` no Paperclip:** patch de 6 arquivos (`openclaw-gateway-create.patch`) aplicado no build via Dockerfile `git apply` fail-closed (antes do build da UI). Destrava o tile no "Add agent" + form URL/token → cria OpenClaw/Hermes pela UI sem invite. ⚠️ **re-gerar o patch se bumpar `PAPERCLIP_REF`** (o `git apply --check` falha o build avisando).
- **Hermes:** WhatsApp + Telegram NATIVOS = `connected`. `api_server` (API HTTP 8642) = `disconnected` (o 401).

## 4. Conexões / gotchas operacionais (valores nas Railway Variables)

| O que | Variável (serviço) | Valor |
|---|---|---|
| Token do gateway | `OPENCLAW_GATEWAY_TOKEN` (OpenClaw) = `CLAW3D_GATEWAY_TOKEN` (Claw3D) | Railway Variables |
| URL gateway OpenClaw | `CLAW3D_GATEWAY_URL` | `ws://openclaw.railway.internal:8080` |
| URL gateway Hermes | (Claw3D backend hermes) | `ws://hermes-adapter.railway.internal:8080` (NÃO valida token inbound) |
| Cookie acesso Claw3D | `STUDIO_ACCESS_TOKEN` (Claw3D) | Railway Variables |
| Admin do wrapper OpenClaw | `WRAPPER_ADMIN_PASSWORD` (OpenClaw) → `/admin` | Railway Variables |
| Chave DeepSeek | `DEEPSEEK_API_KEY` + `auth-profiles.json` do agente | Railway Variables |

- **Onde achar:** Railway → projeto **Vivero AI** → serviço → aba **Variables**.
- **Conectar Claw3D→gateway:** setar cookie `studio_access` no browser; `UPSTREAM_ALLOWLIST` = hostnames **SEM porta**; se der `token_mismatch`, colar o token no Control UI.
- **`/setup` wizard do OpenClaw TRAVADO** quando gateway rodando (redireciona p/ `/`; recusa POST com "Use /api/config"). Só funciona no onboarding inicial.
- **Hermes 401:** `api_server.py` compara `Bearer` com `extra["key"]` (config do gateway) que ≠ `API_SERVER_KEY` da env; e o platform `api_server` está `disconnected` no `gateway_state.json`.

## 5. PENDÊNCIAS (próxima sessão)

> **DECISÃO 2026-06-15 (Thiago):** **(a)** **Hermes = PADRÃO da ponte de Instagram** (não OpenClaw) — rotear a ponte p/ chamar a API HTTP do Hermes; **pré-requisito = consertar o `api_server` do Hermes (item 5, virou PRIORIDADE).** **(b)** Arquitetura atual (Paperclip central distribuído) MANTIDA por enquanto; **co-localizar** (Paperclip+Hermes+Claw3D local, 1 por empresa) = decisão p/ DEPOIS. **(c)** Renomeação de repos (convenção escolhida: `viveroai-openclaw/hermes/claw3d/paperclip`) + serviços Railway (`Função - Empresa`) = decidida mas ADIADA.

1. **Persona do "Gestor de Redes Sociais da Ayni"** — escrever identidade/SOUL.md do agente `main`: papel (secretário de social media), canais que atende (IG via ponte; WhatsApp/Telegram se migrar p/ Hermes), tom de voz, e instruir a usar a skill de inbox. Tira o ruído de "estou fazendo onboarding no Paperclip" (contexto residual do invite).
2. **Skill de "inbox / quem me mandou hoje"** — agrega `sessions.list` + `chat.history` (+ activity log do IG; enriquecer IG `id`→nome via Graph API). Coração do "secretário". Vale OpenClaw e Hermes.
3. **Eduzz + Infinitum** — subir cada empresa: `OpenClaw-<C>` + `Hermes-<C>` + `Hermes-Adapter-<C>` + `Claw3D-<C>` (MESMOS repos, env próprio: tokens novos por empresa, `UPSTREAM_ALLOWLIST` sem porta, URLs internas `*-<C>.railway.internal`), **conectadas no Paperclip CENTRAL** (1 só, companies separadas). Env-spec já extraído (workflow provision-spec). Ordem de criação: OpenClaw+Hermes (independentes) → Hermes-Adapter+Claw3D (dependem dos domínios). Protocolo 4 já vem dos repos. Empresas Ayni+Vivero JÁ existem no Paperclip; faltam Eduzz+Infinitum.
4. **Bugs Claw3D (1 deploy):** (a) **inversão hermes↔openclaw** — `useOfficeFloorRuntimePersistence.ts` persiste o gateway conectado no andar visível → `officeFloors[floor].gatewayUrl` fica cruzado; fix = guard (só persistir se adapterType == floor.provider) + no load (OfficeScreen ~1480) ignorar URL salva que não bate com o provider do floor (auto-cura). (b) **roster não atualiza ao trocar gateway** (mesma raiz) — re-fetch do roster quando a conexão muda.
5. **🔴 PRIORIDADE — Hermes `api_server` (porta 8642) + rotear Instagram→Hermes.** **CAUSA-RAIZ ENCONTRADA:** o `api_server` está `disconnected` porque **a porta 8642 já está EM USO** (log: `[Api_Server] Port 8642 already in use`; retry a cada 300s, attempt 36+ — provável processo stale/zumbi de um gateway anterior segurando a porta). **Fix:** liberar a 8642 (matar o processo que segura — `lsof`/`fuser` no container; ou reiniciar o serviço Hermes pode liberar) OU mover o api_server p/ outra porta (`platforms.api_server.port` no config do hermes + atualizar `HERMES_API_URL` do Hermes-Adapter). Auth (depois de subir): `api_server.py` compara Bearer com `extra['key']` da config do gateway ≠ env `API_SERVER_KEY` → alinhar. **DEPOIS de a API responder**, executar a DECISÃO (a): **rotear a ponte de Instagram p/ chamar a API HTTP do Hermes** em vez de `openclaw agent` (reaproveitar o bridge Node do openclaw-railway trocando só o "chamar agente" por um `POST` na API do Hermes em `hermes-agent.railway.internal:8642`; OU mover o bridge p/ o wrapper do Hermes — atualizar o webhook da Meta se mudar de serviço).
6. **Verificar:** tile no "Add agent" (após build do Paperclip terminar); DeepSeek sobrevive a restart.
7. **Decisão estratégica:** ✅ DECIDIDO 2026-06-15 — **Hermes é o padrão da ponte de Instagram** (ver decisão no topo de §5; execução = item 5). OpenClaw: avaliar depois se mantém só p/ o que já funciona ou migra tudo p/ Hermes. Co-localização do Paperclip (1 por empresa, Hermes+Claw3D local) = decisão p/ DEPOIS.

## 6. Memória auxiliar (histórico detalhado)
Em `~/.claude/projects/-Users-thiagoberto-Soundzz/memory/`: `project_vivero_ai_plataforma_multiagente`, `project_paperclip_internals_agentes_modelos`, `project_vivero_atualizacao_4componentes_2026_06_15`, `project_openclaw_railway_instagram_secretario`. Este CLAUDE.md é o índice mestre; os memory files têm o passo-a-passo histórico.
