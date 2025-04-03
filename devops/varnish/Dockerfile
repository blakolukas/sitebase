# syntax=docker/dockerfile:1
FROM varnish:7.6

LABEL maintainer="PROCERGS <sites@procergs.rs.gov.br>" \
      org.label-schema.name="sitebase-varnish" \
      org.label-schema.description="Site Plone Varnish image." \
      org.label-schema.vendor="PROCERGS"

COPY etc/varnish.vcl /etc/varnish/default.vcl
