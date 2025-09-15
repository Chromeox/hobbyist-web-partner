#!/usr/bin/env python3

"""
TestFlight Testing Group Management System
Handles internal and external testing groups, tester invitations, and build distribution
"""

import json
import os
import sys
import argparse
import yaml
import logging
import csv
import subprocess
import requests
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('testflight-automation/logs/testing-group-manager.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class TestingGroupManager:
    """Manages TestFlight testing groups and tester invitations"""
    
    def __init__(self, config_path: str = "testflight-automation/configs/automation-config.yml"):
        self.config_path = config_path
        self.config = self._load_config()
        self.bundle_id = self.config['project']['bundle_id']
        self.app_name = self.config['project']['name']
        
        # Paths
        self.logs_dir = Path("testflight-automation/logs")
        self.templates_dir = Path("testflight-automation/templates")
        self.testers_dir = Path("testflight-automation/testers")
        
        # Ensure directories exist
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.templates_dir.mkdir(parents=True, exist_ok=True)
        self.testers_dir.mkdir(parents=True, exist_ok=True)
    
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
    
    def get_internal_groups(self) -> List[Dict[str, Any]]:
        """Get internal testing group configurations"""
        return self.config.get('testing_groups', {}).get('internal', [])
    
    def get_external_groups(self) -> List[Dict[str, Any]]:
        """Get external testing group configurations"""
        return self.config.get('testing_groups', {}).get('external', [])
    
    def create_testing_group(self, group_name: str, description: str, group_type: str = "internal") -> bool:
        """Create a new testing group in TestFlight"""
        try:
            logger.info(f"Creating {group_type} testing group: {group_name}")
            
            # Use fastlane pilot to create group
            cmd = [
                'fastlane', 'pilot', 'add_group',
                'app_identifier:' + self.bundle_id,
                'group_name:' + group_name,
                'group_description:' + description
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            if result.returncode == 0:
                logger.info(f"Testing group '{group_name}' created successfully")
                return True
            else:
                logger.error(f"Failed to create testing group: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error creating testing group: {e}")
            return False
    
    def list_testing_groups(self) -> Dict[str, List[Dict[str, Any]]]:
        """List all testing groups"""
        try:
            logger.info("Fetching testing groups...")
            
            # Use fastlane pilot to list groups
            cmd = [
                'fastlane', 'pilot', 'list_groups',
                'app_identifier:' + self.bundle_id
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            if result.returncode == 0:
                # Parse the output to extract group information
                groups = self._parse_groups_output(result.stdout)
                logger.info(f"Found {len(groups)} testing groups")
                return groups
            else:
                logger.error(f"Failed to list testing groups: {result.stderr}")
                return {"internal": [], "external": []}
                
        except Exception as e:
            logger.error(f"Error listing testing groups: {e}")
            return {"internal": [], "external": []}
    
    def _parse_groups_output(self, output: str) -> Dict[str, List[Dict[str, Any]]]:
        """Parse fastlane pilot groups output"""
        groups = {"internal": [], "external": []}
        
        # This is a simplified parser - actual implementation would depend on fastlane output format
        lines = output.split('\n')
        current_group = None
        
        for line in lines:
            if 'Group Name:' in line:
                group_name = line.split('Group Name:')[1].strip()
                current_group = {
                    'name': group_name,
                    'description': '',
                    'testers': [],
                    'type': 'internal'  # Default to internal
                }
                
            elif 'Description:' in line and current_group:
                current_group['description'] = line.split('Description:')[1].strip()
                
            elif 'Type:' in line and current_group:
                group_type = line.split('Type:')[1].strip().lower()
                current_group['type'] = group_type
                
            elif current_group and line.strip() == '':
                # End of current group
                if current_group['type'] == 'external':
                    groups['external'].append(current_group)
                else:
                    groups['internal'].append(current_group)
                current_group = None
        
        return groups
    
    def add_testers_to_group(self, group_name: str, testers: List[Dict[str, str]], notify: bool = True) -> bool:
        """Add testers to a testing group"""
        try:
            logger.info(f"Adding {len(testers)} testers to group '{group_name}'")
            
            # Create temporary CSV file with tester information
            testers_file = self.testers_dir / f"temp_testers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            
            with open(testers_file, 'w', newline='') as csvfile:
                fieldnames = ['email', 'first_name', 'last_name']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                
                for tester in testers:
                    writer.writerow({
                        'email': tester.get('email', ''),
                        'first_name': tester.get('first_name', ''),
                        'last_name': tester.get('last_name', '')
                    })
            
            # Use fastlane pilot to add testers
            cmd = [
                'fastlane', 'pilot', 'add_testers',
                'app_identifier:' + self.bundle_id,
                'groups:' + group_name,
                'csv_file:' + str(testers_file)
            ]
            
            if not notify:
                cmd.append('skip_notify:true')
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            # Clean up temporary file
            testers_file.unlink()
            
            if result.returncode == 0:
                logger.info(f"Testers added to group '{group_name}' successfully")
                return True
            else:
                logger.error(f"Failed to add testers to group: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error adding testers to group: {e}")
            return False
    
    def remove_testers_from_group(self, group_name: str, tester_emails: List[str]) -> bool:
        """Remove testers from a testing group"""
        try:
            logger.info(f"Removing {len(tester_emails)} testers from group '{group_name}'")
            
            for email in tester_emails:
                cmd = [
                    'fastlane', 'pilot', 'remove_tester',
                    'app_identifier:' + self.bundle_id,
                    'email:' + email
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
                
                if result.returncode == 0:
                    logger.info(f"Tester {email} removed successfully")
                else:
                    logger.warning(f"Failed to remove tester {email}: {result.stderr}")
            
            return True
                
        except Exception as e:
            logger.error(f"Error removing testers from group: {e}")
            return False
    
    def distribute_build_to_groups(self, build_number: str, groups: List[str], notify_testers: bool = True) -> bool:
        """Distribute a specific build to testing groups"""
        try:
            logger.info(f"Distributing build {build_number} to groups: {', '.join(groups)}")
            
            cmd = [
                'fastlane', 'pilot', 'distribute',
                'app_identifier:' + self.bundle_id,
                'build_number:' + build_number,
                'groups:' + ','.join(groups)
            ]
            
            if not notify_testers:
                cmd.append('notify_external_testers:false')
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            if result.returncode == 0:
                logger.info(f"Build {build_number} distributed successfully")
                return True
            else:
                logger.error(f"Failed to distribute build: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error distributing build to groups: {e}")
            return False
    
    def generate_public_link(self, group_name: str) -> Optional[str]:
        """Generate public link for external testing group"""
        try:
            logger.info(f"Generating public link for group '{group_name}'")
            
            # Use fastlane pilot to get or create public link
            cmd = [
                'fastlane', 'pilot', 'get_public_link',
                'app_identifier:' + self.bundle_id,
                'group:' + group_name
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd())
            
            if result.returncode == 0:
                # Extract public link from output
                public_link = self._extract_public_link(result.stdout)
                if public_link:
                    logger.info(f"Public link generated: {public_link}")
                    return public_link
                else:
                    logger.error("Could not extract public link from output")
                    return None
            else:
                logger.error(f"Failed to generate public link: {result.stderr}")
                return None
                
        except Exception as e:
            logger.error(f"Error generating public link: {e}")
            return None
    
    def _extract_public_link(self, output: str) -> Optional[str]:
        """Extract public link from fastlane output"""
        # Look for TestFlight public link pattern
        link_pattern = r'https://testflight\.apple\.com/join/[a-zA-Z0-9]+'
        match = re.search(link_pattern, output)
        
        if match:
            return match.group(0)
        
        return None
    
    def send_invitation_emails(self, testers: List[Dict[str, str]], group_name: str, 
                              public_link: Optional[str] = None, custom_message: str = "") -> bool:
        """Send custom invitation emails to testers"""
        try:
            logger.info(f"Sending invitation emails to {len(testers)} testers")
            
            # Load email configuration
            email_config = self.config.get('notifications', {}).get('email', {})
            if not email_config.get('enabled', False):
                logger.warning("Email notifications not configured, skipping")
                return True
            
            # Email content
            subject = f"Invitation to test {self.app_name}"
            
            # Load email template
            template_path = self.templates_dir / 'invitation_email_template.html'
            if template_path.exists():
                with open(template_path, 'r') as f:
                    email_template = f.read()
            else:
                email_template = self._get_default_email_template()
            
            # Setup SMTP
            smtp_server = smtplib.SMTP(email_config['smtp_server'], email_config['smtp_port'])
            smtp_server.starttls()
            smtp_server.login(email_config['username'], email_config['password'])
            
            sent_count = 0
            for tester in testers:
                try:
                    # Personalize email content
                    personalized_content = email_template.format(
                        first_name=tester.get('first_name', 'Tester'),
                        app_name=self.app_name,
                        group_name=group_name,
                        public_link=public_link or 'Check TestFlight app',
                        custom_message=custom_message,
                        support_email=email_config.get('from_email', '')
                    )
                    
                    # Create email message
                    msg = MIMEMultipart('alternative')
                    msg['Subject'] = subject
                    msg['From'] = email_config['from_email']
                    msg['To'] = tester['email']
                    
                    html_part = MIMEText(personalized_content, 'html')
                    msg.attach(html_part)
                    
                    # Send email
                    smtp_server.send_message(msg)
                    sent_count += 1
                    logger.debug(f"Invitation sent to {tester['email']}")
                    
                except Exception as e:
                    logger.warning(f"Failed to send invitation to {tester['email']}: {e}")
            
            smtp_server.quit()
            logger.info(f"Sent {sent_count}/{len(testers)} invitation emails")
            return sent_count > 0
            
        except Exception as e:
            logger.error(f"Error sending invitation emails: {e}")
            return False
    
    def _get_default_email_template(self) -> str:
        """Get default email template"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>TestFlight Invitation</title>
        </head>
        <body>
            <h2>You're invited to test {app_name}!</h2>
            
            <p>Hi {first_name},</p>
            
            <p>You've been invited to test <strong>{app_name}</strong> through TestFlight as part of the <strong>{group_name}</strong> testing group.</p>
            
            {custom_message}
            
            <h3>How to get started:</h3>
            <ol>
                <li>Install the TestFlight app from the App Store if you haven't already</li>
                <li>Use this link to join the beta: <a href="{public_link}">{public_link}</a></li>
                <li>Follow the instructions in TestFlight to install the beta version</li>
            </ol>
            
            <p>Thank you for helping us test {app_name}! Your feedback is valuable to us.</p>
            
            <p>If you have any questions, please contact us at <a href="mailto:{support_email}">{support_email}</a></p>
            
            <p>Best regards,<br>The {app_name} Team</p>
        </body>
        </html>
        """
    
    def load_testers_from_csv(self, csv_path: str) -> List[Dict[str, str]]:
        """Load testers from CSV file"""
        try:
            testers = []
            with open(csv_path, 'r') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    # Validate email
                    email = row.get('email', '').strip()
                    if email and '@' in email:
                        testers.append({
                            'email': email,
                            'first_name': row.get('first_name', '').strip(),
                            'last_name': row.get('last_name', '').strip()
                        })
                    else:
                        logger.warning(f"Invalid email address: {email}")
            
            logger.info(f"Loaded {len(testers)} testers from {csv_path}")
            return testers
            
        except Exception as e:
            logger.error(f"Error loading testers from CSV: {e}")
            return []
    
    def setup_internal_testing_groups(self) -> bool:
        """Setup internal testing groups based on configuration"""
        try:
            logger.info("Setting up internal testing groups...")
            
            internal_groups = self.get_internal_groups()
            success_count = 0
            
            for group_config in internal_groups:
                group_name = group_config['name']
                description = group_config.get('description', f"Internal testing group: {group_name}")
                
                if self.create_testing_group(group_name, description, "internal"):
                    success_count += 1
                    
                    # Add testers if specified
                    if 'testers_file' in group_config:
                        testers = self.load_testers_from_csv(group_config['testers_file'])
                        if testers:
                            self.add_testers_to_group(group_name, testers, notify=False)
            
            logger.info(f"Successfully setup {success_count}/{len(internal_groups)} internal groups")
            return success_count == len(internal_groups)
            
        except Exception as e:
            logger.error(f"Error setting up internal testing groups: {e}")
            return False
    
    def setup_external_testing_groups(self) -> Dict[str, str]:
        """Setup external testing groups and return public links"""
        try:
            logger.info("Setting up external testing groups...")
            
            external_groups = self.get_external_groups()
            public_links = {}
            
            for group_config in external_groups:
                group_name = group_config['name']
                description = group_config.get('description', f"External testing group: {group_name}")
                
                if self.create_testing_group(group_name, description, "external"):
                    # Generate public link for external groups
                    public_link = self.generate_public_link(group_name)
                    if public_link:
                        public_links[group_name] = public_link
                        
                        # Save public link to file
                        link_file = self.testers_dir / f"{group_name}_public_link.txt"
                        with open(link_file, 'w') as f:
                            f.write(public_link)
                        
                        logger.info(f"Public link for '{group_name}': {public_link}")
            
            return public_links
            
        except Exception as e:
            logger.error(f"Error setting up external testing groups: {e}")
            return {}
    
    def generate_testing_report(self) -> Dict[str, Any]:
        """Generate a comprehensive testing groups report"""
        try:
            groups = self.list_testing_groups()
            
            report = {
                'timestamp': datetime.now().isoformat(),
                'app_name': self.app_name,
                'bundle_id': self.bundle_id,
                'summary': {
                    'internal_groups': len(groups['internal']),
                    'external_groups': len(groups['external']),
                    'total_groups': len(groups['internal']) + len(groups['external'])
                },
                'groups': groups,
                'configuration': {
                    'internal': self.get_internal_groups(),
                    'external': self.get_external_groups()
                }
            }
            
            # Save report
            report_path = self.logs_dir / f"testing_groups_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(report_path, 'w') as f:
                json.dump(report, f, indent=2)
            
            logger.info(f"Testing groups report saved: {report_path}")
            return report
            
        except Exception as e:
            logger.error(f"Error generating testing report: {e}")
            return {}

def main():
    parser = argparse.ArgumentParser(description='TestFlight Testing Group Management System')
    parser.add_argument('--config', default='testflight-automation/configs/automation-config.yml',
                       help='Configuration file path')
    parser.add_argument('--action', required=True,
                       choices=['setup-internal', 'setup-external', 'create-group', 'add-testers', 
                               'distribute-build', 'generate-link', 'send-invitations', 'list-groups', 'report'],
                       help='Action to perform')
    parser.add_argument('--group-name', help='Testing group name')
    parser.add_argument('--group-description', help='Testing group description')
    parser.add_argument('--group-type', choices=['internal', 'external'], default='internal',
                       help='Testing group type')
    parser.add_argument('--testers-file', help='CSV file with tester information')
    parser.add_argument('--build-number', help='Build number to distribute')
    parser.add_argument('--groups', help='Comma-separated list of groups')
    parser.add_argument('--notify', action='store_true', help='Send notifications to testers')
    parser.add_argument('--custom-message', help='Custom message for invitations')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    manager = TestingGroupManager(args.config)
    
    if args.action == 'setup-internal':
        success = manager.setup_internal_testing_groups()
        sys.exit(0 if success else 1)
    
    elif args.action == 'setup-external':
        public_links = manager.setup_external_testing_groups()
        if public_links:
            print("Public links generated:")
            for group, link in public_links.items():
                print(f"  {group}: {link}")
        else:
            sys.exit(1)
    
    elif args.action == 'create-group':
        if not args.group_name:
            logger.error("--group-name is required for create-group action")
            sys.exit(1)
        
        description = args.group_description or f"{args.group_type.title()} testing group"
        success = manager.create_testing_group(args.group_name, description, args.group_type)
        sys.exit(0 if success else 1)
    
    elif args.action == 'add-testers':
        if not args.group_name or not args.testers_file:
            logger.error("--group-name and --testers-file are required for add-testers action")
            sys.exit(1)
        
        testers = manager.load_testers_from_csv(args.testers_file)
        if testers:
            success = manager.add_testers_to_group(args.group_name, testers, args.notify)
            sys.exit(0 if success else 1)
        else:
            sys.exit(1)
    
    elif args.action == 'distribute-build':
        if not args.build_number or not args.groups:
            logger.error("--build-number and --groups are required for distribute-build action")
            sys.exit(1)
        
        groups = [g.strip() for g in args.groups.split(',')]
        success = manager.distribute_build_to_groups(args.build_number, groups, args.notify)
        sys.exit(0 if success else 1)
    
    elif args.action == 'generate-link':
        if not args.group_name:
            logger.error("--group-name is required for generate-link action")
            sys.exit(1)
        
        public_link = manager.generate_public_link(args.group_name)
        if public_link:
            print(f"Public link: {public_link}")
        else:
            sys.exit(1)
    
    elif args.action == 'send-invitations':
        if not args.group_name or not args.testers_file:
            logger.error("--group-name and --testers-file are required for send-invitations action")
            sys.exit(1)
        
        testers = manager.load_testers_from_csv(args.testers_file)
        if testers:
            public_link = manager.generate_public_link(args.group_name)
            success = manager.send_invitation_emails(testers, args.group_name, 
                                                   public_link, args.custom_message or "")
            sys.exit(0 if success else 1)
        else:
            sys.exit(1)
    
    elif args.action == 'list-groups':
        groups = manager.list_testing_groups()
        print(json.dumps(groups, indent=2))
    
    elif args.action == 'report':
        report = manager.generate_testing_report()
        print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()