# Git Pre-Push Hooks Documentation

This project includes automated pre-push hooks to ensure code quality before pushing to GitHub.

## 🎯 What Gets Checked

Before every `git push`, the following checks run automatically:

1. **RSpec Tests** - All test specs must pass
2. **RuboCop Linting** - Code style must comply with Ruby standards
3. **Brakeman Security Scan** - No security vulnerabilities allowed

## ✅ Hook is Already Installed

The pre-push hook is located at:

```
.git/hooks/pre-push
```

It runs automatically every time you push code.

## 🚀 Usage

### Normal Push (Full Checks)

```bash
git push origin main
```

This will:

- ✅ Run all RSpec tests
- ✅ Run RuboCop on entire codebase
- ✅ Run full Brakeman security scan

**Expected output:**

```
🔍 Running pre-push checks...

📝 Running RSpec tests...
✅ All tests passed!

🔧 Running RuboCop linting...
✅ RuboCop checks passed!

🔒 Running Brakeman security scan...
✅ No security vulnerabilities found!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL PRE-PUSH CHECKS PASSED!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Proceeding with push...
```

### If Checks Fail

If any check fails, the push will be **blocked**:

```
❌ PRE-PUSH CHECKS FAILED!

Please fix the issues above before pushing.

To skip these checks (NOT RECOMMENDED), use:
  git push --no-verify
```

**What to do:**

1. Fix the failing tests/linting/security issues
2. Commit your fixes
3. Try pushing again

## ⚡ Fast Mode (Optional)

For quick pushes when you're confident, you can use the fast version:

### Enable Fast Mode

```bash
# Temporarily use fast checks
cp .git/hooks/pre-push.fast .git/hooks/pre-push
```

### Restore Full Checks

```bash
# Restore full checks
git checkout .git/hooks/pre-push
```

**Fast mode only checks:**

- Changed spec files (not all tests)
- Changed Ruby files (not entire codebase)
- Quick Brakeman scan

## 🔧 Manual Checks (Without Pushing)

Run checks manually before committing:

```bash
# Run all checks
bundle exec rspec && bundle exec rubocop && bundle exec brakeman

# Run individually
bundle exec rspec                    # Tests only
bundle exec rubocop                  # Linting only
bundle exec brakeman                 # Security only
```

## 🚫 Bypassing Checks (Emergency Only)

**⚠️ NOT RECOMMENDED** - Only use in emergencies:

```bash
git push --no-verify
```

This skips all pre-push checks. Use only when:

- You're pushing a hotfix
- Checks are failing due to infrastructure issues
- You're absolutely certain the code is safe

## 🛠️ Fixing Common Issues

### RSpec Failures

```bash
# Run tests to see what's failing
bundle exec rspec

# Run specific failing test
bundle exec rspec spec/path/to/failing_spec.rb
```

### RuboCop Issues

```bash
# Auto-fix most style issues
bundle exec rubocop --autocorrect-all

# See what can't be auto-fixed
bundle exec rubocop
```

### Brakeman Warnings

```bash
# See detailed security report
bundle exec brakeman

# Generate HTML report
bundle exec brakeman -o brakeman_report.html
```

## 📊 Hook Performance

**Full checks typically take:**

- RSpec: ~5-10 seconds
- RuboCop: ~2-3 seconds
- Brakeman: ~3-5 seconds
- **Total: ~10-18 seconds**

**Fast mode typically takes:**

- Changed specs: ~1-3 seconds
- Changed files linting: ~1 second
- Quick security scan: ~2 seconds
- **Total: ~4-6 seconds**

## 🔄 Updating the Hook

If you need to modify the hook:

```bash
# Edit the hook
nano .git/hooks/pre-push

# Make sure it's executable
chmod +x .git/hooks/pre-push
```

## 📝 Best Practices

1. **Run checks locally before committing**

   ```bash
   bundle exec rspec && bundle exec rubocop --autocorrect-all
   ```

2. **Fix issues incrementally**

   - Don't let linting issues pile up
   - Write tests as you code
   - Run Brakeman regularly

3. **Use meaningful commit messages**

   ```bash
   git commit -m "Add weather caching feature with tests"
   ```

4. **Keep the main branch clean**
   - Never use `--no-verify` on main branch
   - Always ensure all checks pass

## 🎓 Why Pre-Push Hooks?

**Benefits:**

- ✅ Prevents broken code from reaching GitHub
- ✅ Maintains code quality standards
- ✅ Catches security issues early
- ✅ Ensures tests always pass
- ✅ Enforces consistent code style
- ✅ Saves time in code reviews

**Team Benefits:**

- No broken builds on main branch
- Consistent code quality
- Faster code reviews
- Fewer bugs in production

## 🆘 Troubleshooting

### Hook not running?

```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-push

# Make it executable
chmod +x .git/hooks/pre-push
```

### Hook running but not blocking push?

Check the exit code in the hook script. It should `exit 1` on failure.

### Want to disable temporarily?

```bash
# Rename the hook
mv .git/hooks/pre-push .git/hooks/pre-push.disabled

# Re-enable later
mv .git/hooks/pre-push.disabled .git/hooks/pre-push
```

## 📚 Additional Resources

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [RSpec Best Practices](https://rspec.info/)
- [RuboCop Documentation](https://rubocop.org/)
- [Brakeman Security Scanner](https://brakemanscanner.org/)

---

**Remember:** These checks exist to help you ship better code! 🚀
