# =========================
# Test de NetworkPolicy
# =========================

# IMPORTANTE:
# Si el test desde el pod NO permitido devuelve HTTP 200,
# significa que la NetworkPolicy "allow-same-namespace"
# sigue permitiendo el tráfico.

$namespace     = "hoverdev-dev"
$allowedLabel  = "app=cu-ms-invoices"
$targetService = "cu-ms-payments"
$targetPort    = 3000

Write-Host "============================================"
Write-Host " Test NetworkPolicy"
Write-Host " Allowed label : $allowedLabel"
Write-Host " Target        : ${targetService}:${targetPort}"
Write-Host " Namespace     : $namespace"
Write-Host "============================================"
Write-Host ""

# -------------------------
# 1) Pods PERMITIDOS
# -------------------------
Write-Host "[1] Probando desde pods PERMITIDOS"
Write-Host ""

$allowedPods = oc get pods -n $namespace -l $allowedLabel -o jsonpath='{.items[*].metadata.name}' | Out-String
$allowedPods = $allowedPods -split "\s+"

foreach ($pod in $allowedPods) {
    if ($pod) {
        Write-Host "  Pod permitido: $pod"

        $status = oc exec -n $namespace $pod -- `
            python -c "import requests; print(requests.get('http://${targetService}:${targetPort}/users').status_code)"

        Write-Host "    HTTP status: $status (OK)"
    }
}

# -------------------------
# 2) Pod NO PERMITIDO
# -------------------------
Write-Host ""
Write-Host "[2] Probando desde pod NO PERMITIDO (temporal)"
Write-Host ""

$result = oc run test-pod `
    --rm -i --tty `
    --image=curlimages/curl `
    --restart=Never `
    -n $namespace `
    -- sh -c "curl -s -o /dev/null -w '%{http_code}' http://${targetService}:${targetPort}/users"

# 🔑 CLAVE: usar -match
if ($result -match "200") {
    Write-Host "    RESULTADO: HTTP 200" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    ADVERTENCIA: Trafico permitido desde pod NO autorizado"
    Write-Host ""
    Write-Host "    CAUSA:"
    Write-Host "    La NetworkPolicy 'allow-same-namespace' none sigue activa que viene por defecto OpenShift crea automaticamente. "
    Write-Host ""
    Write-Host "    ACCION REQUERIDA:"
    Write-Host "    Para que funcione en un namaspace y no se cominiquen entro todos los pods Ejecuta:"
    Write-Host ""
    Write-Host "      oc delete networkpolicy allow-same-namespace -n $namespace" -ForegroundColor Cyan 
}
else {
    Write-Host "    RESULTADO: HTTP bloqueado correctamente" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================"
Write-Host " Fin de la prueba de NetworkPolicy"
Write-Host "============================================"
