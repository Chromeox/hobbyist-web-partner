#!/bin/bash

# Comprehensive Supabase Management Script
# For managing both HobbyistSwiftUI and TeeStack projects

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Load environment
if [ -f "$CONFIG_DIR/.env.local" ]; then
    source "$CONFIG_DIR/.env.local"
else
    echo "❌ Configuration not found. Run ./supabase-setup.sh first"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

function print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

function print_usage() {
    print_header "Supabase Management Tool"
    
    echo "Commands:"
    echo ""
    echo "  Project Management:"
    echo "    status                 - Show project status"
    echo "    link <project-id>      - Link to a project"
    echo "    switch <hobbyist|teestack> - Switch between projects"
    echo ""
    echo "  Database Operations:"
    echo "    migrate                - Apply pending migrations"
    echo "    reset                  - Reset database (CAUTION!)"
    echo "    seed                   - Run seed data"
    echo "    backup                 - Create full backup"
    echo ""
    echo "  Edge Functions:"
    echo "    functions list         - List all functions"
    echo "    functions deploy <name> - Deploy specific function"
    echo "    functions deploy-all   - Deploy all functions"
    echo "    functions logs <name>  - View function logs"
    echo ""
    echo "  Development:"
    echo "    types                  - Generate TypeScript types"
    echo "    local start           - Start local development"
    echo "    local stop            - Stop local development"
    echo ""
    echo "Usage: $0 <command> [args]"
}

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not installed${NC}"
    echo ""
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

# Determine which project to use
PROJECT_ID="${SUPABASE_PROJECT_ID}"
if [ ! -z "$2" ]; then
    case "$2" in
        "hobbyist")
            PROJECT_ID="${HOBBYIST_PROJECT_ID:-$SUPABASE_PROJECT_ID}"
            echo -e "${GREEN}Using HobbyistSwiftUI project${NC}"
            ;;
        "teestack")
            PROJECT_ID="${TEESTACK_PROJECT_ID:-$SUPABASE_PROJECT_ID}"
            echo -e "${GREEN}Using TeeStack project${NC}"
            ;;
    esac
fi

case "$1" in
    "status")
        print_header "Project Status"
        # Ensure we're linked to the correct project
        if [ ! -z "$PROJECT_ID" ]; then
            supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
        fi
        supabase status
        ;;
    
    "link")
        if [ -z "$2" ]; then
            echo "Please specify a project ID"
            exit 1
        fi
        print_header "Linking Project"
        supabase link --project-ref "$2"
        ;;
    
    "migrate")
        print_header "Applying Migrations"
        # First ensure we're linked to the correct project
        if [ ! -z "$PROJECT_ID" ]; then
            echo "Linking to project: $PROJECT_ID"
            supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
        fi
        # Use the --linked flag for remote project
        supabase db push --linked
        ;;
    
    "reset")
        print_header "Database Reset"
        echo -e "${RED}⚠️  WARNING: This will delete all data!${NC}"
        read -p "Are you sure? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            # Ensure we're linked to the correct project
            if [ ! -z "$PROJECT_ID" ]; then
                supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
            fi
            supabase db reset --linked
        fi
        ;;
    
    "seed")
        print_header "Running Seed Data"
        # Ensure we're linked to the correct project
        if [ ! -z "$PROJECT_ID" ]; then
            supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
        fi
        supabase seed
        ;;
    
    "backup")
        print_header "Creating Backup"
        BACKUP_DIR="$SCRIPT_DIR/../backups"
        mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        # Ensure we're linked to the correct project
        if [ ! -z "$PROJECT_ID" ]; then
            supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
        fi
        
        echo "Creating schema backup..."
        supabase db dump --linked > "$BACKUP_DIR/backup_${PROJECT_ID}_${TIMESTAMP}.sql"
        
        echo -e "${GREEN}✅ Backup created: $BACKUP_DIR/backup_${PROJECT_ID}_${TIMESTAMP}.sql${NC}"
        ;;
    
    "functions")
        case "$2" in
            "list")
                print_header "Edge Functions"
                # Ensure we're linked to the correct project
                if [ ! -z "$PROJECT_ID" ]; then
                    supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
                fi
                supabase functions list --linked || ls -d supabase/functions/*/ 2>/dev/null | xargs -n 1 basename
                ;;
            
            "deploy")
                if [ -z "$3" ]; then
                    echo "Please specify a function name"
                    exit 1
                fi
                print_header "Deploying Function: $3"
                # Ensure we're linked to the correct project
                if [ ! -z "$PROJECT_ID" ]; then
                    supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
                fi
                supabase functions deploy "$3" --linked
                ;;
            
            "deploy-all")
                print_header "Deploying All Functions"
                # Ensure we're linked to the correct project
                if [ ! -z "$PROJECT_ID" ]; then
                    supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
                fi
                for func in supabase/functions/*/; do
                    if [ -d "$func" ] && [ "$(basename $func)" != "_shared" ]; then
                        FUNC_NAME=$(basename "$func")
                        echo -e "${YELLOW}Deploying: $FUNC_NAME${NC}"
                        supabase functions deploy "$FUNC_NAME" --linked
                    fi
                done
                ;;
            
            "logs")
                if [ -z "$3" ]; then
                    echo "Please specify a function name"
                    exit 1
                fi
                print_header "Function Logs: $3"
                # Ensure we're linked to the correct project
                if [ ! -z "$PROJECT_ID" ]; then
                    supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
                fi
                supabase functions logs "$3" --linked
                ;;
            
            *)
                echo "Unknown functions command: $2"
                echo "Available: list, deploy <name>, deploy-all, logs <name>"
                ;;
        esac
        ;;
    
    "types")
        print_header "Generating TypeScript Types"
        OUTPUT_FILE="$SCRIPT_DIR/../../types/supabase.generated.ts"
        mkdir -p "$(dirname "$OUTPUT_FILE")"
        
        # Ensure we're linked to the correct project
        if [ ! -z "$PROJECT_ID" ]; then
            supabase link --project-ref "$PROJECT_ID" 2>/dev/null || true
        fi
        
        supabase gen types typescript --linked > "$OUTPUT_FILE"
        
        echo -e "${GREEN}✅ Types generated: $OUTPUT_FILE${NC}"
        ;;
    
    "local")
        case "$2" in
            "start")
                print_header "Starting Local Development"
                supabase start
                ;;
            "stop")
                print_header "Stopping Local Development"
                supabase stop
                ;;
            *)
                echo "Unknown local command: $2"
                echo "Available: start, stop"
                ;;
        esac
        ;;
    
    *)
        if [ ! -z "$1" ]; then
            echo -e "${RED}Unknown command: $1${NC}"
        fi
        print_usage
        ;;
esac