# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Build web app
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy the built Flutter web app to nginx html directory
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
