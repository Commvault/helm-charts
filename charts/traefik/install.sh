helm upgrade --install traefik-crds traefik-crds \
  --repo https://traefik.github.io/charts \
  --version 1.18.0 \
  --namespace traefik --create-namespace \
  --wait --timeout 5m

helm upgrade --install traefik traefik \
  --repo https://traefik.github.io/charts \
  --version 42.0.0 \
  --namespace traefik --create-namespace \
  --skip-crds \
  --values traefik-ingress-values.yaml \
  --wait --timeout 5m
