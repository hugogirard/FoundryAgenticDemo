import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { QuestModule } from './quest/quest.module';


@Module({
  imports: [QuestModule],
  controllers: [AppController],
  providers: [],
})
export class AppModule { }
