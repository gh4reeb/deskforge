FROM node:18 as frontend
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM rust:1.60 as backend
WORKDIR /app
COPY src-tauri/ .
RUN cargo build --release

FROM python:3.8
WORKDIR /app
COPY agent-backend/ .
RUN pip install -r requirements.txt
COPY --from=frontend /app/dist ./dist
COPY --from=backend /app/target/release/deskforge ./deskforge
CMD ["./deskforge"]