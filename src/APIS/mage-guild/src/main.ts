import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('Mage Guild API')
    .setDescription('Provides all the mage guild quests')
    .setVersion('1.0')
    .addServer(process.env.SERVER_URL ?? 'http://localhost:3000')
    .build();

  const documentFactory = () => SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, documentFactory, {
    yamlDocumentUrl: 'swagger/yaml',
    jsonDocumentUrl: 'swagger/json'
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
