#!/bin/bash

# Script to remove Firebase API keys from git history
# WARNING: This rewrites git history. Only run this if you understand the implications.
# After running this, you'll need to force push: git push --force origin main

echo "⚠️  WARNING: This script will rewrite git history!"
echo "This will remove firebase_options.dart files from all commits."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Removing firebase_options.dart files from git history..."
echo "This may take a while..."

# Remove files from git history using git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch driver-app/lib/firebase_options.dart user-app/lib/firebase_options.dart" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "✅ Done! Git history has been rewritten."
echo ""
echo "Next steps:"
echo "1. Review the changes: git log --all"
echo "2. Force push to update remote: git push --force origin main"
echo "3. Inform all team members to re-clone the repository"
echo ""
echo "⚠️  IMPORTANT: All team members must:"
echo "   - Re-clone the repository OR"
echo "   - Run: git fetch origin && git reset --hard origin/main"
echo ""
echo "⚠️  Also remember to:"
echo "   - Regenerate the exposed API keys in Google Cloud Console"
echo "   - Update firebase_options.dart locally with new keys"

