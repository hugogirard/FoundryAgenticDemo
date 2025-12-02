from fastapi import FastAPI
from repositories import QuestRepository
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan_event(app: FastAPI):

    app.state.quest_repository = QuestRepository()

    yield

class Bootstrapper:

    def run(self) -> FastAPI:

        app = FastAPI(lifespan=lifespan_event)

        return app
