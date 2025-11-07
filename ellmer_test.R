library(ellmer)

system("aws configure export-credentials --format env")
Sys.setenv(
  AWS_DEFAULT_REGION = "us-east-1",
  AWS_ACCESS_KEY_ID = "",
  AWS_SECRET_ACCESS_KEY = "",
  AWS_SESSION_TOKEN = ""
)

# Basic usage - create a chat object
chat <- chat_aws_bedrock(
  model = "us.anthropic.claude-sonnet-4-20250514-v1:0",
  echo = "all"
)

# Send a message
response <- chat$chat("What is the capital of France?")
print(response)


# Continue the conversation
response2 <- chat$chat("What's the population of that city?")
print(response2)
