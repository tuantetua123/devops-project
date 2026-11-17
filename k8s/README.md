# Kubernetes deploy (k3s)

One-time setup per cluster:

    kubectl apply -f k8s/namespaces.yaml
    kubectl -n staging create secret generic attendance-secrets \
      --from-literal=POSTGRES_PASSWORD=... --from-literal=QR_SECRET=... --from-literal=ADMIN_API_KEY=...
    # repeat for -n production with DIFFERENT values

Deploy (replace TAG with the commit SHA):

    kubectl apply -k k8s/overlays/staging
    kubectl -n staging create configmap db-migrations --from-file=db/migrations --dry-run=client -o yaml | kubectl -n staging apply -f -
    kubectl -n staging create -f k8s/jobs/migrate-job.yaml
    kubectl -n staging rollout status deployment/api

Rollback:

    kubectl -n staging rollout undo deployment/api

If the GHCR packages are private, create a pull secret and add it to the service account.
Staging/production hosts are staging.attendance.local / attendance.local (add to hosts file until a real domain + cert-manager is set up).