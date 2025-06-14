# The SRE’s Guide to High Availability Open WebUI Deployment Architecture | by Taylor Wilsdon | May, 2025 | Medium

![Taylor Wilsdon](https://miro.medium.com/v2/resize:fill:64:64/1*2vTM233FV7YLdlBv2Ybg3Q.jpeg)
[Taylor Wilsdon](https://taylorwilsdon.medium.com/)

[**Open WebUI**](https://github.com/open-webui/open-webui) is one of, if not the single best chat interfaces for both local & hosted LLMs, giving you a production ready UI coupled with built-in RAG capabilities, web search and almost unlimited potential for customization thanks to a rich ecosystem of tools and functions.

For folks just starting out, the easiest way to run Open WebUI is using the very straightforward quickstart options: **Python** or **Docker**. If you’re just trying it out, _stop reading after the next paragraph and stick with the quickstart — this guide isn’t for you._

At some point however, you may find that you’ve outgrown the single container model, especially if you are serving significant user traffic or running it in an environment where 100% uptime is a hard requirement. If you’re in a position where an Open WebUI outage means you’re getting woken up by PagerDuty, then this is the guide for you.

gpt-image-1 is getting a hell of a lot better with text!

Python Quickstart
-----------------

> Open WebUI can be installed using **pip**, the Python package installer. Before proceeding, ensure you’re using Python 3.11. To install Open WebUI, open your terminal and run the following commands:

```
pip install open-webui
open-webui serve
```


This will start the Open WebUI server, which you can access at [http://localhost:8080](http://localhost:8080/)

Docker Quickstart
-----------------

> For certain Docker environments, additional config might be needed. If you encounter any issues, see the detailed guide @ [Open WebUI](https://docs.openwebui.com/)

Installation with Default Configuration (configure connections in the admin settings panel to Ollama or OpenAI compatible endpoints.

```
docker run -d -p 3000:8080 -e -v open-webui:/app/backend/data - name open-webui - restart always ghcr.io/open-webui/open-webui:main
```


High Availability Starts Here
-----------------------------

Ok, good — with that out of the way, welcome to the deep end. From here on out, we’ll assume:

*   **Multiple stateless WebUI containers** (Kubernetes Pods, Swarm services, ECS tasks — pick your poison), I personally have used k8s pods and Amazon’s ECS.
*   **One highly-available Redis tier** (stand-alone, Cluster or Sentinel). For me, that’s Amazon’s ElastiCache.
*   **External SQL** (PostgreSQL preferred) or at minimum a PVC for the default SQLite file, I’m using AWS Aurora. To migrate from the built in SQLite database from an existing instance to Postgres, check out the [interactive Open WebUI migration tool](https://github.com/taylorwilsdon/open-webui-postgres-migration).
*   **A load balancer** that understands long-lived WebSocket upgrades, in my case an AWS Application Load Balancer (ALB) which provides native support for websockets.

The goal here is a deployment that’s capable of shrugging off node drains, rolling upgrades, and the occasional fat-fingered `kubectl delete pod`.

Everything is stateless **except**:

1.  **JWT/session cookies** — signed with one shared `WEBUI_SECRET_KEY`.
2.  **App state & WebSocket fan-out** — persisted in Redis (`REDIS_URL`, `WEBSOCKET_REDIS_URL`).
3.  **Database** — Postgres or whatever you prefer.
4.  **Persistent Storage —** Storage for uploaded images, documents and attachments. You can use a shared mounted volume (ie AWS EFS/EBS) or a storage backend like S3.

Mandatory env cheatsheet
------------------------

**Cookie/JWT signing:  
**`WEBUI_SECRET_KEY` must use the same across _all_ nodes  
**General Redis:  
**`REDIS_URL=redis://redis:6379/0`  
_editors note — if you’re using AWS ElastiCache, you’ll put_ **_rediss_** _in place of redis for TLS_**WebSocket broker:  
**`ENABLE_WEBSOCKET_SUPPORT=true`  
`WEBSOCKET_MANAGER=redis`  
`WEBSOCKET_REDIS_URL=${REDIS_URL}   `**Sticky-secret override for Redis Sentinel (optional)  
**`REDIS_SENTINEL_HOSTS=redis-a:26379,redis-b:26379`  
`WEBSOCKET_SENTINEL_HOSTS=$REDIS_SENTINEL_HOSTS`**SQL (Postgres)  
**`DATABASE_URL=postgresql+asyncpg://openwebui:password@db:5432/webui   `**Container tuning  
**`UVICORN_WORKERS=<num_cpus>`  
`THREAD_POOL_SIZE=<cpu*20>   `**SSL/Web loader  
**`WEBUI_URL=https://chat.yourdomain.com` for share-links & search

> **_Why WEBSOCKET\_REDIS\_URL_ and _REDIS\_URL?_**_  
> WebUI uses one channel for generic app-state (config items, tasks etc.) and a second channel for websocket management. You can point them at the same Redis unless you have a reason not to, but each needs to be set up._

Load Balancer Config:
---------------------

**HTTP idle timeout**: ≥ 65 s (matches default `keepalive_timeout`)  
**Upgrade headers**:`Connection: Upgrade`, `Upgrade: websocket   `**Sticky sessions**: **Not required**—JWT + Redis make any pod stateless, but harmless if enabled  
**Health check**:`GET /healthz` (200 OK)

Scaling Notes & Considerations:
-------------------------------

**When pods restart, do users stay logged in?** Yes, the shared `WEBUI_SECRET_KEY` + external Redis configuration handles this beautifully. Recycle a node and nobody will even notice mid chat.

**PersistentConfig drift across pods:** Make sure that you’ve got a shared data volume and the `DATABASE_URL` correctly configured so all containers / pods read the same config.

**High QPS vector search:** The in-container ChromaDB will be an immediate bottleneck, especially when running in containers without GPU compute available to them. You’ll want to configure the`VECTOR_DB`[​](https://docs.openwebui.com/getting-started/env-configuration/#vector_db)environment variable, choosing from`chroma`, `elasticsearch`, `milvus`, `opensearch`, `pgvector`, `qdrant`or `pinecone`

*   Depending on your selection, each has its own configuration set. Once you’ve made your choice, find the [**necessary config items**](https://docs.openwebui.com/getting-started/env-configuration/#vector-database) here!

**RAG Content Extraction Engine:** You can likely get away with the default in-container extraction engine, but for better performance and more flexibility you’ve got a bunch of choices: `external`, `tika`, `docling`, `document_intelligence`, or `mistral_ocr`.

*   Same as the above, you’ll have a config set for whatever type you choose. In the interest of brevity, you can find the [**necessary items for your choice**](https://docs.openwebui.com/getting-started/env-configuration/#rag-content-extraction-engine) here!

**Embedding Model Engine:** You don’t want to be running SentenceTransformers in a lightweight container, so the `RAG_EMBEDDING_ENGINE` setting should be set to either `ollama` or `openai`.

*   Depending on your selection, you’ll need to configure `RAG_EMBEDDING_MODEL` — I’ve found that OpenAI’s `text-embedding-3-small` works just fine.
*   You can enable **RAG Hybrid Search** with `ENABLE_RAG_HYBRID_SEARCH`, combining a BM25 retriever with your chosen vector store to leverage reranking.

**Task Model Configuration:** Open WebUI tasks (title generation, autocomplete, tags, retrieval and web search query generation etc) do not need a big, heavy model so you don’t want to let it default to “current model” — pick something like gpt-4.1-nano for OpenAI or Qwen3:8b for local models, otherwise you’ll find significant lag if a user is calling a slow, heavy reasoning model and asking it to also handle these tiny calls all at once. Set both `TASK_MODEL` and `TASK_MODEL_EXTERNAL` to ensure your use cases are met.

Sample Config:
--------------

You have a ton to decide before you are at the point of configuring Presumably anyone operating at this scale already has an established stack and their ci/cd pipelines + secret management systems, so it’s more of a choose-your-own adventure than a one size fits all config — but just conver to whatever format you ingest your manifests in and obviously you’ll have to inject your own secrets where applicable (AWS SSM, Hashicorp Vault etc).

```
# ------------ Mandatory ENV Variables ------------
# Cookie/JWT signing key (must be the same across all nodes)
WEBUI_SECRET_KEY=your-very-secret-key
# General Redis URL (use rediss:// if using TLS with AWS ElastiCache)
REDIS_URL=redis://redis:6379/0
# Enable WebSocket support
ENABLE_WEBSOCKET_SUPPORT=true
# WebSocket manager and URL (typically redis)
WEBSOCKET_MANAGER=redis
WEBSOCKET_REDIS_URL=${REDIS_URL}
# Redis Sentinel hosts (optional — comma separated, if using Sentinel)
REDIS_SENTINEL_HOSTS=
WEBSOCKET_SENTINEL_HOSTS=${REDIS_SENTINEL_HOSTS}
# SQL Database URL (PostgreSQL recommended; update with your DB credentials)
DATABASE_URL=postgresql+asyncpg://openwebui:password@db:5432/webui
# Container tuning (adjust based on deployment resources)
UVICORN_WORKERS=
THREAD_POOL_SIZE=
# Public WebUI URL (for share-links & search)
WEBUI_URL=https://chat.yourdomain.com
# ------------ Choose Your Own Adventure Settings ------------
# Vector DB selection (chroma, elasticsearch, milvus, opensearch, pgvector, qdrant, pinecone)
VECTOR_DB=chroma
# Vector DB specific configuration variables go here, e.g.:
# ELASTICSEARCH_URL=
# MILVUS_HOST=
# QDRANT_HOST=
# ...
# RAG Content Extraction Engine (external, tika, docling, document_intelligence, mistral_ocr)
RAG_EXTRACTION_ENGINE=
# RAG Embedding Engine (ollama, openai)
RAG_EMBEDDING_ENGINE=
# Embedding Model for RAG (example for OpenAI)
RAG_EMBEDDING_MODEL=text-embedding-3-small
# Enable RAG Hybrid Search (optional, true/false)
ENABLE_RAG_HYBRID_SEARCH=false
# Task Model Configuration (ensure these are lightweight for snappy UI tasks)
TASK_MODEL=
TASK_MODEL_EXTERNAL=
# Persistent storage config (S3/EFS details if used; add your own keys here)
# S3_BUCKET=
# S3_ACCESS_KEY_ID=
# S3_SECRET_ACCESS_KEY=
# EFS_MOUNT_PATH=
# ...
# ------------ Example for Okta OIDC (if using SSO) ------------
# OKTA_CLIENT_ID=
# OKTA_CLIENT_SECRET=
# OKTA_ISSUER_URL=
# Check out groups config, JIT provisioning etc 
```


Want to take it even further? Check out my guide to setting up [**Okta OIDC Single Sign On**](https://docs.openwebui.com/tutorials/integrations/okta-oidc-sso)**.** Combine and manage your LLM endpoints with a proxy appliance like [**LiteLLM**](https://github.com/BerriAI/litellm).

Extend your capabilities leveraging **OpenAPI** spec tool servers or **MCP** servers (the latter of which facilitated by the excellent [**mcpo**](https://github.com/open-webui/mcpo)**)** to extend the capabilities of your models. Native tool calling is highly recommended for models that are capable of it. Open WebUI also has an [**extensive library**](https://openwebui.com/) of native (in-container execution) tools and functions.

Made it this far? Hell yeah you did. Give yourself a pat on the back and sleep well knowing you’ve cut your risk of being paged significantly. If you run into any issues or have any questions, feel free to hit me up in the comments!