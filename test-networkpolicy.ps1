# Variables
$namespace = "hoverdev-dev"
$allowedLabel = "app=cu-ms-invoices"
$targetService = "cu-ms-payments"
$targetPort = 3000

Write-Host "=== Comprobando NetworkPolicy de $allowedLabel hacia ${targetService}:${targetPort} ===`n"

# 1️⃣ Listar todos los pods permitidos
$allowedPods = oc get pods -n $namespace -l $allowedLabel -o jsonpath='{.items[*].metadata.name}' | Out-String
$allowedPods = $allowedPods -split "\s+"

foreach ($pod in $allowedPods) {
    if ($pod) {
        Write-Host "[+] Probando desde pod permitido: $pod"
        try {
            $result = oc exec -n $namespace $pod -- python -c "import requests; r=requests.get('http://${targetService}:${targetPort}/users'); print(r.status_code)"
            Write-Host "    Código HTTP: $result"
        } catch {
            Write-Host "    Error al probar el pod: $_" -ForegroundColor Red
        }
    }
}

# 2️⃣ Test desde pod NO permitido (temporal)
Write-Host "`n[+] Probando desde pod NO permitido (temporal)..."
try {
    oc run test-pod --rm -i --tty --image=curlimages/curl --restart=Never -- sh -c "curl -s -o /dev/null -w '%{http_code}' http://${targetService}:${targetPort}/users"
} catch {
    Write-Host "    Error al probar el pod temporal: $_" -ForegroundColor Red
}

Write-Host "`n=== Prueba de NetworkPolicy finalizada ==="
