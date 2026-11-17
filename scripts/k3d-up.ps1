# Local Kubernetes (k3d = k3s in Docker) to test the manifests in k8s/. Usage: .\scripts\k3d-up.ps1
# Stops at the first failing step; prints OK only when every deployment is ready.
$ErrorActionPreference = 'Continue'
function Refresh-Path { $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') }
function Rand($n) { -join ((48..57)+(65..90)+(97..122) | Get-Random -Count $n | ForEach-Object {[char]$_}) }
function Run([scriptblock]$cmd, [string]$what) {
  & $cmd
  if ($LASTEXITCODE -ne 0) { throw "LOI o buoc: $what (ma $LASTEXITCODE). Gui anh nay cho minh." }
}
$cluster = 'attendance'
$ns = 'staging'
$reg = 'ghcr.io/tuantetua123'

docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Docker Desktop chua chay. Mo Docker Desktop, doi xanh roi chay lai." }
$cfree = [math]::Round((Get-PSDrive C).Free/1GB,1)
if ($cfree -lt 2) { throw "O C chi con $cfree GB. Don o C (can it nhat 2 GB) roi chay lai." }

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { winget install -e --id Kubernetes.kubectl --accept-source-agreements --accept-package-agreements; Refresh-Path }
if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
  $dir = 'D:\tools'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Invoke-WebRequest 'https://github.com/k3d-io/k3d/releases/latest/download/k3d-windows-amd64.exe' -OutFile "$dir\k3d.exe"
  $env:Path += ";$dir"
  [Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path','User') + ";$dir"), 'User')
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue) -or -not (Get-Command k3d -ErrorAction SilentlyContinue)) {
  throw "Vua cai cong cu xong: dong va mo lai PowerShell, vao thu muc attendance, chay lai script."
}

# free RAM/ports: stop compose stack (data kept, no -v)
docker compose -f compose.yml -f compose.monitoring.yml down

k3d cluster list $cluster 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Run { k3d cluster create $cluster --servers 1 --agents 0 -p "18081:80@loadbalancer" --wait --timeout 240s } 'tao cum k3d'
}
Run { kubectl config use-context "k3d-$cluster" } 'chon context'
Run { kubectl get nodes } 'ket noi cum'

Run { docker compose build } 'build image'
foreach ($svc in 'api','qr','web') {
  Run { docker tag "local/attendance-${svc}:dev" "$reg/attendance-${svc}:dev" } "tag $svc"
  Run { k3d image import "$reg/attendance-${svc}:dev" -c $cluster } "nap image $svc vao cum"
}

Run { kubectl apply -f k8s/namespaces.yaml } 'tao namespace'
$exists = kubectl -n $ns get secret attendance-secrets -o name --ignore-not-found
if (-not $exists) {
  Run { kubectl -n $ns create secret generic attendance-secrets --from-literal=POSTGRES_PASSWORD=$(Rand 24) --from-literal=QR_SECRET=$(Rand 32) --from-literal=ADMIN_API_KEY=$(Rand 32) } 'tao secret'
}

Run { kubectl apply -k k8s/overlays/staging } 'ap dung overlay staging'
Run { kubectl -n $ns rollout status statefulset/db --timeout=300s } 'cho db san sang'

Run { kubectl -n $ns create configmap db-migrations --from-file=db/migrations --dry-run=client -o yaml | kubectl -n $ns apply -f - } 'tao configmap migration'
Run { kubectl -n $ns create -f k8s/jobs/migrate-job.yaml } 'tao job migration'
try {
  Run { kubectl -n $ns wait --for=condition=complete job --all --timeout=240s } 'cho job migration xong'
} catch {
  kubectl -n $ns get pods
  kubectl -n $ns logs -l batch.kubernetes.io/job-name --tail=30
  throw
}

foreach ($d in 'api','qr','web') {
  Run { kubectl -n $ns rollout status deployment/$d --timeout=300s } "cho deployment $d"
}
kubectl -n $ns get pods,hpa,ingress
Write-Host "`nOK: tat ca deployment da san sang." -ForegroundColor Green
Write-Host "Thu qua Ingress (Traefik): curl.exe -H 'Host: staging.attendance.local' http://localhost:18081/" -ForegroundColor Green