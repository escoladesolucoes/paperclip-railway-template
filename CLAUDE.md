# Vivero AI — Plataforma Multi-Agente (FONTE DE MEMÓRIA DO PROJETO)

> Este arquivo é a **fonte única de verdade / memória** do projeto inteiro (Paperclip + OpenClaw + Hermes + Claw3D). Atualizar aqui a cada sessão. **NUNCA colocar segredos** (tokens/keys) — este repo vai pro GitHub. Segredos vivem nas **Railway Variables**; aqui só referenciamos os NOMES.

## 1. Arquitetura

**3 camadas:** 🎩 **Paperclip** = orquestra/governança (org chart, empresas, papéis, orçamento). 🤖 **OpenClaw** + **Hermes** = runtimes que EXECUTAM (canais, skills, raciocínio). 🎥 **Claw3D** = visualizador 3D + chat + console de gestão.

**Multi-empresa:** **1 Paperclip central** (multi-company nativo) + **por empresa**: OpenClaw + Hermes (+ Hermes-Adapter) + Claw3D. **Empresas com stack provisionado: Ayni** (1ª; + ponte IG) **e Vivero** (2ª; SEM ponte IG por ora — ver §7). Eduzz/Infinitum = depois.

**Protocolo do gateway = 4** em TODOS (a "saga" foi resolver isso). Não reverter os patches 3→4.

**4 repos** (forks em `github.com/escoladesolucoes/`, **renomeados `viveroai-*` em 2026-06-15**), MESMOS repos → N conjuntos de serviços Railway (diferença = env + volumes):
- `viveroai-openclaw` (ex-`openclaw-railway`) → serviço OpenClaw (wrapper + ponte Instagram custom)
- `viveroai-hermes` (ex-`hermes-agent-template`) → serviço Hermes (NousResearch/hermes-agent, canais nativos)
- `viveroai-claw3d` (ex-`Claw3D`) → serve DOIS papéis via `START_MODE`: Claw3D Studio (visualizador) **e** Hermes-Adapter (`START_MODE=hermes-adapter`, traduz HTTP do Hermes ↔ protocolo gateway)
- `viveroai-paperclip` (ex-`paperclip-railway-template`) → Paperclip (1 só, builda paperclipai/paperclip no `PAPERCLIP_REF` + patches no Dockerfile)

Locais: `/Users/thiagoberto/{viveroai-openclaw,viveroai-hermes,viveroai-claw3d,viveroai-paperclip}`. Railway: projeto **Vivero AI** (CLI logado como Escola de Soluções). GitHub mantém redirect dos nomes antigos; Railway linka por ID do repo (sobrevive ao rename).

## 2. Conceitos-chave (não esquecer)

- **Agente ≠ infraestrutura.** O agente só sabe o que está na **identidade/SOUL.md/skills/contexto**. Ele NÃO sabe das pontes/canais externos automaticamente. Pra ele "saber" o papel, escrever na persona.
- **🔑 Hermes = SINGLE-AGENTE × OpenClaw = MULTI-AGENTE (confirmado 2026-06-15).** 1 instância **Hermes = UMA persona** (1 `SOUL.md` GLOBAL, 1 modelo `hermes-agent`, sem dir de agentes). "Criar agente" no Claw3D apontando pro Hermes NÃO cria nada novo — toda conexão cai no mesmo agente → **todos se apresentam igual** (não dá 2 personas em 1 Hermes). **OpenClaw é multi-agente real** (cada agente tem workspace+agent dir+identidade+roteamento próprios; `openclaw agents create <nome>`). → **Vários agentes distintos = OpenClaw** (ou 1 Hermes separado por persona, ex.: Vivero). Hermes = bom p/ o atendente único da empresa.
- **Claw3D 3D (salas, andares) = VISUALIZAÇÃO.** O agente não "mora" nas salas, não "vai" pra sala de reuniões, não tem noção de espaço. "Floor" = só onde o Claw3D posiciona o boneco. O agente está conectado ao GATEWAY, não a um andar.
- **Canais nativos (WhatsApp/Telegram no Hermes):** o agente recebe canal + remetente + memória por contato automaticamente. **Instagram = ponte custom** (texto cru; mas cria sessão `instagram-<id>` + tem activity log → dá pra agregar).
- **"Quem me mandou mensagem hoje?"** NÃO sai de fábrica (conversas são sessões isoladas), MAS os blocos existem (`sessions.list` + `chat.history` + activity log do IG). Precisa de uma **skill de inbox** + papel de operador. Vale pros 3 canais.
- **Paperclip openclaw_gateway:** criar agente gateway remoto = via INVITE ou API direto (`POST /api/companies/:id/agents`, server aceita; auth = sessão). Tile destravado pelo nosso patch (ver §4).

## 3. Estado atual (✅ feito em 2026-06-15)

- **Update geral dos 4:** Hermes `v2026.6.5`, OpenClaw `2026.6.6`, Paperclip `v2026.609.0`, Claw3D `upstream/main`. Protocolo 4 mantido (tarballs conferidos). Patches 3→4 preservados (Paperclip Dockerfile sed; Claw3D hermes-adapter hello-ok=4 — upstream ainda manda 3).
- **DeepSeek do agente `main` (OpenClaw) funcionando.** Causa da quebra = 2026.6.6 mudou auth p/ sqlite por-agente que reseta no boot e NÃO carrega api_key inline por-agente. Fix aplicado: env `DEEPSEEK_API_KEY` + `openclaw models auth paste-api-key --provider deepseek` (global) + key no `openclaw.json` `auth.profiles.deepseek:default` no formato `{provider, mode:"api_key", key}` (⚠️ schema usa **`mode`**, NÃO `type` — usar `type` QUEBRA o gateway em crash-loop). **Backup `/data/openclaw-bak.tgz` no volume.** ⚠️ NUNCA editar `openclaw.json` ao vivo sem validar schema.
- **Claw3D:** Floors renomeados (`openclaw-ground`→"Setor OpenClaw", `hermes-first`→"Setor Hermes"), Lobby `enabled:false`, default floor→openclaw-ground. Skill **Kanban/task-manager** instalada no `main` (`openclaw skills install /data/.openclaw/workspace/skills/task-manager --agent main` — só dropar arquivo não basta, tem que registrar).
- **Tile `openclaw_gateway` no Paperclip:** patch de 6 arquivos (`openclaw-gateway-create.patch`) aplicado no build via Dockerfile `git apply` fail-closed (antes do build da UI). Destrava o tile no "Add agent" + form URL/token → cria OpenClaw/Hermes pela UI sem invite. ⚠️ **re-gerar o patch se bumpar `PAPERCLIP_REF`** (o `git apply --check` falha o build avisando).
- **✅✅ Ponte Instagram→Hermes da Ayni NO AR e RESPONDENDO DM real** (serviço `Instagram Bridge - Ayni` `c921b0e9`; Meta já repontada pro host novo). **DM da Cidade Escola Ayni = Hermes (não OpenClaw)** — confirmado com "Olá" real. Detalhe completo (host, endpoints, vars, gotchas da Meta) em **§5 item 5**. Persona do Gestor + fix de privacidade do perfil global em **§5 item 1**.
- **Hermes:** WhatsApp + Telegram NATIVOS = `connected`. **✅ `api_server` (API HTTP) RESOLVIDO 2026-06-15** — causa-raiz era **colisão de porta** (`PORT=8642` do wrapper público uvicorn **==** `API_SERVER_PORT=8642` do api_server aiohttp → o wrapper tomava a porta, o api_server nunca subia e dava `disconnected`/"port in use"). Fix: `API_SERVER_PORT=8643` + `API_SERVER_HOST=::` (IPv6 p/ railway.internal) nas Variables do Hermes; `HERMES_API_URL` do Hermes-Adapter → `:8643`. **Verificado ao vivo:** `POST /v1/chat/completions` (Bearer `API_SERVER_KEY`) responde o agente; **memória por usuário OK** via header `X-Hermes-Session-Id` (turno 1 "meu nome é Thiago"→turno 2 "qual meu nome?"→"Thiago."). API interna agora em `hermes-agent.railway.internal:8643`.

## 4. Conexões / gotchas operacionais (valores nas Railway Variables)

| O que | Variável (serviço) | Valor |
|---|---|---|
| Token do gateway | `OPENCLAW_GATEWAY_TOKEN` (OpenClaw) = `CLAW3D_GATEWAY_TOKEN` (Claw3D) | Railway Variables |
| URL gateway OpenClaw | `CLAW3D_GATEWAY_URL` | `ws://openclaw.railway.internal:8080` |
| URL gateway Hermes | (Claw3D backend hermes) | `ws://hermes-adapter.railway.internal:8080` (NÃO valida token inbound) |
| Cookie acesso Claw3D | `STUDIO_ACCESS_TOKEN` (Claw3D) | Railway Variables |
| Admin do wrapper OpenClaw | `WRAPPER_ADMIN_PASSWORD` (OpenClaw) → `/admin` | Railway Variables |
| Chave DeepSeek | `DEEPSEEK_API_KEY` + `auth-profiles.json` do agente | Railway Variables |
| Hermes HTTP API (api_server) | `API_SERVER_PORT=8643`, `API_SERVER_HOST=::`, `API_SERVER_KEY` (Hermes) | interno: `http://hermes-agent.railway.internal:8643/v1/chat/completions` (Bearer `API_SERVER_KEY`). ⚠️ `API_SERVER_PORT` ≠ `PORT`(8642, wrapper público) senão colide |
| URL da API p/ o Hermes-Adapter | `HERMES_API_URL` (Hermes-Adapter) | `http://hermes-agent.railway.internal:8643` |

- **Onde achar:** Railway → projeto **Vivero AI** → serviço → aba **Variables**.
- **Conectar Claw3D→gateway:** setar cookie `studio_access` no browser; `UPSTREAM_ALLOWLIST` = hostnames **SEM porta**; se der `token_mismatch`, colar o token no Control UI.
- **`/setup` wizard do OpenClaw TRAVADO** quando gateway rodando (redireciona p/ `/`; recusa POST com "Use /api/config"). Só funciona no onboarding inicial.
- **Hermes 401/disconnected:** ✅ RESOLVIDO (ver §3) — era colisão `PORT`==`API_SERVER_PORT`; api_server foi p/ `8643` e valida `Bearer API_SERVER_KEY`.

### 4.1 Folha de conexão Ayni (Claw3D/Paperclip → OpenClaw/Hermes) — VALORES nas Railway Variables
| De → Para | Endereço (interno) | Token (NOME da var, valor nas Variables) |
|---|---|---|
| Claw3D / Paperclip → **OpenClaw (gateway WS)** | `ws://openclaw.railway.internal:8080` | `OPENCLAW_GATEWAY_TOKEN` (OpenClaw) = `CLAW3D_GATEWAY_TOKEN` (Claw3D) |
| Claw3D / Paperclip → **Hermes (gateway WS, via adapter)** | `ws://hermes-adapter.railway.internal:8080` | **sem token** (adapter NÃO valida inbound) |
| qualquer → **Hermes API HTTP** (api_server) | `http://hermes-agent.railway.internal:8643/v1/chat/completions` | `Authorization: Bearer <API_SERVER_KEY>` + `X-Hermes-Session-Id` |
| browser → **Claw3D Studio** | público `claw3d-production-7ca6.up.railway.app` | cookie `studio_access` = `STUDIO_ACCESS_TOKEN` (Claw3D) |
| browser → **OpenClaw /admin** | público `openclaw-production-e246.up.railway.app/admin` | `WRAPPER_ADMIN_PASSWORD` (OpenClaw) |

⚠️ `*.railway.internal` só resolve DENTRO do projeto Railway (serviço↔serviço). Do laptop, só os domínios públicos. `UPSTREAM_ALLOWLIST` do Claw3D já libera os dois gateways (hostnames SEM porta). Pra Vivero, trocar `openclaw`/`hermes-adapter` por `openclaw-vivero`/`hermes-adapter-vivero` e usar os tokens do Vivero.

## 5. PENDÊNCIAS (próxima sessão)

> **DECISÃO 2026-06-15 (Thiago):** **(a)** **Hermes = PADRÃO da ponte de Instagram** (não OpenClaw) — rotear a ponte p/ chamar a API HTTP do Hermes; **pré-requisito = consertar o `api_server` do Hermes (item 5, virou PRIORIDADE).** **(b)** ✅ **DEFINIDO — arquitetura FICA distribuída de vez:** **1 Paperclip CENTRAL** (atende TODAS as empresas, multi-company nativo) + **por empresa: 1 OpenClaw + 1 Claw3D + 1 Hermes** (+ Hermes-Adapter). **Co-localização do Paperclip foi DESCARTADA** (Thiago decentraliza só "mais tarde" se quiser; não é mais pendência). Isso encerra a dúvida de §1. **(c)** ✅ **Renomeação dos REPOS FEITA 2026-06-15** (remoto via `gh repo rename` + local `mv`+`git remote set-url`): `openclaw-railway`→`viveroai-openclaw`, `hermes-agent-template`→`viveroai-hermes`, `Claw3D`→`viveroai-claw3d`, `paperclip-railway-template`→`viveroai-paperclip`. GitHub redireciona nomes antigos; Railway linka por ID (deploys preservados — verificado). **Renomeação dos SERVIÇOS Railway (`Função - Empresa`) = AINDA PENDENTE** (cosmético/seguro, separado).

1. **✅ Persona do "Gestor de Redes Sociais da Ayni" FEITA 2026-06-15** — gravada em `/data/.hermes/SOUL.md` do Hermes (⚠️ SOUL.md é GLOBAL: vale IG+WhatsApp+Telegram). Backup do original em `/data/.hermes/SOUL.md.bak-20260615` (513 bytes). Persona = atendimento de redes sociais da Cidade Escola Ayni (PT-BR caloroso, sem nome próprio, NÃO se chama "SOUL"/"Hermes"; handoff p/ humano; ciente do papel de inbox). Pega na hora (sem restart). Verificado ao vivo (DM real "Olá"→resposta com a persona; perguntado "OpenClaw ou Hermes?"→respondeu "Sou a Ayni" sem vazar tech). **🔴 GOTCHA CRÍTICO DE PRIVACIDADE (corrigido 2026-06-15 em Ayni+Vivero):** o Hermes vem com `memory.user_profile_enabled: true` = **perfil de usuário GLOBAL** num arquivo único `/data/.hermes/memories/USER.md`, injetado em TODA conversa. Num teste meu o agente aprendeu "name is Thiago" → passou a chamar **TODO usuário do IG de "Thiago"** (vazamento entre usuários!). **Fix p/ bot público multi-usuário:** no `config.yaml` setar **`memory.user_profile_enabled: false`** (mantendo `memory_enabled: true` = memória POR-SESSÃO, isolada por `X-Hermes-Session-Key=instagram-<igsid>`) + **esvaziar `memories/USER.md`** + restart. O `write_config_yaml` do wrapper PRESERVA a seção `memory` (só gerencia model/terminal/agent), então o config.yaml gruda. **⚠️ Aplicar em TODO Hermes novo (Eduzz/Infinitum) — vem `true` por default.**
2. **✅ Skill de "inbox / quem me mandou hoje" FEITA 2026-06-15** — skill local `inbox-ayni` em `/data/.hermes/skills/inbox-ayni/` (SKILL.md + `inbox.py`). `hermes skills list` mostra `local/enabled` (dropar o dir basta no Hermes, ≠ OpenClaw). O agente roda `python3 .../inbox.py --since today|24h|7d` (terminal local), que consulta `localhost:8643/api/sessions`, filtra por canal (IG via `instagram-<igsid>`, wpp/telegram nativos), exclui sessões internas, e resume por canal com horário GMT-3 + prévia. ⚠️ **GOTCHA: o terminal do agente NÃO herda a env do gateway** → a key vem de `/data/.hermes/skills/inbox-ayni/.api_key` (chmod 600; valor=`API_SERVER_KEY`). Verificado ponta a ponta. Follow-ups: (a) IG `igsid`→nome via Graph API (precisa `IG_ACCESS_TOKEN` na env do Hermes — script já enriquece se existir); (b) **segurança: o toolset `terminal` do Hermes é GLOBAL (vale até DMs públicas do IG) → risco de prompt-injection; inbox hoje é gateado só pela persona. Endurecer (restringir terminal/inbox a canais de operador) = follow-up.**
3. **Eduzz + Infinitum** — subir cada empresa: `OpenClaw-<C>` + `Hermes-<C>` + `Hermes-Adapter-<C>` + `Claw3D-<C>` (MESMOS repos, env próprio: tokens novos por empresa, `UPSTREAM_ALLOWLIST` sem porta, URLs internas `*-<C>.railway.internal`), **conectadas no Paperclip CENTRAL** (1 só, companies separadas). Env-spec já extraído (workflow provision-spec). Ordem de criação: OpenClaw+Hermes (independentes) → Hermes-Adapter+Claw3D (dependem dos domínios). Protocolo 4 já vem dos repos. Empresas Ayni+Vivero JÁ existem no Paperclip; faltam Eduzz+Infinitum.
4. **✅ Bugs Claw3D RESOLVIDOS 2026-06-15** (`viveroai-claw3d` push `918bea3`, 7/7 testes + tsc/lint limpos): (a) **inversão hermes↔openclaw** — `useOfficeFloorRuntimePersistence.ts` ganhou guard por `activeAdapterType` (só persiste se bate com o provider do floor, opt-in); (b) **auto-cura na carga** (`OfficeScreen.handleSelectFloor` ~1480) descarta URL salva que pertence a outro adapter → conserta config já invertida + o **roster** (mostrava agents do gateway errado = mesma raiz).
5. **✅✅ Instagram→Hermes da Ayni NO AR E VERIFICADO COM DM REAL 2026-06-15.** Serviço Railway novo **`Instagram Bridge - Ayni`** (`c921b0e9`, repo `viveroai-openclaw` em `BRIDGE_ONLY=true`+`AGENT_BACKEND=hermes`, sem rodar OpenClaw; vol `/data`). Reaproveita o bridge provado (webhook verify/deauthorize/data-deletion/oauth, /privacy /terms, Send API `graph.instagram.com/me/messages`, handoff /bot /humano, **`IG_DEFAULT_BOT=off` = HUMANO-PRIMEIRO** — decisão Thiago 2026-06-15: o bot NÃO responde por padrão, só quem digitar `/bot`; `/humano` silencia; overrides limpos) trocando o `runAgentTurn` por `src/services/hermesAgent.js` → `POST /v1/chat/completions` (Bearer `API_SERVER_KEY` + `X-Hermes-Session-Id: instagram-<igsid>`). **Host (na Meta): `https://instagram-bridge-ayni-production.up.railway.app`** → `/webhooks/instagram` (verify token = `IG_VERIFY_TOKEN`), `/privacy`, `/terms`, deauthorize, data-deletion, oauth. **PROVA AO VIVO:** Thiago mandou "Olá" no DM da Cidade Escola Ayni → caiu na ponte (`sigOk`) → Hermes (sessão `instagram-<id>`) → resposta com a persona; enviada de volta ao IG (logs `sent`). **Meta gotchas:** "App nativo/desktop" = DESLIGADO (é servidor, guarda secret); "Autorizar URL de retorno de chamada" (OAuth) = `…/webhooks/instagram/oauth` (≠ webhook; só p/ o Business Login, mas a Meta exige preenchido). OpenClaw segue de pé (dormente p/ IG; mudanças no repo são opt-in). Follow-up: imagem pesada (slim depois).
6. **Verificar:** tile no "Add agent" (após build do Paperclip terminar); DeepSeek sobrevive a restart.
7. **Decisão estratégica:** ✅ DECIDIDO 2026-06-15 — **Hermes é o padrão da ponte de Instagram** (ver decisão no topo de §5; execução = item 5). OpenClaw: avaliar depois se mantém só p/ o que já funciona ou migra tudo p/ Hermes. Co-localização do Paperclip (1 por empresa, Hermes+Claw3D local) = decisão p/ DEPOIS.

## 6. Memória auxiliar (histórico detalhado)
Em `~/.claude/projects/-Users-thiagoberto-Soundzz/memory/`: `project_vivero_ai_plataforma_multiagente`, `project_paperclip_internals_agentes_modelos`, `project_vivero_atualizacao_4componentes_2026_06_15`, `project_openclaw_railway_instagram_secretario`. Este CLAUDE.md é o índice mestre; os memory files têm o passo-a-passo histórico.

## 7. Stack do VIVERO (provisionado 2026-06-15)

Segunda empresa com stack próprio (mesmos 4 repos, env próprio, **tokens NOVOS por empresa** — não reusa os do Ayni; **DeepSeek = MESMA chave**). **Sem ponte de Instagram por ora** (deixar pronto pro futuro = subir um `Instagram Bridge - Vivero` igual ao do Ayni quando houver conta IG/tokens Meta do Vivero).

| Serviço (Railway) | ID | Repo | Domínio interno | Notas |
|---|---|---|---|---|
| OpenClaw Vivero | `4c79cb61` | viveroai-openclaw | `openclaw-vivero.railway.internal` | `OPENCLAW_GATEWAY_TOKEN`(novo)=`CLAW3D_GATEWAY_TOKEN` do Claw3D Vivero; `OPENCLAW_VERSION=2026.6.6`; vol `/data`. ⚠️ **precisa ONBOARDING** (volume vazio → sem agente até configurar; ver saga DeepSeek do OpenClaw) |
| Hermes Vivero | `d4a74f2d` | viveroai-hermes | `hermes-vivero.railway.internal` | api_server `8643`+`::`+`API_SERVER_KEY`(novo); `PORT=8642`; model auth via Railway vars `DEEPSEEK_API_KEY`+`LLM_MODEL=deepseek/deepseek-v4-pro`; `ADMIN_USERNAME=thiago@vivero.org.br`; vol `/data`. ✅ agente + persona Vivero verificados |
| Hermes Adapter Vivero | `927dd9dd` | viveroai-claw3d (`START_MODE=hermes-adapter`) | `hermes-adapter-vivero.railway.internal` | `HERMES_API_URL=http://hermes-vivero.railway.internal:8643`; `HERMES_API_KEY`=API_SERVER_KEY do Hermes Vivero |
| Claw3D Vivero | `d02544ab` | viveroai-claw3d (Studio) | — (público `claw3d-vivero-production.up.railway.app`) | `CLAW3D_GATEWAY_URL=ws://openclaw-vivero.railway.internal:8080`; `CLAW3D_GATEWAY_TOKEN`=gateway token do Vivero; `STUDIO_ACCESS_TOKEN`(novo); `UPSTREAM_ALLOWLIST=openclaw-vivero.railway.internal,hermes-adapter-vivero.railway.internal` |

**Tokens do Vivero** (gerados novos, guardados nas Railway Variables de cada serviço; backup local efêmero `/tmp/vivero.env`): gateway (OpenClaw=Claw3D), wrapper admin (OpenClaw), Hermes api_server key (Hermes=Adapter), Hermes admin pass, studio access (Claw3D).

**✅ GOTCHA RESOLVIDO no template (Hermes) — `hermes-agent-template` push `b973f53`:** volume vazio dava "Config incomplete — gateway not started" porque `is_config_complete()` lê o **arquivo `/data/.hermes/.env`** (que tem prioridade sobre o env do Railway), não o env do processo. Agora o wrapper **auto-semeia o `.env` a partir das Railway Variables no boot** (`seed_env_from_os_environ()` em `auto_start()`): aditivo, idempotente, no-op se o `.env` já está completo (Ayni intacto), defensivo (não bloqueia boot). **Validado end-to-end** (apaguei o `.env` do Vivero → boot recriou + gateway subiu + agente respondeu). **Consequência: subir Hermes de empresa nova = só setar `DEEPSEEK_API_KEY`+`LLM_MODEL` (+`API_SERVER_*`) nas Railway Variables — sem passo manual de `.env`.**

**Follow-ups p/ "pronto pra uso" (config, não estrutura):** (1) **OpenClaw Vivero onboarding** (criar agente + DeepSeek — interativo, igual saga Ayni); (2) Hermes Vivero: parear WhatsApp/Telegram se quiser canais nativos; (3) Claw3D Vivero: conectar no gateway via Studio UI (cookie `studio_access`); (4) **conectar no Paperclip CENTRAL** (empresa Vivero + agentes via invite/tile); (5) **persona do agente Vivero** (genérica aplicada como ponto de partida — refinar). Estrutura/cabeamento = FEITO; esses são passos de configuração.
