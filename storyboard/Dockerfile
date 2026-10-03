FROM mcr.microsoft.com/playwright:v1.63.0-noble
WORKDIR /storyboard
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
CMD ["sh", "-c", "npx playwright test && node build-report.mjs"]
