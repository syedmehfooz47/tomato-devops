# ------------------- Stage 1: Builder Stage ----------------------------
FROM node:22-alpine AS backend-builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# ------------------- Stage 2: Production Stage -------------------------
FROM node:22-alpine

WORKDIR /app

# Copy everything from builder stage
COPY --from=backend-builder /app .

RUN mkdir -p uploads

EXPOSE 4000

CMD ["npm", "start"]