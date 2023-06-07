{{/*
_cv.tpl is the same for all commvault components. Any change in this file should be copied to the _cv.tpl in all the components.
*/}}




{{- define "cv.image" }}
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
    {{- required "image.tag or global.image.tag is required" (or (.Values.image).tag ((.Values.global).image).tag) }}
{{- end -}}
{{- end }}

{{- define "cv.metadataname" -}}
{{- if .Values.clientName -}}
 {{ tpl (default "" (.Values.global).prefix) . }}{{ tpl .Values.clientName . | lower }}{{tpl (default "" (.Values.global).suffix) . }}
{{- else -}}
{{ tpl (default "" (.Values.global).prefix) . }}{{ .Release.Name | lower }}{{tpl (default "" (.Values.global).suffix) . }}
{{- end -}}
{{- end -}}

{{- define "cv.metadataname2" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
 {{- tpl ( default "" ($root.Values.global).prefix) $root }}{{ $name }}{{tpl ( default "" ($root.Values.global).suffix) $root }}
{{- end -}}

{{- define "cv.hostname" }}
{{- if .Values.clientHostName }}
{{- .Values.clientHostName }}
{{- else }}
{{- include "cv.metadataname" . }}.{{- include "cv.namespace" . }}.{{ or (.Values.global).clusterDomain "svc.cluster.local" }}
{{- end }}
{{- end -}}

{{- define "cv.namespace" -}}
{{- if (.Values.global).namespace -}}
 {{ (.Values.global).namespace }}
{{- else -}}
 {{ .Release.Namespace }}
{{- end -}}
{{- end -}}


{{- define "cv.imagePullSecret" }}
{{- if or (.Values.image).pullSecret ((.Values.global).image).pullSecret }}
      imagePullSecrets: 
      - name: {{ tpl (default "" (.Values.global).prefix) . }}{{or (.Values.image).pullSecret ((.Values.global).image).pullSecret}}{{tpl (default "" (.Values.global).suffix) . }}
{{- end }}
{{- end }}

{{- define "cv.cvfwdport" }}
{{- or .Values.cvfwdport (.Values.global).cvfwdport 8403 }}
{{- end }}


{{/*
cv.deploymentannotations is a function that allows the user to specify deployment annotations
Use "deploymentannotations" as the section name. deploymentannotations can be specified at both global and local values
and will be merged to provide a single set of deployment annotations that will be added into the final deployment
*/}}
{{- define "cv.deploymentannotations" }}
{{- if or (.Values.global).deploymentannotations .Values.deploymentannotations }}
{{ "annotations:" | indent 2 -}}
{{- include "cv.utils.getCombinedYaml" (list .Values.deploymentannotations (.Values.global).deploymentannotations $ 4 true) }}
{{- end -}}
{{ end }}

{{/*
cv.serviceannotations is a function that allows the user to specify service annotations, e.g service.beta.kubernetes.io/azure-dns-label-name
Use "serviceannotations" as the section name. serviceannotations can be specified at both global and local values
and will be merged to provide a single set of service annotations that will be added into the final service specification
*/}}
{{- define "cv.serviceannotations" }}
{{- if or (.Values.global).serviceannotations .Values.serviceannotations }}
{{ "annotations:" | indent 2 -}}
{{- include "cv.utils.getCombinedYaml" (list .Values.serviceannotations (.Values.global).serviceannotations $ 4 true ) }}
{{- end -}}
{{ end }}


{{/*
cv.additionalPodspecs is a function that allows the user to specify additional pod specifications that are not mentioned in the deployment templates
Use "additionalPodspecs" as the section name to enter the additional pod specifications. pod specifications can be specified at both global and local values
and will be merged to provide a single set of additional pod specifications that will be added to the final deployment
There is also a provision to have chart level defaults which can be specified by having a defaults.yaml in chart directory.
Values in defaults.yaml gets the last priority
*/}}
{{- define "cv.additionalPodspecs" }}
{{- $defaults := (fromYaml (.Files.Get "defaults.yaml")) }}
{{- if or (.Values.global).additionalPodspecs .Values.additionalPodspecs $defaults.additionalPodspecs }}
{{- $combinedYaml := fromYaml ((include "cv.utils.getCombinedYaml" (list (.Values.global).additionalPodspecs $defaults.additionalPodspecs $ 6 false ))) }}
{{- include "cv.utils.getCombinedYaml" (list .Values.additionalPodspecs $combinedYaml $ 6 false ) }}
{{- end -}}
{{- end }}

{{/*
cv.commonContainerSpecs adds container specifications that are common for all commvault images
*/}}
{{- define "cv.commonContainerSpecs" }}
{{- $defaults := (fromYaml (.Files.Get "defaults.yaml")) }}
{{- if and (eq (include "cv.utils.isMinVersion" (list . 11 32)) "true") (ne (.Values.pause |default false) true) }}
{{- $startupprobe := ternary $defaults.startupprobe "true" (hasKey $defaults "startupprobe") }}
{{- $startupprobe = ternary .Values.startupprobe $startupprobe (hasKey .Values "startupprobe") }}
  {{- if $startupprobe }}
        startupProbe:
            httpGet:
                path: /startupstatus
                port: 6688
                scheme: HTTP
            initialDelaySeconds: 2
            timeoutSeconds: 600
            periodSeconds: 2
            failureThreshold: 7
  {{- end }}            
{{- end }}
{{- end }}

{{/*
cv.resources is a function that allows the user to specify pod resource requests and limits
Pod resource specifications can be specified at both global and local values
and will be merged to provide a single set of resource specification that will be added to the final deployment
There is also a provision to have chart level defaults which can be specified by having a defaults.yaml in chart directory.
Values in defaults.yaml gets the last priority
*/}}
{{- define "cv.resources" }}
{{- $defaults := (fromYaml (.Files.Get "defaults.yaml")) }}
{{- if or (.Values.global).resources .Values.resources $defaults.resources }}
{{ "resources:" | indent 8 -}}
{{- $combinedYaml := fromYaml ((include "cv.utils.getCombinedYaml" (list (.Values.global).resources $defaults.resources $ 10 false ))) }}
{{- include "cv.utils.getCombinedYaml" (list .Values.resources $combinedYaml $ 10 false ) }}
{{- end -}}
{{ end }}

{{/*
cv.commonenv creates environment variables that are common to all deployments
*/}}
{{- define "cv.commonenv" }}
{{- $statefulset := or .Values.statefulset ((.Values).global).statefulset }}
{{- $objectname := include "cv.metadataname" . }}
        {{- if $statefulset }}
        # client display name
        - name: CV_CLIENT_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: CV_CLIENT_HOSTNAME
          # pod ip will be used for statefulset
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: CV_IS_STATEFULSET  
          value: 'true'
        - name: CV_DNS_SUFFIX
          # dns suffix of the client
          value: {{ .Values.serviceName | default $objectname }}.{{- include "cv.namespace" . }}.{{ or (.Values.global).clusterDomain "svc.cluster.local" }}
        {{- else }}
        - name: CV_CLIENT_NAME
          # client display name
          {{- if .Values.displayname }}
          value: {{ tpl .Values.displayname .}}
          {{- else if .Values.clientName }}
          value: {{ tpl .Values.clientName .}}
          {{- else }}
          value: {{ .Release.Name }}
          {{- end }}
        - name: CV_CLIENT_HOSTNAME
          # hostname of the client should match the service name.
          value: {{ include "cv.hostname" . }}
        - name: CV_DNS_SUFFIX
          # dns suffix of the client
          value: {{ include "cv.namespace" . }}.{{ or (.Values.global).clusterDomain "svc.cluster.local" }}
        {{- end }}
        {{- if .Values.csOrGatewayHostName }}
        - name: CV_CSHOSTNAME
          value: {{ .Values.csOrGatewayHostName }}
        {{- end }}
        {{- if ((.Values).secret).user }}
        - name: CV_COMMCELL_USER
          value: {{ .Values.secret.user }}
        {{- end }}
        {{- if ((.Values).secret).password }}
        - name: CV_COMMCELL_PWD
          value: {{ .Values.secret.password }}
        {{- end }}
        {{- if .Values.pause }}
        - name: CV_PAUSE
          value: 'true'
        {{- end }}
        {{- if (.Values.global).prefix }}
        - name: CV_APP_PREFIX
          value: "{{ tpl (.Values.global).prefix . }}"
        {{- end }}
        {{- if (.Values.global).suffix }}
        - name: CV_APP_SUFFIX
          value: "{{ tpl (.Values.global).suffix . }}"
        {{- end }}
        - name: CV_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: CV_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace   
{{- end -}}


{{/*
cv.commondeploymentpecs creates pod specifications that are common to all deployments
*/}}
{{- define "cv.commondeploymentspecs" }}
{{- $objectname := include "cv.metadataname" . }}
{{- $statefulset := or .Values.statefulset ((.Values).global).statefulset }}
  {{- if $statefulset }}
  serviceName: {{ .Values.serviceName | default $objectname }}
  {{- if .Values.replicas }}
  replicas: {{.Values.replicas}}
  {{- end }}
  updateStrategy:
    type: RollingUpdate
  {{- else }}
  replicas: 1  
  strategy:
    type: Recreate
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $objectname }}
  revisionHistoryLimit: 0
{{- end -}}

