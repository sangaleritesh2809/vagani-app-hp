# ==========================================
# Stage 1: Build Flutter Web Application
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source files
COPY . .

# Build Flutter Web in release mode with optional API_BASE_URL arg
ARG API_BASE_URL=""
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL; \
    else \
      flutter build web --release; \
    fi

# ==========================================
# Stage 2: Serve with Nginx Alpine
# ==========================================
FROM nginx:alpine

# Set default port to 80 (Render / Cloud platforms pass $PORT dynamically)
ENV PORT=80

# Clean default nginx files
RUN rm -rf /usr/share/nginx/html/*

# Copy Flutter web build output
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration as template (envsubst will substitute ${PORT})
COPY nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
