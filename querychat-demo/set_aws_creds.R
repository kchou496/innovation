aws_creds <- system("aws configure export-credentials --format env", intern = TRUE)

cred_list <- list()
for (line in aws_creds) {
  if (nchar(trimws(line)) == 0) next
  
  # Remove 'export ' prefix
  line <- sub("^export ", "", line)
  
  # Split on first '=' only
  eq_pos <- regexpr("=", line)[1]
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    value <- substr(line, eq_pos + 1, nchar(line))
    cred_list[[key]] <- value
  }
}

# Set all environment variables at once
do.call(Sys.setenv, cred_list)

Sys.setenv(AWS_DEFAULT_REGION = "us-east-1")

# Verify it worked
Sys.getenv("AWS_ACCESS_KEY_ID")
Sys.getenv("AWS_SECRET_ACCESS_KEY")
Sys.getenv("AWS_SESSION_TOKEN")
Sys.getenv("AWS_DEFAULT_REGION")


