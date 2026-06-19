# ------------------- Stage 1: Build Stage ------------------------------
FROM node:22-alpine AS frontend-builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# ------------------- Stage 2: Production Stage -------------------------
FROM node:22-alpine

WORKDIR /app

# Copy from builder stage
COPY --from=frontend-builder /app .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--mode", "docker"]