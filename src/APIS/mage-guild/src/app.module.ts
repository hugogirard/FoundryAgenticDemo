import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { QuestController } from './quest/quest.controller';
import { QuestRepository } from './quest/quest.repository';

@Module({
  imports: [],
  controllers: [AppController, QuestController],
  providers: [QuestRepository],
})
export class AppModule { }
