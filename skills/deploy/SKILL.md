---
name: deploy
description: Template skill for deployment workflows. Customize this skill with your specific deployment commands, environments, and verification steps.
---

# Deploy (Template)

This is a template. Customize for your deployment process.

## Example Structure

```markdown
Deploy to $0:

1. Verify: `npm test && git status`
2. Build: `npm run build`
3. Deploy: `./scripts/deploy.sh $0`
4. Verify: `curl -f https://$0.example.com/health`
```

## Customization

Replace the example with your actual:
- Test commands
- Build process
- Deploy mechanism (SSH, cloud CLI, container push)
- Health check endpoints
- Rollback procedure
