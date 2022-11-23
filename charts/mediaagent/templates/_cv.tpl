{{- define "cv.image" }}
{{- $values := index . 0 }}
{{- $defaultRepository := index . 1 }}
    {{- or ($values.image).registry (($values.global).image).registry }}
    {{- or ($values.image).namespace (($values.global).image).namespace "commvault" }}/
    {{- or ($values.image).repository (($values.global).image).repository $defaultRepository }}:
    {{- or ($values.image).tag (($values.global).image).tag "latest" }}
{{- end }}

{{- define "cv.metadataname" -}}
 {{(.Values.global).appname}}{{ tpl .Values.clientName . | lower }}
{{- end -}}

{{- define "cv.hostname" }}
{{- if .Values.clientHostName }}
{{- .Values.clientHostName }}
{{- else }}
{{- include "cv.metadataname" . }}.{{ or (.Values.global).namespace "default" }}.{{ or (.Values.global).clusterDomain "svc.cluster.local" }}
{{- end }}
{{- end -}}


{{- define "cv.imagePullSecret" }}
{{- if or (.Values.image).pullSecret ((.Values.global).image).pullSecret }}
      imagePullSecrets: 
      - name: {{(.Values.global).appname}}{{or (.Values.image).pullSecret ((.Values.global).image).pullSecret}}
{{- end }}
{{- end }}


{{/*
cv.formatYAML is a generic function that will iterate over the input specifications list and output the yaml.
It also supports string based values to be templates themselves.
So just as an example you can have the value of additionalPodspecs.zone set to some global value like so:

additionalPodspecs:
  nodeSelector: 
    region: "{{ .Values.global.region }}"

The usequotes parameter is for annotations which require the values to be in quotes if they are integers
*/}}
{{- define "cv.formatYAML" }}
{{- $specs := index . 0 }}
{{- $root := index . 1 }}
{{- $indent := index . 2 }}
{{- $useQuotes := index . 3 }}
{{- $indent2 := add $indent 2 }}
{{- range $k, $v := $specs }} 
{{- if kindIs "invalid" $v }}
{{- else if (kindIs "map" $v) -}}
{{ $k | nindent $indent }}:
{{- include "cv.formatYAML" (list $v $root (int $indent2) $useQuotes ) }}
{{- else if (kindIs "slice" $v) -}}
{{ $k | nindent $indent }}:
{{- toYaml $v | nindent (int $indent2) -}}
{{- else if or (kindIs "float64" $v) (kindIs "int64" $v) (kindIs "bool" $v) -}}
{{- if $useQuotes -}}
{{ $k | nindent $indent }}: {{ $v | quote }}
{{- else -}}
{{ $k | nindent $indent }}: {{ $v }}
{{- end -}}
{{- else if kindIs "string" $v -}}
{{ $k | nindent $indent }}: {{ tpl $v $root }}
{{- else }}
{{- toYaml $v | nindent $indent -}}
{{- end }}
{{- end }}
{{- end -}}

{{/*
cv.getCombinedYaml is a generic function that will merge 2 sections of values from global and local where local values will override global values if supplied
For example if the following values are defined
# globals.yaml
global:
  annotations:
    controller.kubernetes.io/pod-deletion-cost: "50"

# values.yaml
annotations:
  topology.kubernetes.io/zone: "useast"
  service.beta.kubernetes.io/azure-dns-label-name: "{{ .Values.clientName }}"

then combined annotations will be
annotations:
  controller.kubernetes.io/pod-deletion-cost: "50"
  topology.kubernetes.io/zone: "useast"
  service.beta.kubernetes.io/azure-dns-label-name: clientName

The values can be templatized strings themselves, as shown for dns label annotation, to make it more flexible
*/}}
{{- define "cv.getCombinedYaml" }}
{{- $localValues := index . 0 }}
{{- $globalValues := index . 1 }}
{{- $root := index . 2 }}
{{- $indent := index . 3 }}
{{- $useQuotes := index . 4 }}
{{- if or $globalValues $localValues }}
{{- if and $globalValues $localValues -}}
{{- $mergedValues := mustMergeOverwrite (dict) $globalValues $localValues -}}
{{- include "cv.formatYAML" (list $mergedValues $root $indent $useQuotes ) }}
{{- else if $globalValues -}}
{{- include "cv.formatYAML" (list $globalValues $root $indent $useQuotes ) }}
{{- else -}}
{{- include "cv.formatYAML" (list $localValues $root $indent $useQuotes ) }}
{{- end -}}
{{- end -}}
{{ end }}



{{/*
cv.deploymentannotations is a utility function that allows the user to specify deployment annotations
Use "deploymentannotations" as the section name. deploymentannotations can be specified at both global and local values
and will be merged to provide a single set of deployment annotations that will be added into the final deployment
*/}}
{{- define "cv.deploymentannotations" }}
{{- if or (.Values.global).deploymentannotations .Values.deploymentannotations }}
{{ "annotations:" | indent 2 -}}
{{- include "cv.getCombinedYaml" (list .Values.deploymentannotations (.Values.global).deploymentannotations $ 4 true) }}
{{- end -}}
{{ end }}

{{/*
cv.serviceannotations is a utility function that allows the user to specify service annotations, e.g service.beta.kubernetes.io/azure-dns-label-name
Use "serviceannotations" as the section name. serviceannotations can be specified at both global and local values
and will be merged to provide a single set of service annotations that will be added into the final service specification
*/}}
{{- define "cv.serviceannotations" }}
{{- if or (.Values.global).serviceannotations .Values.serviceannotations }}
{{ "annotations:" | indent 2 -}}
{{- include "cv.getCombinedYaml" (list .Values.serviceannotations (.Values.global).serviceannotations $ 4 true ) }}
{{- end -}}
{{ end }}


{{/*
cv.additionalPodspecs is a utility function that allows the user to specify additional pod specifications that are not mentioned in the deployment templates
Use "podspecs" as the section name to enter the additional pod specifications. pod specifications can be specified at both global and local values
and will be merged to provide a single set of additional pod specifications that will be added to the final deployment
*/}}
{{- define "cv.additionalPodspecs" }}
{{- include "cv.getCombinedYaml" (list .Values.additionalPodspecs (.Values.global).additionalPodspecs $ 6 false ) }}
{{- end }}

{{/*
cv.resources is a utility function that allows the user to specify pod resource requests and limits
Pod resource specifications can be specified at both global and local values
and will be merged to provide a single set of resource specification that will be added to the final deployment
*/}}
{{- define "cv.resources" }}
{{- if or (.Values.global).resources .Values.resources }}
{{ "resources:" | indent 8 -}}
{{- include "cv.getCombinedYaml" (list .Values.resources (.Values.global).resources $ 10 false ) }}
{{- end -}}
{{ end }}
