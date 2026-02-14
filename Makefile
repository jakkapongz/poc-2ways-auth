.PHONY: help certs build up down logs test clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

certs: ## Generate SSL certificates
	@echo "Generating certificates..."
	@chmod +x generate-certs.sh
	@./generate-certs.sh

build: ## Build Docker images
	@echo "Building Docker images..."
	@docker-compose build

up: ## Start all services
	@echo "Starting services..."
	@docker-compose up -d
	@echo "Services started!"
	@echo "Spring Boot: https://localhost:8443"
	@echo "Apache HTTPD: https://localhost:443"

up-logs: ## Start all services with logs
	@echo "Starting services with logs..."
	@docker-compose up

down: ## Stop all services
	@echo "Stopping services..."
	@docker-compose down

logs: ## Show logs
	@docker-compose logs -f

logs-spring: ## Show Spring Boot logs
	@docker-compose logs -f spring-app

logs-httpd: ## Show Apache HTTPD logs
	@docker-compose logs -f httpd-proxy

test: ## Run tests against endpoints
	@echo "Running tests..."
	@chmod +x test-endpoints.sh
	@./test-endpoints.sh

restart: down up ## Restart all services

rebuild: down build up ## Rebuild and restart all services

clean: ## Clean up all generated files and stop containers
	@echo "Cleaning up..."
	@docker-compose down -v
	@rm -rf certs/
	@rm -f src/main/resources/keystore.p12
	@rm -f src/main/resources/truststore.p12
	@rm -rf build/
	@rm -rf target/
	@echo "Cleanup complete!"

setup: certs build up ## Complete setup (generate certs, build, and start)
	@echo ""
	@echo "Setup complete! Services are running."
	@echo "Run 'make test' to test the endpoints."

gradle-build: ## Build with Gradle locally
	@echo "Building with Gradle..."
	@./gradlew clean build

gradle-run: ## Run Spring Boot locally with Gradle
	@echo "Running Spring Boot with Gradle..."
	@./gradlew bootRun

gradle-jar: ## Build and run jar with Gradle
	@echo "Building jar with Gradle..."
	@./gradlew clean bootJar
	@echo "Running Spring Boot..."
	@java -jar build/libs/poc-2ways-auth-1.0.0-SNAPSHOT.jar

status: ## Show service status
	@docker-compose ps

shell-spring: ## Open shell in Spring Boot container
	@docker-compose exec spring-app sh

shell-httpd: ## Open shell in Apache HTTPD container
	@docker-compose exec httpd-proxy sh
