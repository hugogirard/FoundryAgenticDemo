FROM node:lts-alpine AS builder
WORKDIR /usr/src/app

# Copy package files first for better layer caching
COPY package*.json ./
RUN npm ci --silent

# Copy source files
COPY . .
RUN npm run build

FROM node:lts-alpine
ENV NODE_ENV=production
WORKDIR /usr/src/app

# Install production dependencies with clean install
COPY package*.json ./
RUN npm ci --production --silent && \
    npm cache clean --force && \
    mv node_modules ../

# Copy built artifacts
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/src/data ./dist/data

EXPOSE 3000
RUN chown -R node /usr/src/app
USER node
CMD ["node", "dist/main.js"]

# COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
# RUN npm install --silent
# COPY . .
# RUN npm run build

# FROM node:lts-alpine
# ENV NODE_ENV=production
# WORKDIR /usr/src/app
# COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
# RUN npm install --production --silent && mv node_modules ../
# COPY --from=builder /usr/src/app/dist ./dist
# EXPOSE 3000
# RUN chown -R node /usr/src/app
# USER node
# CMD ["node", "dist/main.js"]