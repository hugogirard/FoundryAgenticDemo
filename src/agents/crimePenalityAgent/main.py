from fastapi.responses import RedirectResponse
from boostrapper import Bootstrapper

app = Bootstrapper().run()

@app.get('/', include_in_schema=False)
async def root():
    return RedirectResponse(url='/docs')