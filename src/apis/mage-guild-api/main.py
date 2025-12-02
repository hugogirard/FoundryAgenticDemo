from bootstrapper import Bootstrapper
from fastapi.responses import RedirectResponse
from routes import routes

app = Bootstrapper().run()

for route in routes:
    app.include_router(route)

@app.get('/', include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")