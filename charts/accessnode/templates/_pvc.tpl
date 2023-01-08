{{/*
_pvc.tpl is the same for all commvault components. Any change in this file should be copied to the _pvc.tpl in all the components.
*/}}

{{/*
For creating pvc either storage class (for dynamic provisioning) or pv name can be used.
Storage class can also be blank to use default storage class for dynamic provisioning
storageClass:
  logs: logs

or

storageClass:
  logs_pv: existinglogvol

*/}}
{{- define "cv.pvc" }}
{{- $root := index . 0 }}
{{- $type := index . 1 }}
{{- $type_size := print $type "_size" }}
{{- $type_pv := print $type "_pv" }}
{{- $defaultsize := index . 2 }}
{{- $name := $type }}
{{- if eq (len .) 4 }}
{{- $name = index . 3 }}
{{- end }}
{{- $storageClass := or (get ($root.Values.storageClass) $type) (get (($root.Values.global).storageClass) $type) "" }}
{{- $size := or (get ($root.Values.storageClass) $type_size) (get (($root.Values.global).storageClass) $type_size) $defaultsize }}
{{- $pv := or (get ($root.Values.storageClass) $type_pv) (get (($root.Values.global).storageClass) $type_pv) "" }}
# PVC for {{$name}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "cv.metadataname" $root }}-{{ $name }}
  namespace: {{($root.Values.global).namespace}}
spec:
  accessModes:
    - ReadWriteOnce
  {{- if $pv }}
{{- /* Empty string must be explicitly set otherwise default StorageClass will be set */}}
  storageClassName: ""
  volume: {{ $pv }}
{{- /* Leave this if condition alone. otherwise it can cause problem on restart if storageClassName is blank */}}
  {{- else if $storageClass }}
  storageClassName: {{ $storageClass }} 
  {{- end}}
  resources:
    requests:
      storage: {{ $size }}
{{- end }}



{{- define "cv.pvctemplate" }}
{{- $root := index . 0 }}
{{- $type := index . 1 }}
{{- $type_size := print $type "_size" }}
{{- $defaultsize := index . 2 }}
{{- $name := $type }}
{{- if eq (len .) 4 }}
{{- $name = index . 3 }}
{{- end }}
{{- $storageClass := or (get ($root.Values.storageClass) $type) (get (($root.Values.global).storageClass) $type) "" }}
{{- $size := or (get ($root.Values.storageClass) $type_size) (get (($root.Values.global).storageClass) $type_size) $defaultsize }}
  - metadata:
      name: cv-storage-{{ $name }}
    spec:
{{- /*
 leave this if condition alone. otherwise it can cause problem on restart if storageclassname is blank
*/}}
      {{- if $storageClass }}
      storageClassName: {{ $storageClass }}
      {{- end}}
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: {{ $size }}
{{- end }}
