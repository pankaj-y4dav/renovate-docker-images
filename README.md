# Renovate Docker Image Auto-Update Configuration

This repository contains a Renovate configuration designed to automatically detect and update Docker images (Datadog Agent and AWS Fluent Bit) across any repository, regardless of file types or structure.

## 🎯 Purpose

Automatically update Docker images to their latest **minor and patch** versions to address security vulnerabilities while avoiding breaking changes from major version updates.

## � Quick Start

### Option 1: GitHub Repository (Recommended)

1. **Copy the config to your repo:**
   ```bash
   curl -o renovate.json https://raw.githubusercontent.com/YOUR-ORG/renovate-docker-images/main/renovate.json
   ```

2. **Install Renovate GitHub App:**
   - Visit: https://github.com/apps/renovate
   - Click "Install"
   - Select your repositories

3. **That's it!** Renovate will:
   - Scan your repo automatically
   - Create PRs for image updates
   - Label them with `dependencies` and `security`

### Option 2: Self-Hosted Renovate

1. **Install Renovate:**
   ```bash
   npm install -g renovate
   ```

2. **Run it:**
   ```bash
   export RENOVATE_TOKEN="your_github_token"
   renovate your-org/your-repo
   ```

### Option 3: GitLab/Bitbucket

1. Copy `renovate.json` to the root of your repository
2. Configure Renovate for your platform
3. Follow platform-specific setup instructions

## 📦 Supported Images

| Image | Pattern | Versions | Constraint |
|-------|---------|----------|------------|
| **Datadog Agent** | `public.ecr.aws/datadog/agent:*` | 7.x only | Configured via `allowedVersions: "/^7\\./"`¹ |
| **AWS Fluent Bit** | `public.ecr.aws/aws-observability/aws-for-fluent-bit:*` | All stable | No version constraint |

¹ *Version constraint is configured in renovate.json, not a Renovate limitation*

## ⚙️ Configuration Features

### 1. Custom Managers (Regex-based Detection)

The configuration uses custom regex managers to detect Docker image references in multiple file types:
- ✅ YAML files (`.yml`, `.yaml`)
- ✅ Terraform files (`.tf`)
- ✅ JSON files (`.json`)
- ✅ Shell scripts (`.sh`)
- ✅ Dockerfiles (`Dockerfile*`)

### 2. Update Policies

- ✅ **Minor updates**: Enabled
- ✅ **Patch updates**: Enabled
- ❌ **Major updates**: Disabled (prevents breaking changes)

### 3. Version Constraints

**Datadog Agent:**
- Only version 7.x updates allowed (configurable via `allowedVersions`)
- Uses semantic versioning
- Examples: `7.50.0`, `7.51.2`

**AWS Fluent Bit:**
- Uses "loose" versioning to handle date-suffixed versions
- Examples: `2.31.12`, `2.31.12.20231222`

### 4. Security Features

- Vulnerability alerts enabled
- Automatic labeling with `dependencies` and `security` tags
- Groups updates by image type for easier review

### 5. Update Schedule

- **Default**: Weekly checks every Monday at 5 AM
- **Patch updates**: Automatically proposed (~weekly)
- **Minor updates**: Automatically proposed (~monthly)
- **Major updates**: ❌ Blocked (manual upgrade required)

## 🎯 What to Expect

### First Run

You'll see PRs like:

```
✅ Update Datadog Agent to 7.51.2
   📦 public.ecr.aws/datadog/agent:7.50.0 → 7.51.2
   🔒 Security fixes included

✅ Update AWS Fluent Bit to 2.32.0
   📦 public.ecr.aws/aws-observability/aws-for-fluent-bit:2.31.12 → 2.32.0
   🐛 Bug fixes and improvements
```

## 🧪 Testing

### Quick Validation

```bash
# Install validator
npm install -g renovate

# Validate config
renovate-config-validator renovate.json
```

### Local Dry Run

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_github_token"

# Run Renovate in dry-run mode (no changes)
renovate --dry-run --log-level=debug your-org/your-repo
```

### Using Docker

```bash
docker run --rm \
  -e RENOVATE_TOKEN=$GITHUB_TOKEN \
  -e LOG_LEVEL=debug \
  -v $(pwd)/renovate.json:/usr/src/app/renovate.json \
  renovate/renovate:latest \
  --dry-run \
  your-org/your-repo
```

### Create a Test Repository

```bash
# Create a test repo
mkdir renovate-test
cd renovate-test
git init

# Copy test files and config
cp -r ../examples/* .
cp ../renovate.json .

# Commit and push
git add .
git commit -m "Test Renovate configuration"
git remote add origin https://github.com/your-org/renovate-test.git
git push -u origin main
```

### Test Verification Checklist

- [ ] Configuration validates without errors
- [ ] Images detected in Terraform files (`.tf`)
- [ ] Images detected in Kubernetes manifests (`.yaml`, `.yml`)
- [ ] Images detected in Docker Compose files
- [ ] Images detected in JSON files
- [ ] Images detected in shell scripts (`.sh`)
- [ ] Images detected in Dockerfiles
- [ ] Only Datadog 7.x versions are proposed
- [ ] Major version updates are blocked
- [ ] Minor and patch updates are allowed
- [ ] PRs have proper labels (`dependencies`, `security`)

### Troubleshooting

**No images detected?**
```bash
# Check if regex patterns match your files
renovate --dry-run --log-level=trace | grep -i "matching"
```

**Wrong versions proposed?**
```bash
# Debug version filtering
renovate --dry-run --log-level=debug | grep -i "version"
```

**Too many PRs?**
Add rate limiting to `renovate.json`:
```json
{
  "prConcurrentLimit": 2,
  "prHourlyLimit": 1
}
```

## 🔧 Customization

### Adding More Images

Edit `renovate.json` and add a new custom manager block:

```json
{
  "customType": "regex",
  "description": "Your custom image",
  "fileMatch": ["^.*\\.ya?ml$", "^.*\\.tf$"],
  "matchStrings": [
    "(?<depName>your-registry\\.com/image):(?<currentValue>[A-Za-z0-9._-]+)"
  ],
  "datasourceTemplate": "docker",
  "versioningTemplate": "semver"
}
```

### Changing Update Schedule

Add to root level:

```json
{
  "schedule": ["before 5am on monday"]
}
```

Common schedules:
- `["every weekend"]`
- `["before 5am on monday"]`
- `["after 10pm every weekday"]`

### Enabling Auto-merge

Add to package rules:

```json
{
  "matchDatasources": ["docker"],
  "matchUpdateTypes": ["patch"],
  "automerge": true
}
```

### Modifying Version Constraints

To allow Datadog Agent versions beyond 7.x:

```json
{
  "matchPackageNames": ["public.ecr.aws/datadog/agent"],
  "allowedVersions": "/^[78]\\./",  // Allow 7.x and 8.x
}
```

Or remove the constraint entirely to allow all versions.

## 📁 File Structure

```
renovate-docker-images/
├── renovate.json                    # Main Renovate configuration
├── README.md                        # This file
└── examples/                        # Example files demonstrating image references
    ├── terraform/                   # ECS task definitions
    ├── kubernetes/                  # K8s deployments
    ├── docker/                      # Docker Compose & Dockerfiles
    ├── scripts/                     # Shell scripts
    └── json/                        # JSON configs
```

## 📊 Monitoring Renovate

### GitHub
- Visit: `https://github.com/YOUR-ORG/YOUR-REPO/issues`
- Look for: "Dependency Dashboard" issue

### Self-hosted
```bash
# Check logs
cat ~/.renovate/renovate.log
```

## 📝 Version Compatibility

- Renovate: v37.0.0+
- Works with: GitHub, GitLab, Bitbucket, Azure DevOps
- Node.js: 18+ (for local testing)

## 🛡️ Security Considerations

- Major version updates are disabled to prevent breaking changes
- All updates are grouped and labeled for easy review
- Vulnerability alerts are prioritized
- Consider enabling branch protection rules
- Review PRs before merging, especially for security-critical services

## 📚 Additional Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Custom Manager Documentation](https://docs.renovatebot.com/modules/manager/regex/)
- [Docker Datasource](https://docs.renovatebot.com/modules/datasource/docker/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)

## 🤝 Contributing

Feel free to open issues or PRs to improve this configuration!

## 📄 License

This configuration is provided as-is for use in any project.
