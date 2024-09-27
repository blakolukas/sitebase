# syntax=docker/dockerfile:1
FROM varnish:7.4

LABEL maintainer="PROCERGS <sites@procergs.rs.gov.br>" \
      org.label-schema.name="siteplone-varnish" \
      org.label-schema.description="Site Plone Varnish image." \
      org.label-schema.vendor="PROCERGS"

COPY etc/varnish.vcl /etc/varnish/default.vcl
