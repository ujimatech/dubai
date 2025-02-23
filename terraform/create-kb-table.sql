-- Create the extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Now you can create your table with vector column
CREATE TABLE knowledge_embeddings (
    id UUID PRIMARY KEY,
    content TEXT,
    metadata JSONB,
    embedding vector(1024)  -- Now this will work
);