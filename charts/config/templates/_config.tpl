{{- define "cv.imagePullSecretCredentials" }}
{{- with .Values.pullsecret }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" ( .registry | default "docker.io" ) .username .password "@commvault.com" (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "cv.cvpatcherimage" }}
{{- if (.Values.image).location -}}
{{- (.Values.image).location }}
{{- else -}}
{{- $defaults := (fromYaml (.Files.Get "defaults.yaml")) }}
{{- $registry := (or (.Values.image).registry ((.Values.global).image).registry "")  }}
{{- if ne $registry "" -}}
{{- if ne (hasSuffix "/" $registry) true -}}
{{- $registry = print $registry "/" -}}
{{- end -}}
{{- end -}}
    {{- $registry }}
    {{- or (.Values.image).namespace ((.Values.global).image).namespace ($defaults.image).namespace }}/
    {{- or (.Values.image).repository ((.Values.global).image).repository ($defaults.image).repository }}:
    {{- "latest" }}
{{- end -}}    
{{- end }}
