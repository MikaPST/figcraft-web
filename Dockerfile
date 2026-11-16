FROM nginx:1.27-alpine
LABEL org.opencontainers.image.title="FigCraft Web" \
      org.opencontainers.image.description="Community Docker packaging for FigCraft Web"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/licenses/
RUN mkdir -p /tmp/nginx /var/cache/nginx /var/run \
    && chown -R nginx:nginx /tmp/nginx /var/cache/nginx /var/run /usr/share/nginx/html \
    && chmod -R a+rX /usr/share/nginx/html
USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
