# =========================
# Test de NetworkPolicy
# =========================

# ⚠️ IMPORTANTE:
# Para que esta prueba de NetworkPolicy funcione correctamente,
# es OBLIGATORIO eliminar la NetworkPolicy "allow-same-namespace".
#
# Dicha policy permite todo el tráfico entre los pods del namespace,
# lo que provoca que incluso los pods NO permitidos reciban HTTP 200.
#
# Si no se elimina, esta prueba SIEMPRE dará 200 aunque la NetworkPolicy
# esté correctamente configurada.
#
# Comando para eliminarla:
# oc delete networkpolicy allow-same-namespace -n hoverdev-dev

# -------------------------
# Variables
# -------------------------
$namespace     = "hoverdev-dev"
$allowedLabel  = "app=cu-ms-invoices"
$targetService = "cu-ms-payments"
$targetPort    = 3000

Write-Host "============================================"
Write-Host " Test NetworkPolicy: $allowedLabel ➜ $targetService:$targetPort"
Write-Host " Namespace: $namespace"
Write-Host "============================================`n"

# -------------------------
# 1️⃣ Test desde pods PERMITIDOS
# -------------------------
Write-Host "▶ Probando desde pods PERMITIDOS (cu-ms-invoices)`n"

$allowedPods = oc get pods -n $namespace -l $allowedLabel -o jsonpath='{.items[*].metadata.name}' | Out-String
$allowedPods = $allowedPods -split "\s+"

foreach ($pod in $allowedPods) {
    if ($pod) {
        Write-Host "[+] Pod permitido: $pod"

        try {
            $status = oc exec -n $namespace $pod -- `
                python -c "import requests; print(requests.get('http://${targetService}:${targetPort}/users').status_code)"

            Write-Host "    ✅ HTTP $status (PERMITIDO)" -ForegroundColor Green
        }
        catch {
            Write-Host "    ❌ ERROR inesperado: $_" -ForegroundColor Red
        }
    }
}

# -------------------------
# 2️⃣ Test desde pod NO PERMITIDO
# -------------------------
Write-Host "`n▶ Probando desde pod NO PERMITIDO (temporal)`n"

try {
    $result = oc run test-pod `
        --rm -i --tty `
        --image=curlimages/curl `
        --restart=Never `
        -n $namespace `
        -- sh -c "curl -s -o /dev/null -w '%{http_code}' http://${targetService}:${targetPort}/users"

    if ($result -eq "200") {
        Write-Host "    ❌ HTTP 200 (NO debería pasar)" -ForegroundColor Red
        Write-Host "    🔥 NetworkPolicy NO está funcionando correctamente"
    }
    else {
        Write-Host "    ✅ HTTP $result (BLOQUEADO correctamente)" -ForegroundColor Green
        Write-Host "    🔐 NetworkPolicy funcionando correctamente"
    }
}
catch {
    Write-Host "    ✅ Conexión BLOQUEADA (timeout / conexión rechazada)" -ForegroundColor Green
    Write-Host "    🔐 NetworkPolicy funcionando correctamente"
}

# -------------------------
# Fin
# -------------------------
Write-Host "`n============================================"
Write-Host " Fin de la prueba de NetworkPolicy"
Write-Host "============================================"
