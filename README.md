# CI Checks

A collection of useful scripts for Continuous Integration (CI) pipelines to ensure code quality, security, and best practices.

## Scripts

### 1. security-check.sh

A comprehensive security testing script for Docker images, particularly designed for scratch-based images. This script performs various security checks to ensure your Docker containers follow security best practices.

#### Features

The script performs the following security checks:

1. **Shell Access Prevention** - Verifies that shell access (`/bin/sh`) is blocked
2. **Bash Access Prevention** - Ensures bash access (`/bin/bash`) is not possible
3. **Environment Variable Protection** - Checks that environment variables are not exposed
4. **Arbitrary Command Execution** - Tests if arbitrary commands can be executed
5. **Root User Check** - Warns if container runs as root (many applications do this)
6. **Sensitive Files Check** - Ensures sensitive system files (`/etc/passwd`, `/etc/shadow`) are not present
7. **Application Binary Verification** - Checks if the specified application binary is accessible and executable
8. **Image Size Analysis** - Reports the Docker image size
9. **CA Certificates** - Checks Dockerfile for CA certificates inclusion (important for scratch images)

#### Usage

```bash
./security-check.sh <image_name> [binary_path]
```

#### Parameters

- `image_name` (required): The Docker image name to test (e.g., `my-app:latest`)
- `binary_path` (optional): Path to the application binary inside the container (e.g., `/bin/app`)

#### Examples

```bash
# Basic security check
./security-check.sh my-server:latest

# Check with application binary
./security-check.sh my-server:latest /bin/app
```

#### Output

The script provides clear pass/fail indicators for each check:

- ✅ **PASS**: Security check passed
- ❌ **FAIL**: Security check failed
- ⚠️ **WARNING**: Non-critical issue detected
- 📦 **Image size**: Shows the Docker image size
- 🎉 **Success**: All checks passed
- ⚠️ **Warning**: Some checks failed

#### Exit Codes

- `0`: All security checks passed
- `1`: One or more security checks failed

#### Use Cases

- **CI/CD Pipelines**: Integrate into your build pipeline to ensure security compliance
- **Pre-deployment Testing**: Verify Docker images before deployment to production
- **Security Audits**: Regular security assessments of container images
- **Development Workflow**: Catch security issues early in development

#### Best Practices

This script is particularly useful for:

- **Scratch-based images**: Minimal images with no shell or unnecessary tools
- **Multi-stage builds**: Ensure final images are properly stripped
- **Production images**: Verify security hardening before deployment
- **Compliance requirements**: Meet security standards and regulations

#### Integration Examples

**GitHub Actions:**
```yaml
- name: Security Check
  run: |
    chmod +x ./security-check.sh
    ./security-check.sh ${{ steps.build.outputs.image }} /bin/app
```

**GitLab CI:**
```yaml
security_check:
  script:
    - chmod +x ./security-check.sh
    - ./security-check.sh $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA /bin/app
```

**Jenkins Pipeline:**
```groovy
stage('Security Check') {
    steps {
        sh 'chmod +x ./security-check.sh'
        sh './security-check.sh my-app:latest /bin/app'
    }
}
```

## Contributing

Feel free to contribute additional CI scripts or improvements to existing ones. Please ensure all scripts follow the same pattern of clear documentation and proper error handling.

## License

This project is licensed under the terms specified in the LICENSE file.
