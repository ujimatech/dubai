# C4 Level 3: Component Diagram for LiteLLM Proxy

```mermaid
C4Component
    title Component Diagram for LiteLLM Proxy (Refined LLM Adapters)

    Container(openwebui_app, "OpenWebUI Application", "Python, React", "Container: User interface that sends LLM requests.")
    System(openrouter_llm, "OpenRouter LLM Provider", "Third-party Public LLM services.")
    System(aws_bedrock_llm, "AWS Bedrock LLM Provider", "AWS Managed LLM services for sensitive data.")
    Container(secrets_mgmt, "Secrets Management", "AWS Secrets Manager", "Container: Secure credential storage.")
    Container(dubai_vpc, "DubAI VPC", "AWS Virtual Private Cloud", "Networking environment for secure internal communication.")


    System_Boundary(litellm_proxy, "LiteLLM Proxy") {

        Component(api_handler, "API Handler / Request Validator", "Python", "Receives and validates incoming LLM API requests.")
        Component(std_layer, "Standardization Layer", "Python", "Transforms requests/responses to/from a consistent internal format.")
        Component(llm_router, "LLM Router / Dispatcher", "Python", "Routes requests to the appropriate LLM Integration Adapter.")
        Component(api_key_manager, "API Key Manager / Credential Retriever", "Python", "Securely fetches and manages LLM API keys/credentials for providers.")

        Component(openrouter_adapter, "OpenRouter Adapter", "Python", "Integrates with OpenRouter API.")
        Component(aws_bedrock_adapter, "AWS Bedrock Adapter", "Python, AWS SDK", "Integrates with AWS Bedrock via VPC-internal mechanisms.")


        Rel(api_handler, std_layer, "Passes validated request to")
        Rel(std_layer, llm_router, "Passes standardized request to")
        Rel(llm_router, openrouter_adapter, "Dispatches Public LLM Request to")
        Rel(llm_router, aws_bedrock_adapter, "Dispatches Sensitive LLM Request to")

        Rel(api_key_manager, secrets_mgmt, "Retrieves API Keys/Credentials From", "AWS SDK Calls")
        Rel(openrouter_adapter, api_key_manager, "Uses API Key From")
        Rel(aws_bedrock_adapter, api_key_manager, "Uses IAM Role/Key From")

        Rel(openrouter_adapter, openrouter_llm, "Makes API calls to", "Public Internet")
        Rel(aws_bedrock_adapter, aws_bedrock_llm, "Makes API calls to", "VPC Endpoint")

        Rel(llm_router, dubai_vpc, "Operates within", "Private Network Access")
        Rel(aws_bedrock_llm, dubai_vpc, "Accessed via", "Private Endpoint")

    }

    Rel(openwebui_app, api_handler, "Sends LLM requests to", "API Calls")
    Rel(api_handler, openwebui_app, "Sends responses to")
```

This diagram zooms into the **LiteLLM Proxy** container, which we saw in the Container Diagram. It breaks down this container into its internal, logical components and shows how they interact with each other and with critical external systems, particularly focusing on how it handles connections to different types of Large Language Models.

**Container in Focus:** **`LiteLLM Proxy`**

**Key Components within LiteLLM Proxy and Their Roles:**

*   **`API Handler / Request Validator`:**
    *   **Description:** This is the entry point for all incoming LLM API requests (e.g., from OpenWebUI). It receives these requests, validates their format and any authentication headers, and extracts the necessary parameters for the LLM call.
    *   **Technology:** Python.
*   **`Standardization Layer`:**
    *   **Description:** This crucial component ensures uniformity. It transforms incoming requests from various sources into a consistent internal format that the LiteLLM Proxy understands. Similarly, it transforms responses from LLM providers back into a standardized format before sending them out.
    *   **Technology:** Python.
*   **`LLM Router / Dispatcher`:**
    *   **Description:** This component acts as the traffic controller. Based on the model requested or other criteria, it intelligently decides which specific LLM Integration Adapter (e.g., OpenRouter, AWS Bedrock) should handle the request and dispatches it accordingly.
    *   **Technology:** Python.
*   **`API Key Manager / Credential Retriever`:**
    *   **Description:** This component is responsible for securely obtaining and managing the API keys, IAM roles, or other credentials required to authenticate with different LLM providers. It communicates directly with the external `Secrets Management` service.
    *   **Technology:** Python, AWS SDK.
*   **`OpenRouter Adapter`:**
    *   **Description:** A specific integration module designed to communicate with the **OpenRouter LLM Provider**. It translates internal LiteLLM requests into OpenRouter's specific API format and handles the responses. This is typically used for public LLM interactions.
    *   **Technology:** Python.
*   **`AWS Bedrock Adapter`:**
    *   **Description:** A specific integration module designed to communicate with the **AWS Bedrock LLM Provider**. This adapter is optimized for interaction with AWS's managed LLM services, often involving specific AWS SDK calls and potentially leveraging private network access for sensitive data.
    *   **Technology:** Python, AWS SDK.

**External Systems (relevant to this diagram):**

*   **`OpenWebUI Application` (Container):** The source of LLM requests to the LiteLLM Proxy.
*   **`OpenRouter LLM Provider` (System):** The external public LLM service accessed over the public internet.
*   **`AWS Bedrock LLM Provider` (System):** The AWS managed LLM service designed for sensitive data, accessed potentially via private endpoints within the VPC.
*   **`Secrets Management` (Container):** The service that securely stores the API keys and credentials needed by LiteLLM Proxy's `API Key Manager`.
*   **`DubAI VPC` (Container):** Represents the private network environment within AWS where the DubAI system operates. This is explicitly shown to highlight that `AWS Bedrock LLM Provider` is accessed via the VPC.

**Interactions and Flow:**

1.  **Incoming Request:** The **`OpenWebUI Application`** **`Sends LLM requests to`** the **`API Handler / Request Validator`**.
2.  **Internal Processing:**
    *   The **`API Handler`** **`Passes validated request to`** the **`Standardization Layer`**.
    *   The **`Standardization Layer`** **`Passes standardized request to`** the **`LLM Router / Dispatcher`**.
    *   The **`LLM Router / Dispatcher`** **`Dispatches`** requests to either the **`OpenRouter Adapter`** (for public LLM calls) or the **`AWS Bedrock Adapter`** (for sensitive LLM calls).
3.  **Credential Management:** The **`API Key Manager / Credential Retriever`** **`Retrieves API Keys/Credentials From`** **`Secrets Management`**. Each adapter (OpenRouter, AWS Bedrock) **`Uses API Key/IAM Role From`** the `API Key Manager`.
4.  **External LLM Communication:**
    *   The **`OpenRouter Adapter`** **`Makes API calls to`** the **`OpenRouter LLM Provider`** over the public internet.
    *   The **`AWS Bedrock Adapter`** **`Makes API calls to`** the **`AWS Bedrock LLM Provider`**, specifically via a `VPC Endpoint` within the `DubAI VPC`, emphasizing secure, private access for sensitive data.
5.  **Network Context:** The `LiteLLM Proxy` (implicitly, via its containers and connections) **`Operates within`** the **`DubAI VPC`**, and the **`AWS Bedrock LLM Provider`** is **`Accessed via`** that `Private Endpoint` within the VPC.
6.  **Outgoing Response:** The `API Handler` **`Sends responses to`** the `OpenWebUI Application`.

In essence, this diagram provides a deep dive into how LiteLLM Proxy acts as an intelligent intermediary, routing different types of LLM calls (public vs. sensitive) to appropriate providers while managing credentials and ensuring secure network interactions, particularly for Bedrock.
