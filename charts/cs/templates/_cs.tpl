{{- define "cv.csserviceannotations" }}
{{- if or (.Values.global).csserviceannotations .Values.csserviceannotations }}
{{ "annotations:" | indent 2 -}}
{{ if and (.Values.global).csserviceannotations .Values.csserviceannotations -}}
{{- $mergedcsserviceannotations := mustMergeOverwrite (dict) .Values.global.csserviceannotations .Values.csserviceannotations -}}
{{- range $k, $v := $mergedcsserviceannotations }} 
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- else if (.Values.global).csserviceannotations -}}
{{- range $k, $v := .Values.global.csserviceannotations }}
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- else -}}
{{- range $k, $v := .Values.csserviceannotations }}
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- end -}}
{{- end -}}
{{ end }}

{{- define "cv.consoleserviceannotations" }}
{{- if or (.Values.global).consoleserviceannotations .Values.consoleserviceannotations }}
{{ "annotations:" | indent 2 -}}
{{ if and (.Values.global).consoleserviceannotations .Values.consoleserviceannotations -}}
{{- $mergedconsoleserviceannotations := mustMergeOverwrite (dict) .Values.global.consoleserviceannotations .Values.consoleserviceannotations -}}
{{- range $k, $v := $mergedconsoleserviceannotations }} 
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- else if (.Values.global).consoleserviceannotations -}}
{{- range $k, $v := .Values.global.consoleserviceannotations }}
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- else -}}
{{- range $k, $v := .Values.consoleserviceannotations }}
    {{ $k }}: {{ tpl $v $ }}
{{- end }}
{{- end -}}
{{- end -}}
{{ end }}

