{{- define "service.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/part-of: peaceapp
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "service.selector" -}}
app.kubernetes.io/name: {{ .Values.name }}
{{- end -}}
