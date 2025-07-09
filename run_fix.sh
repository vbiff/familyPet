#!/bin/bash

# Script to fix new user family assignment issue
# This runs the SQL fix directly on your Supabase database

echo "🔧 Fixing new user family assignment issue..."
echo "This will:"
echo "1. Check current database state"
echo "2. Find and fix incorrectly assigned users"
echo "3. Update the auth trigger to prevent future issues"
echo ""

# Check if we have the Supabase CLI available
if command -v supabase &> /dev/null; then
    echo "📡 Running fix via Supabase CLI..."
    supabase db reset --db-url "$DB_URL" --file fix_new_user_family_assignment.sql
else
    echo "❌ Supabase CLI not available"
    echo "📋 Please run the SQL script manually in your Supabase dashboard:"
    echo "   1. Go to your Supabase project dashboard"
    echo "   2. Navigate to SQL Editor"
    echo "   3. Copy and paste the contents of fix_new_user_family_assignment.sql"
    echo "   4. Run the script"
    echo ""
    echo "📁 The SQL file is located at: $(pwd)/fix_new_user_family_assignment.sql"
fi 