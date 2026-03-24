NAME := inception

COMPOSE_FILE := ./srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

DATA_DIR := /home/$(USER)/data
DB_DATA := $(DATA_DIR)/db
WP_DATA := $(DATA_DIR)/wordpress

.PHONY: all setup build up down stop start restart logs ps status

all: up

setup:
	@mkdir -p $(DB_DATA) $(WP_DATA)

build: setup
	@$(COMPOSE) build

up: setup
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

restart: down up

logs:
	@$(COMPOSE) logs -f

ps status:
	@$(COMPOSE) ps
