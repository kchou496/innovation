library(paws)

# Create bedrock runtime client
client <- bedrockruntime(
  config = list(
    credentials = list(
      creds = list(
        access_key_id = Sys.getenv("AWS_ACCESS_KEY_ID"),
        secret_access_key = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
        session_token = Sys.getenv("AWS_SESSION_TOKEN")
      )
    ),
    region = "us-east-1"
  )
)

# Try to invoke with lowercase parameters
result <- client$invoke_model(
  modelId = "us.anthropic.claude-sonnet-4-20250514-v1:0",
  body = charToRaw('{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"Hello"}],"max_tokens":100}')
)

# If successful, decode the response
rawToChar(result$body)
