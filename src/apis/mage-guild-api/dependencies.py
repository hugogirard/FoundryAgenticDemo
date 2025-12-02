from fastapi import Request
from logging import Logger
from repositories import QuestRepository
import logging
import sys

# Configure logger
_logger = logging.getLogger('QuestAPI')
_logger.setLevel(logging.DEBUG)

# StreamHandler for the console
stream_handler = logging.StreamHandler(sys.stdout)
log_formatter = logging.Formatter("%(asctime)s [%(processName)s: %(process)d] [%(threadName)s: %(thread)d] [%(levelname)s] %(name)s: %(message)s")
stream_handler.setFormatter(log_formatter)
_logger.addHandler(stream_handler)

def get_quest_repository(request: Request) -> QuestRepository:
    return request.app.state.quest_repository

def get_logger() -> Logger:
    return _logger