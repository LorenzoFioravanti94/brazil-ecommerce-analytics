## Description
<prefix>: feature/, refactor/, docs/, bugfix/, hotfix/

TARGET BRANCH | <prefix> | <Layer> | <optional: Sublayer> | <description>

## Checklist

**PR from `feature/` → `develop`**
- [ ] Before opening this PR, I ran:
  ```
  git checkout feature/<feature_name>
  git add .
  git commit -m "feat: descrizione modifica"
  git fetch origin
  git rebase origin/main
  git push --force-with-lease origin feature/<feature_name>
  ```

**PR from `develop` → `main`**
- [ ] Before opening this PR, I ran:
  ```
  git checkout develop
  git pull origin develop
  ```