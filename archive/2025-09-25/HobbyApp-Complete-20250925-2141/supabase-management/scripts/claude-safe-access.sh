#!/bin/bash

# Safe Supabase Access Script for Claude
# This provides limited, safe operations that Claude can perform

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Load environment if exists
if [ -f "$CONFIG_DIR/.env.local" ]; then
    source "$CONFIG_DIR/.env.local"
fi

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function print_usage() {
    echo "Safe Supabase Operations for Claude"
    echo "===================================="
    echo ""
    echo "READ OPERATIONS (always safe):"
    echo "  list-tables              - List all tables in the database"
    echo "  show-schema <table>      - Show schema for a specific table"
    echo "  show-migrations          - List migration files"
    echo "  show-functions           - List Edge Functions"
    echo "  test-connection          - Test Supabase connection"
    echo "  get-project-info         - Get project configuration"
    echo ""
    echo "DEVELOPMENT OPERATIONS (safe in dev):"
    echo "  apply-migration <file>   - Apply a specific migration"
    echo "  deploy-function <name>   - Deploy an Edge Function"
    echo "  run-seed                 - Run seed data (dev only)"
    echo "  generate-types           - Generate TypeScript types"
    echo ""
    echo "BACKUP OPERATIONS:"
    echo "  backup-schema            - Backup database schema"
    echo "  backup-data <table>      - Backup specific table data"
    echo ""
    echo "Usage: $0 <command> [args]"
}

# Check for command
if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

case "$1" in
    # Safe read operations
    "list-tables")
        echo -e "${GREEN}Listing all tables...${NC}"
        if [ ! -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
            curl -s "$SUPABASE_URL/rest/v1/" \
                -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
                -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
                -H "Accept: application/vnd.pgrst.object+json" | \
                python3 -m json.tool 2>/dev/null || echo "Failed to list tables"
        else
            echo "Service role key required for this operation"
        fi
        ;;
    
    "show-schema")
        if [ -z "$2" ]; then
            echo "Please specify a table name"
            exit 1
        fi
        echo -e "${GREEN}Showing schema for table: $2${NC}"
        curl -s "$SUPABASE_URL/rest/v1/$2?limit=0" \
            -H "apikey: $SUPABASE_ANON_KEY" \
            -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
            -H "Prefer: count=exact" -I 2>/dev/null | grep -E "Content-Range|Content-Type"
        ;;
    
    "show-migrations")
        echo -e "${GREEN}Listing migration files...${NC}"
        MIGRATIONS_DIR="$SCRIPT_DIR/../../supabase/migrations"
        if [ -d "$MIGRATIONS_DIR" ]; then
            ls -la "$MIGRATIONS_DIR"/*.sql 2>/dev/null || echo "No migrations found"
        else
            echo "Migrations directory not found"
        fi
        ;;
    
    "show-functions")
        echo -e "${GREEN}Listing Edge Functions...${NC}"
        FUNCTIONS_DIR="$SCRIPT_DIR/../../supabase/functions"
        if [ -d "$FUNCTIONS_DIR" ]; then
            ls -d "$FUNCTIONS_DIR"/*/ 2>/dev/null | xargs -n 1 basename || echo "No functions found"
        else
            echo "Functions directory not found"
        fi
        ;;
    
    "test-connection")
        echo -e "${GREEN}Testing Supabase connection...${NC}"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            "$SUPABASE_URL/rest/v1/" \
            -H "apikey: $SUPABASE_ANON_KEY" \
            -H "Authorization: Bearer $SUPABASE_ANON_KEY")
        
        if [ "$RESPONSE" = "200" ]; then
            echo -e "${GREEN}✅ Connection successful${NC}"
            echo "Project URL: $SUPABASE_URL"
        else
            echo -e "${RED}❌ Connection failed (HTTP $RESPONSE)${NC}"
        fi
        ;;
    
    "get-project-info")
        echo -e "${GREEN}Getting project information...${NC}"
        if [ ! -z "$SUPABASE_ACCESS_TOKEN" ] && command -v supabase &> /dev/null; then
            supabase projects get "$SUPABASE_PROJECT_ID" --token "$SUPABASE_ACCESS_TOKEN" 2>/dev/null || \
                echo "Failed to get project info. Check your access token."
        else
            echo "Project ID: ${SUPABASE_PROJECT_ID:-Not set}"
            echo "Project URL: ${SUPABASE_URL:-Not set}"
            echo ""
            echo "Note: Install Supabase CLI and set SUPABASE_ACCESS_TOKEN for more details"
        fi
        ;;
    
    # Development operations
    "apply-migration")
        if [ "$NODE_ENV" != "development" ]; then
            echo -e "${RED}This operation is only allowed in development${NC}"
            exit 1
        fi
        
        if [ -z "$2" ]; then
            echo "Please specify a migration file"
            exit 1
        fi
        
        echo -e "${YELLOW}Applying migration: $2${NC}"
        if command -v supabase &> /dev/null && [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
            supabase db push --project-id "$SUPABASE_PROJECT_ID" --token "$SUPABASE_ACCESS_TOKEN"
        else
            echo "Supabase CLI and access token required for this operation"
        fi
        ;;
    
    "deploy-function")
        if [ -z "$2" ]; then
            echo "Please specify a function name"
            exit 1
        fi
        
        echo -e "${YELLOW}Deploying function: $2${NC}"
        if command -v supabase &> /dev/null && [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
            supabase functions deploy "$2" \
                --project-id "$SUPABASE_PROJECT_ID" \
                --token "$SUPABASE_ACCESS_TOKEN"
        else
            echo "Supabase CLI and access token required for this operation"
        fi
        ;;
    
    "run-seed")
        if [ "$NODE_ENV" != "development" ]; then
            echo -e "${RED}This operation is only allowed in development${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Running seed data...${NC}"
        SEED_FILE="$SCRIPT_DIR/../../supabase/seed.sql"
        if [ -f "$SEED_FILE" ]; then
            if command -v supabase &> /dev/null && [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
                supabase db seed --project-id "$SUPABASE_PROJECT_ID" --token "$SUPABASE_ACCESS_TOKEN"
            else
                echo "Supabase CLI and access token required for this operation"
            fi
        else
            echo "Seed file not found at $SEED_FILE"
        fi
        ;;
    
    "generate-types")
        echo -e "${GREEN}Generating TypeScript types...${NC}"
        if command -v supabase &> /dev/null && [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
            supabase gen types typescript \
                --project-id "$SUPABASE_PROJECT_ID" \
                --token "$SUPABASE_ACCESS_TOKEN" \
                > "$SCRIPT_DIR/../../types/supabase.generated.ts"
            echo "Types generated at types/supabase.generated.ts"
        else
            echo "Supabase CLI and access token required for this operation"
        fi
        ;;
    
    # Backup operations
    "backup-schema")
        echo -e "${GREEN}Backing up database schema...${NC}"
        BACKUP_DIR="$SCRIPT_DIR/../backups"
        mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        if command -v supabase &> /dev/null && [ ! -z "$SUPABASE_ACCESS_TOKEN" ]; then
            supabase db dump \
                --project-id "$SUPABASE_PROJECT_ID" \
                --token "$SUPABASE_ACCESS_TOKEN" \
                --schema-only \
                > "$BACKUP_DIR/schema_${TIMESTAMP}.sql"
            echo "Schema backed up to: $BACKUP_DIR/schema_${TIMESTAMP}.sql"
        else
            echo "Supabase CLI and access token required for this operation"
        fi
        ;;
    
    "backup-data")
        if [ -z "$2" ]; then
            echo "Please specify a table name"
            exit 1
        fi
        
        echo -e "${GREEN}Backing up data for table: $2${NC}"
        BACKUP_DIR="$SCRIPT_DIR/../backups"
        mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        curl -s "$SUPABASE_URL/rest/v1/$2" \
            -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
            -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
            -H "Accept: application/json" \
            > "$BACKUP_DIR/${2}_data_${TIMESTAMP}.json"
        
        echo "Data backed up to: $BACKUP_DIR/${2}_data_${TIMESTAMP}.json"
        ;;
    
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac