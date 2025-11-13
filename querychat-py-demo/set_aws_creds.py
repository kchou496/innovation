import subprocess
import os

# Get AWS credentials
aws_creds = subprocess.run(
    ["aws", "configure", "export-credentials", "--format", "env"],
    capture_output=True,
    text=True
).stdout

# Parse and set environment variables
for line in aws_creds.strip().split('\n'):
    line = line.strip()
    if not line:
        continue
    
    # Remove 'export ' prefix if present
    if line.startswith('export '):
        line = line[7:]
    
    # Split on first '=' only
    if '=' in line:
        key, value = line.split('=', 1)
        os.environ[key] = value

# Set AWS region
os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'

# Verify it worked
print(f"AWS_ACCESS_KEY_ID: {os.environ.get('AWS_ACCESS_KEY_ID')}")
print(f"AWS_SECRET_ACCESS_KEY: {os.environ.get('AWS_SECRET_ACCESS_KEY')}")
print(f"AWS_SESSION_TOKEN: {os.environ.get('AWS_SESSION_TOKEN')}")
print(f"AWS_DEFAULT_REGION: {os.environ.get('AWS_DEFAULT_REGION')}")