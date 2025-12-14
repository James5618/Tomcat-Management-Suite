# Tomcat Suite - Ansible Playbook Automation

Comprehensive Ansible playbooks for managing Apache Tomcat installations across your infrastructure with automated version detection, upgrades, and backup/restore capabilities.

---

## Table of Contents

- [Overview](#overview)
- [Playbooks Included](#playbooks-included)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Key Features](#key-features)
- [Backup and Restore](#backup-and-restore)
- [Variables](#variables)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Version Compatibility](#version-compatibility)
- [Support](#support)

---

## Overview

This suite contains Ansible playbooks for managing Apache Tomcat installations across your infrastructure. It supports automated version detection, upgrades, and comprehensive backup/restore capabilities for both minor and major version upgrades.

---

## Playbooks Included

### 1. `playbook.yml`
- **Purpose:** Upgrade Tomcat 9 installations to the latest 9.x version
- **Type:** Minor version upgrade
- **Use Case:** Keeping Tomcat 9 up-to-date with security patches

### 2. `playbook-tomcat7.yml`
- **Purpose:** Upgrade Tomcat 7 installations to the latest 7.x version
- **Type:** Minor version upgrade within Tomcat 7
- **Note:** Tomcat 7 reached End of Life on March 31, 2021

### 3. `playbook-tomcat7-to-9-upgrade.yml`
- **Purpose:** Major version upgrade from Tomcat 7 to Tomcat 9
- **Type:** Major version upgrade
- **Use Case:** Migrating from EOL Tomcat 7 to supported Tomcat 9

### 4. `tomcat_report.yml`
- **Purpose:** Generate comprehensive reports of Tomcat installations
- **Type:** Information gathering
- **Use Case:** Audit and inventory management

---

## Prerequisites

### System Requirements
- **Ansible:** 2.9 or higher installed on controller
- **Python:** 3.6 or higher on controller
- **SSH access** to target servers
- **sudo/root privileges** on target servers

### Target Server Requirements
- **Operating System:** Linux (RedHat/CentOS/RHEL or Debian/Ubuntu)
- **Java:** 8+ installed (for Tomcat 9 upgrades)
- **Network access** to download Tomcat archives
- **Disk space:** Sufficient for backups (2x Tomcat installation size)

### Network Requirements
- SSH connectivity from controller to target servers
- HTTPS access to `tomcat.apache.org` (for version detection)
- HTTPS access to `archive.apache.org` (for downloads)

---

## Installation

1. **Clone or extract this playbook suite** to your Ansible controller:
   ```bash
   cd /path/to/ansible/
   ```

2. **Edit the inventory file:**
   ```bash
   vi inventory.ini
   ```
   
   Add your target servers (one per line):
   ```ini
Server1
Server2
Server3
   ```

3. **Test connectivity:**
   ```bash
   ansible all -i inventory.ini -m ping
   ```

4. **Verify sudo access:**
   ```bash
   ansible all -i inventory.ini -m shell -a "whoami" --become
   ```

---

## Usage

### Tomcat 9 Minor Version Upgrade

**Basic usage:**
```bash
ansible-playbook -i inventory.ini playbook.yml
```

**With verbose output:**
```bash
ansible-playbook -i inventory.ini playbook.yml -v
```

**Target specific servers:**
```bash
ansible-playbook -i inventory.ini playbook.yml --limit server1
```

**Auto-confirm (skip prompts):**
```bash
ansible-playbook -i inventory.ini playbook.yml -e auto_confirm_upgrade=true
```

**Check mode (dry run):**
```bash
ansible-playbook -i inventory.ini playbook.yml --check
```

#### What it does:
- Detects latest Tomcat 9 version automatically
- Finds all Tomcat 9 installations on target servers
- Compares installed versions with latest available
- Downloads Tomcat once to controller, copies to targets
- Stops running instances gracefully
- Creates comprehensive backups
- Upgrades to latest version
- Preserves configuration and webapps
- Removes Windows .bat files and documentation
- Starts services and verifies functionality
- Auto-rollback on failure

---

### Tomcat 7 to 9 Major Upgrade

**Basic usage:**
```bash
ansible-playbook -i inventory.ini playbook-tomcat7-to-9-upgrade.yml
```

**With verbose output:**
```bash
ansible-playbook -i inventory.ini playbook-tomcat7-to-9-upgrade.yml -v
```

**Auto-confirm:**
```bash
ansible-playbook -i inventory.ini playbook-tomcat7-to-9-upgrade.yml -e auto_confirm_upgrade=true
```

#### What it does:
- Verifies Java 8+ is installed (required for Tomcat 9)
- Finds all Tomcat 7 installations
- Displays comprehensive upgrade warnings
- Creates full backups of Tomcat 7
- Installs Tomcat 9 while preserving configs/webapps
- Generates configuration migration notes
- Provides comparison between Tomcat 7 and 9 configs
- Auto-rollback to Tomcat 7 if startup fails

> **WARNING - IMPORTANT:** This is a major version upgrade with breaking changes!
> - Review the upgrade warnings carefully
> - Test applications in dev/test first
> - Plan a maintenance window
> - Review configuration migration notes after upgrade

---

### Generate Tomcat Report

**Basic usage:**
```bash
ansible-playbook -i inventory.ini tomcat_report.yml
```

**Custom email recipient:**
```bash
ansible-playbook -i inventory.ini tomcat_report.yml -e email_to=admin@example.com
```

#### What it does:
- Scans all servers for Tomcat installations
- Detects versions and running status
- Identifies processes and ports
- Generates HTML report
- Optionally emails the report

---

## Key Features

### Automatic Version Detection
- Queries Apache website for latest versions
- No manual version updates needed
- Validates version format and availability

### Intelligent Discovery
- Finds Tomcat by running processes
- Searches common installation directories
- Detects systemd services
- Works with custom installations

### Comprehensive Backups
- Full tar.gz backups before any changes
- Separate conf, webapps, logs backups
- JSON metadata for automation
- Detailed restore instructions

### Version Comparison
- Compares installed vs latest versions
- Only upgrades installations that need it
- Skips already up-to-date installations
- Clear reporting of what will be upgraded

### Graceful Process Handling
- Attempts graceful shutdown first
- Force kills only if necessary
- Preserves running port information
- Restarts on same ports

### Configuration Preservation
- Keeps existing configurations
- Preserves web applications
- Maintains logs and work directories
- For major upgrades: provides new config templates

### Automatic Rollback
- Monitors startup after upgrade
- Checks HTTP response
- Automatically reverts on failure
- Restores from backup seamlessly

### Post-Upgrade Cleanup
- Removes Windows .bat files (Linux installations)
- Removes README, LICENSE, NOTICE files
- Cleans up temporary download files
- Maintains clean installation directory

---

## Backup and Restore

### Backup Location
All backups are stored in `/tmp/tomcat_backup_<timestamp>/` on target servers

### Backup Contents
- Full tar archive of entire Tomcat installation
- Separate copies of conf, webapps, logs directories
- Metadata files with version and configuration info
- Restore instructions

### Manual Restore Procedure

1. **Stop current Tomcat:**
   ```bash
   systemctl stop tomcat
   # OR
   cd /path/to/tomcat && ./bin/shutdown.sh
   ```

2. **Remove current installation:**
   ```bash
   cd /path/to/tomcat/..
   rm -rf /path/to/tomcat
   ```

3. **Restore from backup:**
   ```bash
   tar -xf /tmp/tomcat_backup_<timestamp>/<name>/tomcat_backup_<name>_<epoch>.tar \
       -C /path/to/parent/directory
   ```

4. **Fix permissions:**
   ```bash
   chown -R tomcat:tomcat /path/to/tomcat
   ```

5. **Start Tomcat:**
   ```bash
   systemctl start tomcat
   # OR
   cd /path/to/tomcat && ./bin/startup.sh
   ```

### Automatic Rollback
The playbooks include automatic rollback on failure. If Tomcat fails to start after upgrade, the playbook will:
- Detect the failure
- Restore from backup automatically
- Start the restored version
- Report the issue and exit

---

## Variables

### Common Variables (all playbooks)

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `tomcat_user` | `tomcat` | Owner of Tomcat files | `-e tomcat_user=tomcat9` |
| `tomcat_group` | `tomcat` | Group of Tomcat files | `-e tomcat_group=tomcat` |
| `auto_confirm_upgrade` | `false` | Skip manual confirmation prompts | `-e auto_confirm_upgrade=true` |

### Tomcat 9 Specific (`playbook.yml`)

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `tomcat_latest_version` | auto-detected | Override detected version | `-e tomcat_latest_version=9.0.105` |

### Tomcat 7 to 9 Specific (`playbook-tomcat7-to-9-upgrade.yml`)

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `min_java_version` | `1.8` | Minimum required Java version | Cannot be changed (Tomcat 9 requirement) |

### Report Specific (`tomcat_report.yml`)

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `email_to` | `example@example.com` | Report recipient email | `-e email_to=admin@company.com` |
| `email_from` | `example@admin.com` | Report sender email | `-e email_from=noreply@company.com` |

---

## Troubleshooting

### Issue: Version detection fails
**Solution:**
- Check internet connectivity from controller
- Verify access to tomcat.apache.org
- Use fallback: `-e tomcat_latest_version=9.0.106`

### Issue: Download fails
**Solution:**
- Check network connectivity
- Verify firewall rules allow HTTPS
- Try mirror URL manually
- Pre-download to /tmp/ on controller

### Issue: Tomcat won't start after upgrade
**Solution:**
- Check Java version: `java -version`
- Review logs: `tail -f /path/to/tomcat/logs/catalina.out`
- Check port conflicts: `netstat -tlnp | grep <port>`
- Verify file permissions: `ls -la /path/to/tomcat`
- If automatic rollback occurred, check backup logs

### Issue: Configuration issues after Tomcat 7→9 upgrade
**Solution:**
- Review migration notes: `cat /tmp/tomcat_backup_*/*/CONFIGURATION_MIGRATION_NOTES.txt`
- Compare configs: `diff -r old_conf/ new_conf/`
- Check for deprecated settings in server.xml
- Review Tomcat 9 migration guide

### Issue: Application compatibility issues
**Solution:**
- Check servlet version requirements
- Review application logs
- Update application dependencies
- Test in development environment first

### Issue: Backup space issues
**Solution:**
- Check available space: `df -h /tmp`
- Clean old backups: `rm -rf /tmp/tomcat_backup_*`
- Use custom backup location: `-e tomcat_backup_dir=/opt/backups`

### Issue: Permission denied errors
**Solution:**
- Verify sudo access: `ansible all -i inventory.ini -m shell -a "whoami" --become`
- Check SSH key authentication
- Verify become settings in ansible.cfg

---

## Best Practices

### Before Running Upgrades

#### 1. Test in Non-Production First
- Run playbooks in dev/test environments
- Verify application compatibility
- Review any errors or warnings

#### 2. Plan Maintenance Windows
- Schedule during low-traffic periods
- Notify stakeholders in advance
- Have rollback plan ready

#### 3. Verify Prerequisites
- Check Java versions
- Ensure adequate disk space
- Verify network connectivity
- Test SSH access

#### 4. Review Current State
- Run `tomcat_report.yml` first
- Document current versions
- Note running ports and services

#### 5. Backup Strategy
- Verify backup location has space
- Test restore procedure beforehand
- Keep backups for at least 30 days

### During Execution

#### 1. Monitor Progress
- Use verbose mode (`-v`) for first run
- Watch for warnings or errors
- Review backup creation messages

#### 2. Don't Interrupt
- Let playbook complete fully
- Interruption may leave system inconsistent
- If interrupted, check Tomcat status manually

### After Upgrades

#### 1. Verify Functionality
- Check Tomcat version: `./bin/version.sh`
- Test web applications
- Review logs for errors
- Monitor performance

#### 2. Clean Up (Tomcat 7→9)
- Review configuration migration notes
- Update application configs if needed
- Remove deprecated settings
- Test all features thoroughly

#### 3. Documentation
- Update runbooks with new versions
- Document any issues encountered
- Note configuration changes made

#### 4. Monitor
- Watch logs for 24-48 hours
- Check memory and CPU usage
- Monitor application performance
- Keep backups until stable

---

## Security Considerations

### SSH Access
- Use SSH keys instead of passwords
- Limit SSH access to Ansible controller
- Use dedicated Ansible service account
- Review sudo permissions regularly

### File Permissions
- Tomcat files owned by tomcat user/group
- Avoid running as root
- Verify permissions after upgrade

### Network Security
- Firewall rules for required ports only
- TLS/SSL for Tomcat connectors
- Secure manager/admin interfaces
- Regular security updates

### Backup Security
- Backups may contain sensitive data
- Secure backup storage location
- Encrypt backups if required
- Clean up old backups regularly

---

## Version Compatibility

### Tomcat 9 Requirements
- **Java:** 8 or higher (Java 11+ recommended)
- **Servlet:** 4.0 compatible applications
- **JSP:** 2.3 compatible applications

### Tomcat 7 Requirements (EOL)
- **Java:** 6 or higher (Java 7+ recommended)
- **Servlet:** 3.0 compatible applications
- **JSP:** 2.2 compatible applications

### Major Version Changes (7→9)

| Component | Tomcat 7 | Tomcat 9 |
|-----------|----------|----------|
| Servlet API | 3.0 | 4.0 |
| JSP | 2.2 | 2.3 |
| Expression Language | 2.2 | 3.0 |
| WebSocket API | JSR 356 | JSR 356 (updated) |
| Java | 6+ | 8+ (required) |

---

## Support

For issues, questions, or contributions:


### When reporting issues, include:
- Playbook being used
- Ansible version: `ansible --version`
- Target OS and version
- Tomcat version (before upgrade)
- Error messages and logs
- Steps to reproduce

---

## Changelog


---

## License

This playbook suite is provided as-is for internal company (there are some bispoke things like symlink to config-locations these can be changed as seen fit).  
Modify and distribute according to your organization's policies.

Apache Tomcat is licensed under the Apache License 2.0.  
See https://www.apache.org/licenses/LICENSE-2.0

---

## File Structure

```
tomcatsuite/
├── inventory.ini                           # Server inventory
├── playbook.yml                            # Tomcat 9 minor upgrade
├── playbook-tomcat7.yml                    # Tomcat 7 minor upgrade
├── playbook-tomcat7-to-9-upgrade.yml       # Tomcat 7 to 9 major upgrade
├── tomcat_report.yml                       # Report generator
└── README.md                               # This file
```

### After execution:
```
/tmp/tomcat_backup_<timestamp>/             # Backup directory
├── <installation_name>/
│   ├── tomcat_backup_<name>_<epoch>.tar    # Full backup
│   ├── conf_original/                      # Original config
│   ├── webapps_original/                   # Original webapps
│   └── CONFIGURATION_MIGRATION_NOTES.txt   # Migration guide (Tomcat 7→9)
├── backup_metadata.txt                     # Human-readable metadata
└── backup_metadata.json                    # Machine-readable metadata
```

---


