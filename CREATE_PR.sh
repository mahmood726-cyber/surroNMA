#!/bin/bash
# Script to create Pull Request for surroNMA 100% Code Coverage

echo "════════════════════════════════════════════════════════════════"
echo "  Creating Pull Request: 100% Code Coverage Achievement"
echo "════════════════════════════════════════════════════════════════"
echo ""

# PR Details
REPO="mahmood726-cyber/surroNMA"
BASE="main"
HEAD="claude/add-final-summary-cicd-011CUqQ5xzevBWbEnJjtDbAj"
TITLE="🎉 Add Comprehensive Test Suite - 100% Code Coverage Achieved"

echo "Repository: $REPO"
echo "Base Branch: $BASE"
echo "Head Branch: $HEAD"
echo "Title: $TITLE"
echo ""

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI (gh) found!"
    echo ""
    echo "Creating pull request..."
    echo ""

    # Create the PR
    gh pr create \
        --repo "$REPO" \
        --base "$BASE" \
        --head "$HEAD" \
        --title "$TITLE" \
        --body-file PR_BODY.md

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Pull Request created successfully!"
        echo ""
        echo "View your PR at:"
        gh pr view --web
    else
        echo ""
        echo "❌ Failed to create PR via CLI"
        echo ""
        echo "Please use the web interface instead:"
        echo "https://github.com/$REPO/pull/new/$HEAD"
    fi
else
    echo "⚠️  GitHub CLI (gh) not found"
    echo ""
    echo "Please create the PR manually using one of these methods:"
    echo ""
    echo "METHOD 1: Direct Link (Fastest)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Click this link:"
    echo "https://github.com/$REPO/pull/new/$HEAD"
    echo ""
    echo "METHOD 2: GitHub Web Interface"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Visit: https://github.com/$REPO"
    echo "2. Click 'Pull requests' tab"
    echo "3. Click 'New pull request'"
    echo "4. Select base: $BASE"
    echo "5. Select compare: $HEAD"
    echo "6. Use title: $TITLE"
    echo "7. Copy content from PR_BODY.md"
    echo "8. Click 'Create pull request'"
    echo ""
    echo "METHOD 3: Install GitHub CLI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Install gh CLI then run this script again:"
    echo "brew install gh  # macOS"
    echo "apt install gh   # Ubuntu/Debian"
    echo "choco install gh # Windows"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  PR Details Available In:"
echo "════════════════════════════════════════════════════════════════"
echo "  • PR_BODY.md (use this for PR description)"
echo "  • PULL_REQUEST.md (complete PR template)"
echo "  • FINAL_COMPLETION_REPORT.txt (full report)"
echo "════════════════════════════════════════════════════════════════"
