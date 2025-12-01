#!/bin/bash

# Migration script for moving from monolithic to modular Terraform

set -e

echo "🚀 Terraform Modular Migration Script"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "main.tf" ] || [ ! -f "workload.tf" ]; then
    echo "❌ Error: This script must be run from the infra directory"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform is not installed"
    exit 1
fi

echo "📋 Migration Options:"
echo "1. Fresh deployment (recommended for new environments)"
echo "2. Backup current configuration and prepare for migration"
echo "3. Initialize modules only"
echo ""

read -p "Choose an option (1-3): " choice

case $choice in
    1)
        echo "🆕 Fresh deployment selected"
        echo ""
        echo "📝 Steps to deploy fresh modular infrastructure:"
        echo "1. Backup your terraform.tfvars file if it exists"
        echo "2. Run: terraform init"
        echo "3. Run: terraform plan -var-file=terraform.tfvars"
        echo "4. Run: terraform apply"
        echo ""
        echo "⚠️  Note: This will create new resources. Make sure to update your terraform.tfvars"
        echo "   to point to the modular configuration files."
        ;;
    
    2)
        echo "💾 Backing up current configuration..."
        
        # Create backup directory
        backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        # Copy current state and configuration
        if [ -f "terraform.tfstate" ]; then
            cp terraform.tfstate "$backup_dir/"
            echo "✅ State file backed up"
        fi
        
        if [ -f "terraform.tfvars" ]; then
            cp terraform.tfvars "$backup_dir/"
            echo "✅ Variables file backed up"
        fi
        
        # Copy main files
        cp main.tf "$backup_dir/"
        cp workload.tf "$backup_dir/"
        cp outputs.tf "$backup_dir/"
        cp variables.tf "$backup_dir/"
        
        echo "✅ Configuration files backed up to $backup_dir/"
        echo ""
        echo "📝 Next steps for in-place migration:"
        echo "1. Use 'terraform state mv' commands to move resources to modules"
        echo "2. This is an advanced operation - consider fresh deployment instead"
        echo "3. Refer to the MODULES-README.md for detailed guidance"
        ;;
    
    3)
        echo "🔧 Initializing modules..."
        terraform init
        echo "✅ Modules initialized"
        echo ""
        echo "📝 Next steps:"
        echo "1. Review the module configurations in ./modules/"
        echo "2. Update your terraform.tfvars as needed"
        echo "3. Run: terraform plan to see what will be created"
        ;;
    
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "📚 For detailed information about the modular architecture:"
echo "   👉 Read MODULES-README.md"
echo ""
echo "🎯 Key benefits of the modular approach:"
echo "   • Better organization and maintainability"
echo "   • Reusable components across environments"
echo "   • Easier testing and validation"
echo "   • Clear separation of concerns"
echo ""
echo "✨ Migration completed successfully!"