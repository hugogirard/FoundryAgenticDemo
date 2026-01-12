from fastapi import FastAPI
from contextlib import asynccontextmanager
from services import CrimeAgent
from config import Config

@asynccontextmanager
async def lifespan_event(app: FastAPI):
    
    config = Config()
    app.state.crime_agent = CrimeAgent(config)

    yield

class Bootstrapper:

    def run(self) -> FastAPI:

        app = FastAPI(lifespan=lifespan_event)

        return app