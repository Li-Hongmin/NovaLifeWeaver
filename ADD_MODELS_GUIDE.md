# Add Model Files to Xcode Project

## Problem
The Model files exist in `/Models/` directory but are not part of the Xcode project, causing build errors.

## Solution: Add Files to Xcode Project

### Option 1: Using Xcode GUI (Recommended)

1. **Open Project in Xcode**
   ```bash
   open NovaLifeWeaver.xcodeproj
   ```

2. **Add Models Group**
   - In Project Navigator, right-click on "NovaLifeWeaver" folder
   - Select "New Group"
   - Name it "Models"

3. **Add Model Files**
   - Right-click on the "Models" group
   - Select "Add Files to NovaLifeWeaver..."
   - Navigate to the `/Models/` directory (one level up from project)
   - Select all `.swift` files:
     - User.swift
     - Goal.swift
     - Habit.swift
     - FinancialRecord.swift
     - EmotionRecord.swift
     - Event.swift
     - Insight.swift
     - Correlation.swift
     - UserContext.swift
   - **IMPORTANT**: Check "Copy items if needed"
   - **IMPORTANT**: Check "Add to targets: NovaLifeWeaver"
   - Click "Add"

4. **Verify**
   - Build the project (⌘+B)
   - Should compile successfully

### Option 2: Move Files into Xcode Project Directory

Run this script to copy model files:

```bash
# From project root
mkdir -p NovaLifeWeaver/NovaLifeWeaver/Models
cp Models/*.swift NovaLifeWeaver/NovaLifeWeaver/Models/
```

Then follow Option 1 steps 2-4 to add them to Xcode.

### Option 3: Fix Protocols Directory Structure

The DatabaseProtocol.swift also needs to be added:

```bash
# Check if Protocols directory exists in project
ls NovaLifeWeaver/NovaLifeWeaver/Protocols/

# If not, copy it
mkdir -p NovaLifeWeaver/NovaLifeWeaver/Protocols
cp Protocols/*.swift NovaLifeWeaver/NovaLifeWeaver/Protocols/
```

## After Adding Files

Build should succeed:
```bash
xcodebuild -scheme NovaLifeWeaver -configuration Debug build
```

## Quick Fix Script

Run this to set up the entire structure:

```bash
#!/bin/bash
set -e

echo "📦 Setting up Model files in Xcode project..."

# Create directories
mkdir -p NovaLifeWeaver/NovaLifeWeaver/Models
mkdir -p NovaLifeWeaver/NovaLifeWeaver/Protocols

# Copy files
cp Models/*.swift NovaLifeWeaver/NovaLifeWeaver/Models/ 2>/dev/null || echo "Models already exist"
cp Protocols/*.swift NovaLifeWeaver/NovaLifeWeaver/Protocols/ 2>/dev/null || echo "Protocols already exist"
cp Services/*.swift NovaLifeWeaver/NovaLifeWeaver/Services/ 2>/dev/null || echo "Services already exist"

echo "✅ Files copied. Now:"
echo "1. Open NovaLifeWeaver.xcodeproj in Xcode"
echo "2. Right-click 'NovaLifeWeaver' folder → Add Files"
echo "3. Select Models/ and Protocols/ folders"
echo "4. Check 'Copy items if needed' and 'Add to targets'"
echo "5. Build (⌘+B)"
```

Save this as `setup_models.sh`, make it executable, and run it.
