# TP03 — Registre privé et supply chain

## Lancer

```bash
bash registry/gen-certs.sh
bash registry/gen-htpasswd.sh
cd registry && docker compose up -d
```

Comptes : `ci` / `ci-push-2024` (push), `dev` / `dev-pull-2024` (pull). Interface : http://localhost:8081.
Registre sur `registry.local:5000`, mirror Docker Hub sur `localhost:5001`.

## 1. Registre

- TLS : CA interne et certificat serveur avec SAN `registry.local`, `registry`, `localhost`, `127.0.0.1`.
  La CA est copiée dans `~/.docker/certs.d/<hôte>:5000/ca.crt` (équivalent Windows de `/etc/docker/certs.d`).
- Auth htpasswd bcrypt, volumes nommés, `storage.delete.enabled`, `healthcheck`, `restart: unless-stopped`,
  configuration par `config.yml` monté, UI `joxit/docker-registry-ui`, mirror pull-through sur 5001.
- `curl https://registry.local:5000/v2/` donne `401`, avec `dev` le catalogue répond.
  `docker login` puis `docker push localhost:5000/shopapi:1.4.2` fonctionnent.
- Mirror : après un premier pull, le catalogue du mirror contient `library/alpine` et ses logs montrent les requêtes.
- Limites sur ce poste : l'entrée `/etc/hosts` pour `registry.local` demande les droits administrateur que je
  n'avais pas. Docker et les tests passent par `localhost:5000` (présent dans le SAN) et `curl --resolve`.
  Le `registry-mirrors` du daemon n'a pas été modifié (redémarrage de Docker Desktop) : les pulls passent
  par `localhost:5001/library/...`. Ligne à ajouter dans `daemon.json` : `"registry-mirrors": ["http://localhost:5001"]`.
- `htpasswd` ne suffit pas en entreprise : pas de rôles par projet, pas de SSO, pas d'audit, pas de scan, pas
  de réplication, pas de quotas, pas d'immutabilité des tags. Harbor, Nexus, Artifactory et les registres cloud
  (ECR/ACR/GAR) apportent RBAC, scan intégré, réplication, quotas, tags immuables et rétention.

## 2. API du registre

Avec `curl` seulement (`registry/lib.sh` fournit `reg_curl` et `jq`) :

- `GET /v2/_catalog` liste les dépôts, `GET /v2/<repo>/tags/list` les tags.
- Le digest d'un tag vient de `HEAD /v2/<repo>/manifests/<tag>` avec les en-têtes `Accept` OCI et Docker,
  valeur de `Docker-Content-Digest`.
- Test : `demo:v1`, `demo:v2` et `demo:latest` pointaient sur le même digest. `DELETE /manifests/<digest>`
  a répondu `202` et les trois tags ont disparu. Deux tags sur le même manifeste partagent donc leur sort.
- `registry garbage-collect /etc/docker/registry/config.yml` : sans lui, la suppression ne libère rien sur le
  disque. Il a signalé les blobs devenus orphelins.
- `retention.sh demo 2` garde `1.0.0` (semver) et les deux builds les plus récents, et refuse de supprimer
  `build-1` parce qu'il partage son digest avec `1.0.0`.

## 3. Tags

Voir `TAGGING.md`. Retag sans pull avec `crane tag` exécuté dans un conteneur sur le réseau du compose.

## 4. SBOM, scan, signature

- `syft shopapi:1.4.2 -o spdx-json` : 134 paquets (`security/sbom.json`).
- `trivy` sur `shopapi:1.4.2` : 0 CVE HIGH/CRITICAL corrigeable, 0 secret.
- `trivy` sur `shopapi:legacy` : 22 CVE HIGH/CRITICAL corrigeables (paquets npm, par exemple `brace-expansion`)
  et 1 secret : `AWS Access Key ID` dans `/app/.env`.
- `cosign generate-key-pair` (mot de passe vide), `sign`, `attest --type spdxjson`, puis `verify` et
  `verify-attestation` : valides.
- Dans le registre, signature et attestation sont dans un tag `sha256-<digest>` du même dépôt (visible dans
  `tags/list`).
- Test : j'ai poussé une autre image (`shopapi:test`) sous le tag `1.4.2`. `cosign verify` sur le tag donne
  `no signatures found`, sur l'ancien digest il réussit. La signature suit le digest, pas le tag.
  Le tag `1.4.2` a ensuite été remis sur l'image d'origine.
- Attention : mon premier `cosign sign` sans option a envoyé digest et clé publique à Rekor, le journal public
  de Sigstore. La porte de release utilise `--use-signing-config=false --tlog-upload=false`.

## 5. Porte de release

`./release-gate.sh IMAGE [--push REGISTRY_IMAGE]` contrôle les labels `version`, `revision`, `source`,
l'utilisateur non-root, le `HEALTHCHECK`, les CVE HIGH/CRITICAL corrigeables et les secrets. Si tout passe et
que `--push` est donné, il pousse, génère le SBOM, signe et atteste.

- `shopapi:legacy` : refusé (2 labels absents, root, pas de healthcheck, 22 CVE, 1 secret), code de sortie 1.
- `shopapi:1.4.2 --push registry.local:5000/shopapi:1.4.2-gate` : accepté, poussé, signé, SBOM attesté.
