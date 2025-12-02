using Mage.Guild.Api.Endpoints;
using Mage.Guild.Api.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "Mage Guild API",
        Version = "v1",
        Description = "API for managing Mage Guild quests, enrollments, and rewards"
    });
});
builder.Services.AddSingleton<IQuestRepository, InMemoryQuestRepository>();

var app = builder.Build();

// Configure Swagger UI
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "Mage Guild API v1");
    options.RoutePrefix = string.Empty; // Serve Swagger UI at root
});

app.UseHttpsRedirection();

// Map Quest endpoints
app.MapQuestEndpoints();

app.Run();
