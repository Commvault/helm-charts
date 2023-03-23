{{- define "cv.imagePullSecretCredentials" }}
{{- with .Values.pullsecret }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" ( .registry | default "docker.io" ) .username .password "@commvault.com" (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
