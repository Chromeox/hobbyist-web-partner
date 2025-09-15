#!/usr/bin/env python3

"""
TestFlight Metadata Management System
Programmatically manages App Store Connect metadata, configuration files, and validation
"""

import json
import os
import sys
import argparse
import yaml
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
import subprocess
import requests

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('testflight-automation/logs/metadata-manager.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class MetadataManager:
    """Manages App Store Connect metadata operations"""
    
    def __init__(self, config_path: str = "testflight-automation/configs/automation-config.yml"):
        self.config_path = config_path
        self.config = self._load_config()
        self.bundle_id = self.config['project']['bundle_id']
        self.app_name = self.config['project']['name']
        
        # Paths
        self.metadata_dir = Path("fastlane/metadata")
        self.templates_dir = Path("testflight-automation/templates")
        self.logs_dir = Path("testflight-automation/logs")
        
        # Ensure directories exist
        self.metadata_dir.mkdir(parents=True, exist_ok=True)
        self.templates_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(parents=True, exist_ok=True)
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(self.config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {self.config_path}")
            sys.exit(1)
        except yaml.YAMLError as e:
            logger.error(f"Error parsing configuration file: {e}")
            sys.exit(1)
    
    def validate_metadata_fields(self, metadata: Dict[str, Any]) -> List[str]:
        """Validate required metadata fields"""
        required_fields = [
            'name',
            'subtitle',
            'description',
            'keywords',
            'marketing_url',
            'support_url',
            'privacy_policy_url'
        ]
        
        missing_fields = []
        for field in required_fields:
            if field not in metadata or not metadata[field]:
                missing_fields.append(field)
        
        # Validate description length
        if 'description' in metadata and len(metadata['description']) > 4000:
            missing_fields.append('description (too long, max 4000 characters)')
        
        # Validate keywords
        if 'keywords' in metadata:
            keywords_str = metadata['keywords'] if isinstance(metadata['keywords'], str) else ', '.join(metadata['keywords'])
            if len(keywords_str) > 100:
                missing_fields.append('keywords (too long, max 100 characters)')
        
        return missing_fields
    
    def create_metadata_template(self) -> Dict[str, Any]:
        """Create a metadata template with default values"""
        template = {
            'name': self.app_name,
            'subtitle': 'A SwiftUI booking application',
            'description': 'HobbyistSwiftUI is a comprehensive booking application built with SwiftUI.',
            'keywords': 'booking, swiftui, ios, app',
            'marketing_url': 'https://example.com',
            'support_url': 'https://example.com/support',
            'privacy_policy_url': 'https://example.com/privacy',
            'categories': {
                'primary': 'BUSINESS',
                'secondary': 'PRODUCTIVITY'
            },
            'rating': {
                'age_rating': '4+',
                'content_rights': {
                    'contains_third_party_content': False,
                    'has_rights': True
                }
            },
            'review_information': {
                'demo_account_name': '',
                'demo_account_password': '',
                'notes': 'Please test the main booking flow and user registration.'
            },
            'version_info': {
                'version': '1.0.0',
                'whats_new': 'Initial release with core booking functionality.'
            }
        }
        return template
    
    def generate_fastlane_metadata(self, metadata: Dict[str, Any]) -> None:
        """Generate Fastlane metadata files from metadata dictionary"""
        logger.info("Generating Fastlane metadata files...")
        
        # Create metadata directory structure
        locales = ['en-US']  # Add more locales as needed
        
        for locale in locales:
            locale_dir = self.metadata_dir / locale
            locale_dir.mkdir(parents=True, exist_ok=True)
            
            # Write metadata files
            metadata_files = {
                'name.txt': metadata.get('name', ''),
                'subtitle.txt': metadata.get('subtitle', ''),
                'description.txt': metadata.get('description', ''),
                'keywords.txt': metadata.get('keywords', ''),
                'marketing_url.txt': metadata.get('marketing_url', ''),
                'support_url.txt': metadata.get('support_url', ''),
                'privacy_policy_url.txt': metadata.get('privacy_policy_url', ''),
                'release_notes.txt': metadata.get('version_info', {}).get('whats_new', '')
            }
            
            for filename, content in metadata_files.items():
                file_path = locale_dir / filename
                with open(file_path, 'w') as f:
                    f.write(str(content))
                logger.debug(f"Created {file_path}")
        
        # Create app_store_information.json
        app_info = {
            'primary_category': metadata.get('categories', {}).get('primary', 'BUSINESS'),
            'secondary_category': metadata.get('categories', {}).get('secondary', 'PRODUCTIVITY'),
            'primary_subcategory_one': None,
            'primary_subcategory_two': None,
            'secondary_subcategory_one': None,
            'secondary_subcategory_two': None
        }
        
        with open(self.metadata_dir / 'app_store_information.json', 'w') as f:
            json.dump(app_info, f, indent=2)
        
        # Create review_information directory
        review_dir = self.metadata_dir / 'review_information'
        review_dir.mkdir(exist_ok=True)
        
        review_info = metadata.get('review_information', {})
        review_files = {
            'demo_user.txt': review_info.get('demo_account_name', ''),
            'demo_password.txt': review_info.get('demo_account_password', ''),
            'notes.txt': review_info.get('notes', '')
        }
        
        for filename, content in review_files.items():
            file_path = review_dir / filename
            with open(file_path, 'w') as f:
                f.write(str(content))
        
        logger.info("Fastlane metadata files generated successfully")
    
    def update_app_store_metadata(self, metadata: Dict[str, Any], dry_run: bool = True) -> bool:
        """Update App Store Connect metadata using Fastlane"""
        try:
            # Validate metadata first
            validation_errors = self.validate_metadata_fields(metadata)
            if validation_errors:
                logger.error(f"Metadata validation failed: {validation_errors}")
                return False
            
            # Generate Fastlane metadata files
            self.generate_fastlane_metadata(metadata)
            
            # Prepare fastlane command
            cmd = [
                'fastlane', 'deliver',
                '--app_identifier', self.bundle_id,
                '--skip_binary_upload',
                '--skip_screenshots',
                '--force'
            ]
            
            if dry_run:
                logger.info("DRY RUN: Would execute fastlane deliver command")
                logger.info(f"Command: {' '.join(cmd)}")
                return True
            else:
                logger.info("Updating App Store metadata...")
                result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
                
                if result.returncode == 0:
                    logger.info("App Store metadata updated successfully")
                    return True
                else:
                    logger.error(f"Failed to update metadata: {result.stderr}")
                    return False
                    
        except Exception as e:
            logger.error(f"Error updating App Store metadata: {e}")
            return False
    
    def fetch_current_metadata(self) -> Optional[Dict[str, Any]]:
        """Fetch current metadata from App Store Connect"""
        try:
            # Use fastlane to fetch current metadata
            cmd = [
                'fastlane', 'deliver',
                '--app_identifier', self.bundle_id,
                '--download_metadata',
                '--skip_binary_upload',
                '--skip_screenshots'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            if result.returncode == 0:
                logger.info("Current metadata fetched successfully")
                # Parse the downloaded metadata
                return self._parse_fastlane_metadata()
            else:
                logger.error(f"Failed to fetch metadata: {result.stderr}")
                return None
                
        except Exception as e:
            logger.error(f"Error fetching current metadata: {e}")
            return None
    
    def _parse_fastlane_metadata(self) -> Dict[str, Any]:
        """Parse Fastlane metadata files into dictionary"""
        metadata = {}
        locale_dir = self.metadata_dir / 'en-US'
        
        if locale_dir.exists():
            text_files = {
                'name': 'name.txt',
                'subtitle': 'subtitle.txt',
                'description': 'description.txt',
                'keywords': 'keywords.txt',
                'marketing_url': 'marketing_url.txt',
                'support_url': 'support_url.txt',
                'privacy_policy_url': 'privacy_policy_url.txt',
                'whats_new': 'release_notes.txt'
            }
            
            for key, filename in text_files.items():
                file_path = locale_dir / filename
                if file_path.exists():
                    with open(file_path, 'r') as f:
                        metadata[key] = f.read().strip()
        
        # Parse app store information
        app_info_path = self.metadata_dir / 'app_store_information.json'
        if app_info_path.exists():
            with open(app_info_path, 'r') as f:
                app_info = json.load(f)
                metadata['categories'] = {
                    'primary': app_info.get('primary_category'),
                    'secondary': app_info.get('secondary_category')
                }
        
        return metadata
    
    def create_metadata_backup(self) -> str:
        """Create a backup of current metadata"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_dir = Path(f"testflight-automation/backups/metadata_{timestamp}")
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy existing metadata files
        if self.metadata_dir.exists():
            import shutil
            shutil.copytree(self.metadata_dir, backup_dir / 'metadata', dirs_exist_ok=True)
            
        logger.info(f"Metadata backup created: {backup_dir}")
        return str(backup_dir)
    
    def validate_urls(self, metadata: Dict[str, Any]) -> List[str]:
        """Validate URLs in metadata"""
        invalid_urls = []
        url_fields = ['marketing_url', 'support_url', 'privacy_policy_url']
        
        for field in url_fields:
            if field in metadata and metadata[field]:
                url = metadata[field]
                try:
                    response = requests.head(url, timeout=10, allow_redirects=True)
                    if response.status_code >= 400:
                        invalid_urls.append(f"{field}: {url} (HTTP {response.status_code})")
                except requests.RequestException as e:
                    invalid_urls.append(f"{field}: {url} (Error: {str(e)})")
        
        return invalid_urls
    
    def generate_metadata_report(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Generate a comprehensive metadata report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'app_name': self.app_name,
            'bundle_id': self.bundle_id,
            'validation': {
                'required_fields': self.validate_metadata_fields(metadata),
                'invalid_urls': self.validate_urls(metadata)
            },
            'statistics': {
                'description_length': len(metadata.get('description', '')),
                'keywords_length': len(metadata.get('keywords', '')),
                'subtitle_length': len(metadata.get('subtitle', ''))
            },
            'metadata': metadata
        }
        
        # Save report
        report_path = self.logs_dir / f"metadata_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Metadata report saved: {report_path}")
        return report

def main():
    parser = argparse.ArgumentParser(description='TestFlight Metadata Management System')
    parser.add_argument('--config', default='testflight-automation/configs/automation-config.yml',
                       help='Configuration file path')
    parser.add_argument('--action', required=True,
                       choices=['create-template', 'update', 'fetch', 'validate', 'backup', 'report'],
                       help='Action to perform')
    parser.add_argument('--metadata-file', help='JSON file with metadata to update')
    parser.add_argument('--dry-run', action='store_true', help='Perform dry run without making changes')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    manager = MetadataManager(args.config)
    
    if args.action == 'create-template':
        template = manager.create_metadata_template()
        template_path = 'testflight-automation/templates/metadata-template.json'
        with open(template_path, 'w') as f:
            json.dump(template, f, indent=2)
        print(f"Metadata template created: {template_path}")
    
    elif args.action == 'update':
        if not args.metadata_file:
            logger.error("--metadata-file is required for update action")
            sys.exit(1)
        
        with open(args.metadata_file, 'r') as f:
            metadata = json.load(f)
        
        success = manager.update_app_store_metadata(metadata, dry_run=args.dry_run)
        sys.exit(0 if success else 1)
    
    elif args.action == 'fetch':
        metadata = manager.fetch_current_metadata()
        if metadata:
            output_path = 'testflight-automation/metadata-current.json'
            with open(output_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            print(f"Current metadata saved: {output_path}")
        else:
            sys.exit(1)
    
    elif args.action == 'validate':
        if not args.metadata_file:
            logger.error("--metadata-file is required for validate action")
            sys.exit(1)
        
        with open(args.metadata_file, 'r') as f:
            metadata = json.load(f)
        
        validation_errors = manager.validate_metadata_fields(metadata)
        url_errors = manager.validate_urls(metadata)
        
        if validation_errors or url_errors:
            print("Validation failed:")
            for error in validation_errors:
                print(f"  - Missing/invalid field: {error}")
            for error in url_errors:
                print(f"  - URL error: {error}")
            sys.exit(1)
        else:
            print("✅ Metadata validation passed")
    
    elif args.action == 'backup':
        backup_path = manager.create_metadata_backup()
        print(f"Backup created: {backup_path}")
    
    elif args.action == 'report':
        if not args.metadata_file:
            # Use current metadata if no file specified
            metadata = manager.fetch_current_metadata()
            if not metadata:
                logger.error("Could not fetch current metadata")
                sys.exit(1)
        else:
            with open(args.metadata_file, 'r') as f:
                metadata = json.load(f)
        
        report = manager.generate_metadata_report(metadata)
        print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()