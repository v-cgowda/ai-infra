# Azure AI Infrastructure Deployment Script
# This script automates the deployment of Azure AI infrastructure using Terraform

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('deploy', 'destroy', 'plan', 'status')]
    [string]$Action = 'deploy',
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation = $false
)

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) { Write-ColorOutput Green "✓ $message" }
function Write-Error-Custom($message) { Write-ColorOutput Red "✗ $message" }
function Write-Info($message) { Write-ColorOutput Cyan "ℹ $message" }
function Write-Warning-Custom($message) { Write-ColorOutput Yellow "⚠ $message" }

# Script configuration
$InfraPath = "c:\terraform_poc\ai-infra\infra"
$TerraformVarsFile = Join-Path $InfraPath "terraform.tfvars"

Write-Info "Azure AI Infrastructure Deployment Tool"
Write-Info "========================================"
Write-Info ""

# Check prerequisites
Write-Info "Checking prerequisites..."

# Check Terraform
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Terraform is not installed or not in PATH"
    Write-Info "Install with: winget install --id=Hashicorp.Terraform -e"
    exit 1
}
$terraformVersion = terraform --version | Select-Object -First 1
Write-Success "Terraform installed: $terraformVersion"

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Azure CLI is not installed or not in PATH"
    Write-Info "Install with: winget install -e --id Microsoft.AzureCLI"
    exit 1
}
$azVersion = az --version | Select-Object -First 1
Write-Success "Azure CLI installed: $azVersion"

# Check if logged in to Azure
Write-Info "Checking Azure login status..."
$azAccount = az account show 2>$null | ConvertFrom-Json
if (-not $azAccount) {
    Write-Warning-Custom "Not logged in to Azure"
    Write-Info "Logging in to Azure..."
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Azure login failed"
        exit 1
    }
    $azAccount = az account show | ConvertFrom-Json
}
Write-Success "Logged in to Azure as: $($azAccount.user.name)"
Write-Success "Subscription: $($azAccount.name) ($($azAccount.id))"

# Check terraform.tfvars exists
if (-not (Test-Path $TerraformVarsFile) -and -not $SkipValidation) {
    Write-Error-Custom "terraform.tfvars not found at: $TerraformVarsFile"
    Write-Info "Please create terraform.tfvars with required variables"
    exit 1
}

if (Test-Path $TerraformVarsFile) {
    Write-Success "Configuration file found: terraform.tfvars"
    
    # Check for default password
    $tfvarsContent = Get-Content $TerraformVarsFile -Raw
    if ($tfvarsContent -match 'ChangeMe123') {
        Write-Warning-Custom "Default password detected in terraform.tfvars"
        Write-Warning-Custom "Please change 'utility_vm_admin_password' before deploying"
        if (-not $SkipValidation) {
            exit 1
        }
    }
}

Write-Info ""

# Change to infrastructure directory
Set-Location $InfraPath

# Execute action
switch ($Action) {
    'plan' {
        Write-Info "Running Terraform plan..."
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform init failed"
            exit 1
        }
        terraform plan
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform plan failed"
            exit 1
        }
        Write-Success "Terraform plan completed successfully"
    }
    
    'deploy' {
        Write-Info "Starting infrastructure deployment..."
        Write-Warning-Custom "This will create Azure resources in your subscription"
        Write-Warning-Custom "Estimated cost: ~$300-500/month if left running"
        Write-Info ""
        
        if (-not $AutoApprove) {
            $confirm = Read-Host "Continue with deployment? (yes/no)"
            if ($confirm -ne 'yes') {
                Write-Info "Deployment cancelled"
                exit 0
            }
        }
        
        Write-Info "Initializing Terraform..."
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform init failed"
            exit 1
        }
        Write-Success "Terraform initialized"
        
        Write-Info "Applying Terraform configuration..."
        if ($AutoApprove) {
            terraform apply -auto-approve
        } else {
            terraform apply
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform apply failed"
            exit 1
        }
        
        Write-Success "Deployment completed successfully!"
        Write-Info ""
        Write-Info "To view outputs, run: terraform output"
        Write-Info "To destroy resources, run: .\deploy.ps1 -Action destroy"
    }
    
    'destroy' {
        Write-Warning-Custom "This will DESTROY all infrastructure resources"
        Write-Warning-Custom "This action cannot be undone!"
        Write-Info ""
        
        if (-not $AutoApprove) {
            $confirm = Read-Host "Are you sure you want to destroy all resources? (yes/no)"
            if ($confirm -ne 'yes') {
                Write-Info "Destroy cancelled"
                exit 0
            }
            
            $confirmAgain = Read-Host "Type 'destroy' to confirm"
            if ($confirmAgain -ne 'destroy') {
                Write-Info "Destroy cancelled"
                exit 0
            }
        }
        
        Write-Info "Destroying infrastructure..."
        if ($AutoApprove) {
            terraform destroy -auto-approve
        } else {
            terraform destroy
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Terraform destroy failed"
            Write-Info "If you encounter subnet delegation errors, wait 30-60 minutes and retry"
            Write-Info "Or use: az group delete --name <rg-name> --yes"
            exit 1
        }
        
        Write-Success "Infrastructure destroyed successfully"
        
        # Optional: Clean up Terraform state
        $cleanState = Read-Host "Remove Terraform state files? (yes/no)"
        if ($cleanState -eq 'yes') {
            Remove-Item .terraform -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item terraform.tfstate* -Force -ErrorAction SilentlyContinue
            Remove-Item .terraform.lock.hcl -Force -ErrorAction SilentlyContinue
            Write-Success "Terraform state files removed"
        }
    }
    
    'status' {
        Write-Info "Checking Terraform state..."
        if (Test-Path "terraform.tfstate") {
            $stateInfo = Get-Item "terraform.tfstate"
            Write-Success "Terraform state exists (Last modified: $($stateInfo.LastWriteTime))"
            
            Write-Info ""
            Write-Info "Resource Groups:"
            terraform state list | Where-Object { $_ -like '*azurerm_resource_group*' } | ForEach-Object {
                Write-Info "  - $_"
            }
            
            Write-Info ""
            Write-Info "For full list of resources: terraform state list"
            Write-Info "For resource details: terraform state show <resource>"
        } else {
            Write-Info "No Terraform state found - infrastructure not deployed"
        }
    }
}

Write-Info ""
Write-Info "Script completed"
