# Contributing to File Converter

First off, thank you for considering contributing to File Converter! It's people like you that make this tool better for everyone.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When reporting a bug, include:**
- Your Windows version
- PowerShell version (`$PSVersionTable.PSVersion`)
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if applicable
- Error messages (copy the full text)

### 💡 Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature has already been suggested
- Provide a clear description of the feature
- Explain why this feature would be useful
- Include examples of how it would work

### 🔧 Pull Requests

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature: `git checkout -b feature/my-feature`
4. **Make changes** following our coding standards
5. **Test** your changes thoroughly
6. **Commit** with clear messages: `git commit -m "Add: brief description"`
7. **Push** to your fork: `git push origin feature/my-feature`
8. **Open a Pull Request** with a clear description

## Development Guidelines

### PowerShell Coding Standards

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing code style
- Use `Write-Host` with appropriate colors for user feedback
- Handle errors gracefully with try/catch blocks
- Test on Windows 10 and 11

### File Structure

```
scripts/
├── convert-*.ps1    # Conversion scripts
└── compress-*.ps1   # Compression scripts
```

### Adding New Formats

To add a new format:

1. Update the appropriate `$formatosEntrada` array
2. Add entry to `$formatosSalida` hashtable
3. Update `Show-*Formats` function if needed
4. Test the conversion/compression
5. Update README.md with new format

### Commit Messages

Use clear, descriptive commit messages:

- `Add: new feature description`
- `Fix: bug description`
- `Update: what was updated`
- `Docs: documentation changes`
- `Refactor: code refactoring`

## Testing

Before submitting a PR:

1. Test with various file formats
2. Test all compression levels
3. Verify error handling works correctly
4. Check that file counts display correctly
5. Test on a fresh Windows installation if possible

## Questions?

Feel free to open an issue with your question or reach out to the maintainer.

---

Thank you for contributing! 🎉
