# ------------------- Stage 1: Build Stage ------------------------------
FROM node:22-alpine AS admin-builder

# Set the working directory
WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# ------------------- Stage 2: Production Stage -------------------------
FROM node:22-alpine

WORKDIR /app

# Copy from builder stage
COPY --from=admin-builder /app .

EXPOSE 5174

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5174"]