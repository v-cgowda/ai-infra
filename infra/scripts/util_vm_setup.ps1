Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
winget install --id Microsoft.PowerShell --source winget --silent --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.AzureCLI -e --silent --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.Azure.FunctionsCoreTools -e --silent --accept-source-agreements --accept-package-agreements
winget install --id Git.Git -e --source winget --silent --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.VisualStudioCode --silent --accept-source-agreements --accept-package-agreements
winget install --id Python.Python.3.13 -e --silent --accept-source-agreements --accept-package-agreements
winget install --id GitHub.cli -e --silent --accept-source-agreements --accept-package-agreements
winget install --id Docker.DockerDesktop -e --silent --accept-source-agreements --accept-package-agreements
Install-Module -Name PowerShellGet -Force -AllowClobber -AcceptLicense -SkipPublisherCheck
Install-Module -Name Az -Repository PSGallery -Force -AcceptLicense -SkipPublisherCheck

# restart the computer
Restart-Computer -Force
