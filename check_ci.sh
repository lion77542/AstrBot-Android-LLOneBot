#!/bin/bash
REPO="lion77542/AstrBot-Android-LLOneBot"
TOKEN="***"
RUN="28462691202"

# Get job steps
RESP=$(curl -s -H "User-Agent: Hermes-Agent" -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/actions/runs/$RUN")
STATUS=$(echo "$RESP" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)
CONCLUSION=$(echo "$RESP" | grep -o '"conclusion": "[^"]*"' | head -1 | cut -d'"' -f4)
echo "run=$RUN status=$STATUS conclusion=$CONCLUSION"

if [ "$STATUS" = "completed" ] && [ "$CONCLUSION" = "failure" ]; then
  # Get failed step info
  echo "$RESP" | grep -o '"name": "[^"]*"\|"conclusion": "[^"]*"\|"status": "[^"]*"' | head -40
  
  # Try to get logs
  JOBS_URL=$(echo "$RESP" | grep -o '"jobs_url": "[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$JOBS_URL" ]; then
    JOB_RESP=$(curl -s -H "User-Agent: Hermes-Agent" -H "Authorization: token $TOKEN" "$JOBS_URL")
    echo "$JOB_RESP" | grep -o '"logs_url": "[^"]*"' | head -3
  fi
fi
