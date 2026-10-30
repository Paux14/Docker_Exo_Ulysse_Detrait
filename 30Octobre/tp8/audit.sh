#!/usr/bin/env bash
PROJECT="${1:-shop}"
fail=0

ids=$(docker ps -q --filter "label=com.docker.compose.project=$PROJECT")
[ -n "$ids" ] || { echo "aucun conteneur pour le projet $PROJECT"; exit 2; }

printf '%-22s %-10s %-5s %-8s %-6s %-9s %-6s %-6s\n' CONTENEUR USER PRIV ROOTFS MEM PIDS NONEWP SOCK
for id in $ids; do
  name=$(docker inspect -f '{{.Name}}' "$id" | sed 's#^/##')
  user=$(docker inspect -f '{{.Config.User}}' "$id")
  priv=$(docker inspect -f '{{.HostConfig.Privileged}}' "$id")
  capadd=$(docker inspect -f '{{range .HostConfig.CapAdd}}{{.}} {{end}}' "$id")
  capdrop=$(docker inspect -f '{{range .HostConfig.CapDrop}}{{.}} {{end}}' "$id")
  ro=$(docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' "$id")
  mem=$(docker inspect -f '{{.HostConfig.Memory}}' "$id")
  pids=$(docker inspect -f '{{if .HostConfig.PidsLimit}}{{.HostConfig.PidsLimit}}{{else}}0{{end}}' "$id")
  nnp=$(docker inspect -f '{{range .HostConfig.SecurityOpt}}{{.}} {{end}}' "$id")
  sock=$(docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' "$id" | grep -c 'docker.sock')
  sockrw=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/run/docker.sock"}}{{.RW}}{{end}}{{end}}' "$id")
  proxy=$(docker inspect -f '{{index .Config.Labels "audit.socket-proxy"}}' "$id")

  problems=""
  if [ "$proxy" != "true" ]; then
    case "$user" in ""|0|root|0:0|root:root) problems="$problems user-root";; esac
  fi
  [ "$priv" = "true" ] && problems="$problems privileged"
  case " $capdrop " in *" ALL "*|*" all "*) ;; *) problems="$problems cap-drop-ALL-absent";; esac
  [ -n "$capadd" ] && echo "  [$name] cap_add: $capadd"
  if [ "$proxy" != "true" ]; then
    [ "$ro" = "true" ] || problems="$problems rootfs-rw"
  fi
  [ "$mem" -gt 0 ] || problems="$problems no-mem-limit"
  [ "$pids" -gt 0 ] || problems="$problems no-pids-limit"
  case "$nnp" in *no-new-privileges*) nnpv=yes;; *) nnpv=no; problems="$problems no-new-privileges-absent";; esac
  if [ "$sock" -gt 0 ]; then
    if [ "$proxy" = "true" ] && [ "$sockrw" = "false" ]; then :; else problems="$problems docker-sock"; fi
  fi

  printf '%-22s %-10s %-5s %-8s %-6s %-9s %-6s %-6s\n' "$name" "${user:-root}" "$priv" "$ro" "$((mem/1048576))M" "$pids" "$nnpv" "$sock"
  if [ -n "$problems" ]; then
    echo "  ECART [$name]:$problems"
    fail=$((fail+1))
  fi
done

echo "conteneurs en ecart: $fail"
[ "$fail" -eq 0 ]
