# Politique de tags

## Tags

| Tag | Exemple | Mutable | Usage |
|---|---|---|---|
| version exacte | `1.4.2` | non | release, référence de déploiement |
| mineure | `1.4` | oui | suit le dernier correctif 1.4.x |
| canal | `stable` | oui | image promue en production |
| build | `build-42`, `sha-ab12cd3` | non | CI, une image par commit |
| `latest` | | oui | interdit en production |

Les tags de version exacte et de build ne sont jamais réécrits. Un correctif donne un nouveau tag
(`1.4.3`). `registry:2` ne sait pas rendre un tag immuable : la règle est appliquée par la CI (le job de
release refuse de pousser un tag semver déjà présent). Harbor, ECR ou Artifactory le font côté serveur.

## Pourquoi pas `latest` en production

`latest` bouge à chaque push. Deux nœuds qui tirent à dix minutes d'écart peuvent exécuter deux versions
différentes, un rollback est impossible puisque l'ancienne version n'est plus nommée, et une image réécrite
casse la production sans trace dans Git.

## Référencer par digest

Le digest désigne un contenu précis qui ne peut pas être réécrit. On le garde à côté du tag lisible :

```yaml
services:
  api:
    image: registry.local:5000/shopapi:1.4.2@sha256:bf12213a0c398bdae7b05cb374c9818ffab4ae96e7ab317e2813f2568bd56428
```

Docker utilise alors le digest et ignore le tag. La signature cosign est attachée au digest : un tag réécrit
avec une autre image n'est plus vérifiable (`no signatures found`), l'ancien digest l'est toujours.

## Retag sans pull

Aucune couche n'est téléchargée, seul le manifeste est copié côté registre :

```bash
crane tag registry:5000/shopapi:1.4.2 stable
crane tag registry:5000/shopapi:1.4.2 1.4
```

`stable`, `1.4` et `1.4.2` ont le même digest (`sha256:bf12213a...`).

## Rétention

`registry/retention.sh REPO N` garde les tags semver et les N tags non-semver les plus récents. Supprimer
par digest supprime tous les tags qui pointent dessus : le script ignore donc un tag ancien qui partage son
digest avec un tag conservé.
